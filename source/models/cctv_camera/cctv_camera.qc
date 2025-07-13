$modelname "cameras/cctv_camera"
$cdmaterials "cameras"
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

$poseparameter aim_yaw -90 90
$poseparameter aim_pitch -20 60

$collisionmodel "Collision_Models.SMD" {
    $concave
    $maxconvexpieces 10000
}

$animation idle "anims/idle.SMD"

$animation forward "anims/down.SMD" weightlist "aim_pitch"
$animation backward "anims/up.SMD" weightlist "aim_pitch"
$animation right "anims/right.SMD" weightlist "aim_yaw" 
$animation left "anims/left.SMD" weightlist "aim_yaw"

$sequence 0_idle idle addlayer aim_yaw addlayer aim_pitch
$sequence aim_pitch { backward forward } blend aim_pitch -20 60
$sequence aim_yaw { left right } blend aim_yaw -90 90
