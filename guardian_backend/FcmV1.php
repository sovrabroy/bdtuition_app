<?php
/**
 * FcmV1 — Firebase Cloud Messaging sender (HTTP v1 API).
 *
 * WHY THIS FILE EXISTS:
 *   Google shut down the OLD "legacy" FCM API (fcm.googleapis.com/fcm/send with
 *   "Authorization: key=SERVER_KEY") in June 2024. That method NO LONGER WORKS.
 *   This file uses the NEW, supported v1 API. It needs a Service Account JSON key
 *   file (downloaded from Firebase) instead of a server key.
 *
 * WHAT IT DOES:
 *   1. Reads your service-account JSON.
 *   2. Signs a short-lived Google OAuth2 token (JWT -> access token).
 *   3. Sends a notification to one device token via the v1 endpoint.
 *
 * REQUIREMENTS: PHP with openssl + curl (cPanel has both by default).
 *
 * SETUP (one time):
 *   - In Firebase Console -> Project settings -> Service accounts ->
 *     "Generate new private key". You get a .json file.
 *   - Upload that .json somewhere OUTSIDE public_html (so nobody can download it),
 *     e.g.  /home/mohaqtzn/firebase/bdtuition-service-account.json
 *   - Put the full path in the .env as FCM_SERVICE_ACCOUNT (see below).
 *
 * WHERE TO PUT THIS FILE:
 *   Upload to  app/Services/FcmV1.php  inside panel.bdtuition.com.
 *   The namespace below (App\Services) lets Laravel autoload it, so in your
 *   controller you can just do:  use App\Services\FcmV1;
 */

namespace App\Services;

class FcmV1
{
    /** @var string absolute path to the service-account json file */
    private $serviceAccountPath;

    /** @var array decoded service account */
    private $sa;

    public function __construct(string $serviceAccountPath)
    {
        $this->serviceAccountPath = $serviceAccountPath;
        $json = @file_get_contents($serviceAccountPath);
        if ($json === false) {
            throw new \RuntimeException("FCM: cannot read service account at {$serviceAccountPath}");
        }
        $this->sa = json_decode($json, true);
        if (!isset($this->sa['client_email'], $this->sa['private_key'], $this->sa['project_id'])) {
            throw new \RuntimeException('FCM: service account json is missing required fields');
        }
    }

    /**
     * Send a notification to a single device token.
     * Returns [ok(bool), httpStatus(int), responseBody(string)].
     */
    public function sendToToken(string $deviceToken, string $title, string $body, array $data = []): array
    {
        $accessToken = $this->getAccessToken();

        // v1 requires all data values to be strings.
        $dataStrings = [];
        foreach ($data as $k => $v) {
            $dataStrings[(string) $k] = (string) $v;
        }

        $payload = [
            'message' => [
                'token'        => $deviceToken,
                'notification' => [
                    'title' => $title,
                    'body'  => $body,
                ],
                'data'    => $dataStrings,
                'android' => [
                    'priority'     => 'high',
                    'notification' => [
                        // must match the channel id created in the app (push_service.dart)
                        'channel_id' => 'tuition_alerts',
                    ],
                ],
            ],
        ];

        $projectId = $this->sa['project_id'];
        $url = "https://fcm.googleapis.com/v1/projects/{$projectId}/messages:send";

        $ch = curl_init($url);
        curl_setopt_array($ch, [
            CURLOPT_POST           => true,
            CURLOPT_RETURNTRANSFER => true,
            CURLOPT_HTTPHEADER     => [
                'Authorization: Bearer ' . $accessToken,
                'Content-Type: application/json',
            ],
            CURLOPT_POSTFIELDS     => json_encode($payload),
            CURLOPT_TIMEOUT        => 15,
        ]);
        $resp   = curl_exec($ch);
        $status = (int) curl_getinfo($ch, CURLINFO_HTTP_CODE);
        curl_close($ch);

        return [$status >= 200 && $status < 300, $status, (string) $resp];
    }

