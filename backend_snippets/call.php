<?php
// ============================================================================
// call.php — BDTuition click-to-call bridge (Issabel/Asterisk AMI)
//
// Two modes:
//
//   1) DEFAULT (staff / admin panel)  — existing behaviour, unchanged:
//        POST secret, extension, number
//      Rings the agent's SIP extension, then dials `number` via outrt-2.
//
//   2) mode=bridge (teacher app)      — new:
//        POST secret, teacher_number, guardian_number
//      Rings the TEACHER's mobile first (via outrt-2); on answer, dials the
//      GUARDIAN's mobile (also via outrt-2) and bridges the two legs.
//      Neither side ever sees the other's number.
//
// ============================================================================

file_put_contents("/var/www/html/test_hit.txt", date("Y-m-d H:i:s").PHP_EOL, FILE_APPEND);
$input = json_decode(file_get_contents('php://input'), true);
if (!empty($input)) {
    $_POST = array_merge($_POST, $input);
}
$DEBUG = "/var/www/html/pbx_debug.txt";
function pbxlog($msg)
{
    global $DEBUG;
    file_put_contents(
        $DEBUG,
        date('Y-m-d H:i:s') . " " . $msg . PHP_EOL,
        FILE_APPEND
    );
}
pbxlog("========================================");
pbxlog("PBX call.php HIT");
pbxlog("POST: " . json_encode($_POST));

if (($_POST['secret'] ?? '') !== 'BDTuition2026') {
    pbxlog("INVALID SECRET");
    die('Unauthorized');
}

$mode = $_POST['mode'] ?? 'extension';

if ($mode === 'bridge') {
    // ---- TEACHER APP: two mobile numbers bridged --------------------------
    $teacherNumber  = preg_replace('/[^0-9]/', '', $_POST['teacher_number'] ?? '');
    $guardianNumber = preg_replace('/[^0-9]/', '', $_POST['guardian_number'] ?? '');
    pbxlog("BRIDGE MODE teacher=$teacherNumber guardian=$guardianNumber");

    if (!$teacherNumber || !$guardianNumber) {
        pbxlog("MISSING DATA");
        die('Missing data');
    }

    $cmd = "printf 'Action: Login\r\n" .
        "Username: laravel\r\n" .
        "Secret: LaravelAMI2026!\r\n\r\n" .
        "Action: Originate\r\n" .
        "Channel: Local/{$teacherNumber}@outrt-2\r\n" .
        "Context: outrt-2\r\n" .
        "Exten: {$guardianNumber}\r\n" .
        "Priority: 1\r\n" .
        "CallerID: BDTuition <5000>\r\n" .
        "Async: yes\r\n\r\n" .
        "Action: Logoff\r\n\r\n' | nc 127.0.0.1 5038";
    pbxlog("AMI COMMAND:");
    pbxlog($cmd);
    $output = [];
    $return = 0;
    exec($cmd . " 2>&1", $output, $return);
    pbxlog("RETURN CODE: " . $return);
    if (!empty($output)) {
        pbxlog("OUTPUT:");
        pbxlog(implode("\n", $output));
    }
    header('Content-Type: application/json');
    echo json_encode([
        'success'   => true,
        'mode'      => 'bridge',
        'teacher'   => $teacherNumber,
        'guardian'  => $guardianNumber,
    ]);
    exit;
}

// ---- DEFAULT: agent extension -> number (unchanged) -----------------------
$extension = preg_replace('/[^0-9]/', '', $_POST['extension'] ?? '');
$number    = preg_replace('/[^0-9]/', '', $_POST['number'] ?? '');
pbxlog("EXTENSION: $extension");
pbxlog("NUMBER: $number");
if (!$extension || !$number) {
    pbxlog("MISSING DATA");
    die('Missing data');
}
$cmd = "printf 'Action: Login\r\n" .
    "Username: laravel\r\n" .
    "Secret: LaravelAMI2026!\r\n\r\n" .
    "Action: Originate\r\n" .
    "Channel: SIP/$extension\r\n" .
    "Context: outrt-2\r\n" .
    "Exten: $number\r\n" .
    "Priority: 1\r\n" .
    "CallerID: $extension <$extension>\r\n" .
    "Variable: AMPUSER=$extension\r\n" .
    "Variable: REALCALLERIDNUM=$extension\r\n" .
    "Variable: FROMEXTEN=$extension\r\n" .
    "Async: yes\r\n\r\n" .
    "Action: Logoff\r\n\r\n' | nc 127.0.0.1 5038";
pbxlog("AMI COMMAND:");
pbxlog($cmd);
$output = [];
$return = 0;
exec($cmd . " 2>&1", $output, $return);
pbxlog("RETURN CODE: " . $return);
if (!empty($output)) {
    pbxlog("OUTPUT:");
    pbxlog(implode("\n", $output));
}
header('Content-Type: application/json');
$response = [
    'success'   => true,
    'extension' => $extension,
    'number'    => $number
];
pbxlog("RESPONSE: " . json_encode($response));
echo json_encode($response);
