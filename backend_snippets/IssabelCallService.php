<?php
// ============================================================================
//  DO NOT USE THIS FILE.  (kept only to avoid confusion)
//
//  This was an early draft that talked to Asterisk AMI over a raw socket.
//  Your real system does NOT work that way — it POSTs to call.php on the PBX
//  (144.79.218.25), exactly like your admin panel does.
//
//  USE INSTEAD:
//    - call.php                            -> replace on the PBX server
//    - call_guardian_controller_method.php -> paste into the panel controller
//    - SETUP_click_to_call.md              -> step-by-step guide
// ============================================================================
