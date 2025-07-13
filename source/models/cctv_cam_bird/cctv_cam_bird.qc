$modelname "cameras/cctv_cam_bird"
$cdmaterials "models/cctv_cam_bird"
$surfaceprop "metal"
$origin 0.000000 0.000000 0.000000 -90.000000
$scale 1.000000

$body "cctv_camera" "cctv_camera.SMD"

$bonemerge "Implicit"
$bonemerge "Base"
$bonemerge "Rotary_x"
$bonemerge "Rotary_y"

$bodygroup "Pod" {
    studio "PExist.SMD"
	Blank
}

$bodygroup "Cam" {
    studio "CExist.SMD"
	Blank
}

$weightlist aim_yaw {
    "Implicit" 0
    "Base" 0
    "Rotary_x" 1
    "Rotary_y" 0
}

$weightlist aim_pitch {
    "Implicit" 0
    "Base" 0
    "Rotary_x" 0
    "Rotary_y" 1
}

$poseparameter aim_pitch 90 30
$poseparameter aim_yaw -180 180 loop 360


$collisionmodel "Collision_Models.SMD" {
    $concave
    $maxconvexpieces 10000
}

$animation idle "anims/idle.SMD"

$animation forward "anims/forward.SMD" weightlist "aim_pitch"
$animation backward "anims/backward.SMD" weightlist "aim_pitch"

$animation yaw_1 "anims/yaw_360.SMD" frames 0 0 weightlist "aim_yaw" subtract idle 0
$animation yaw_2 "anims/yaw_360.SMD" frames 1 1 weightlist "aim_yaw" subtract idle 0
$animation yaw_3 "anims/yaw_360.SMD" frames 2 2 weightlist "aim_yaw" subtract idle 0
$animation yaw_4 "anims/yaw_360.SMD" frames 3 3 weightlist "aim_yaw" subtract idle 0
$animation yaw_5 "anims/yaw_360.SMD" frames 4 4 weightlist "aim_yaw" subtract idle 0

$sequence 0_idle idle addlayer aim_yaw addlayer aim_pitch
$sequence aim_pitch { backward forward } blend aim_pitch 90 20
$sequence aim_yaw { yaw_1 yaw_2 yaw_3 yaw_4 yaw_5 } blendwidth 5 blend aim_yaw -180 180 delta