    /**
     * Exchange the service account for a short-lived OAuth2 access token.
     * Cached on disk for ~55 minutes so we don't re-sign on every push.
     */
    private function getAccessToken(): string
    {
        $cacheFile = sys_get_temp_dir() . '/fcm_v1_token_' . md5($this->sa['client_email']) . '.json';
        if (is_file($cacheFile)) {
            $cached = json_decode((string) @file_get_contents($cacheFile), true);
            if (isset($cached['access_token'], $cached['expires_at']) && $cached['expires_at'] > time() + 60) {
                return $cached['access_token'];
            }
        }

        $now   = time();
        $header = ['alg' => 'RS256', 'typ' => 'JWT'];
        $claim  = [
            'iss'   => $this->sa['client_email'],
            'scope' => 'https://www.googleapis.com/auth/firebase.messaging',
            'aud'   => 'https://oauth2.googleapis.com/token',
            'iat'   => $now,
            'exp'   => $now + 3600,
        ];

        $segments = [
            $this->b64(json_encode($header)),
            $this->b64(json_encode($claim)),
        ];
        $signingInput = implode('.', $segments);

        $signature = '';
        $ok = openssl_sign($signingInput, $signature, $this->sa['private_key'], 'sha256WithRSAEncryption');
        if (!$ok) {
            throw new \RuntimeException('FCM: failed to sign JWT (check private_key)');
        }
        $jwt = $signingInput . '.' . $this->b64($signature);

        $ch = curl_init('https://oauth2.googleapis.com/token');
        curl_setopt_array($ch, [
            CURLOPT_POST           => true,
            CURLOPT_RETURNTRANSFER => true,
            CURLOPT_POSTFIELDS     => http_build_query([
                'grant_type' => 'urn:ietf:params:oauth:grant-type:jwt-bearer',
                'assertion'  => $jwt,
            ]),
            CURLOPT_TIMEOUT        => 15,
        ]);
        $resp   = curl_exec($ch);
        $status = (int) curl_getinfo($ch, CURLINFO_HTTP_CODE);
        curl_close($ch);

        $json = json_decode((string) $resp, true);
        if ($status !== 200 || !isset($json['access_token'])) {
            throw new \RuntimeException("FCM: token request failed (HTTP {$status}): {$resp}");
        }

        @file_put_contents($cacheFile, json_encode([
            'access_token' => $json['access_token'],
            'expires_at'   => $now + (int) ($json['expires_in'] ?? 3600),
        ]));

        return $json['access_token'];
    }

    /** URL-safe base64 without padding (for JWT). */
    private function b64(string $data): string
    {
        return rtrim(strtr(base64_encode($data), '+/', '-_'), '=');
    }

    /**
     * Convenience: push a "new tuition in your area" notification to one teacher.
     * Safe to call in a loop — any failure (no token, misconfig, bad token) is
     * swallowed so it can never break the surrounding WhatsApp/email flow.
     *
     * Call from the controller like:
     *   \App\Services\FcmV1::notifyTeacher($teacher, $tuition);
     */
    public static function notifyTeacher($teacher, $tuition): void
    {
        try {
            if (empty($teacher->fcm_token)) {
                return;
            }
            $sap = env('FCM_SERVICE_ACCOUNT');
            if (!$sap || !is_file($sap)) {
                return;
            }
            $fcm = new self($sap);
            $fcm->sendToToken(
                $teacher->fcm_token,
                'নতুন টিউশন আপনার এলাকায়!',
                "{$tuition->tuition_code} — {$tuition->area}, ৳{$tuition->salary}/মাস",
                [
                    'tuition_id'   => (string) $tuition->id,
                    'tuition_code' => (string) $tuition->tuition_code,
                    'area'         => (string) $tuition->area,
                ]
            );
        } catch (\Throwable $e) {
            error_log('FCM notifyTeacher failed: ' . $e->getMessage());
        }
    }
}
