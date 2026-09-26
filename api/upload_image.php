<?php
require_once "db_connect.php";

$method = $_SERVER['REQUEST_METHOD'];

if ($method !== 'POST') {
    http_response_code(405);
    echo json_encode([
        "status" => "error",
        "message" => "Method not allowed. Use POST."
    ]);
    exit();
}

$userId = requireAuth();

// 1. กำหนดโฟลเดอร์สำหรับเก็บไฟล์รูปภาพ (เทียบจากตำแหน่งไฟล์นี้)
$uploadBaseDir = __DIR__ . "/uploads/";
if (!file_exists($uploadBaseDir)) {
    mkdir($uploadBaseDir, 0777, true);
}

// โฟลเดอร์ย่อยตามประเภท: 'profile', 'nutrition', หรือ 'general'
$type = isset($_POST['type']) ? trim($_POST['type']) : 'general';
$targetDir = $uploadBaseDir . $type . "/";
if (!file_exists($targetDir)) {
    mkdir($targetDir, 0777, true);
}

// 2. ตรวจสอบการส่งไฟล์ผ่าน Multipart Form-Data (ไฟล์ 'image' หรือ 'file')
$fileInputName = isset($_FILES['image']) ? 'image' : (isset($_FILES['file']) ? 'file' : null);

if ($fileInputName && isset($_FILES[$fileInputName]) && $_FILES[$fileInputName]['error'] === UPLOAD_ERR_OK) {
    $fileTmpPath = $_FILES[$fileInputName]['tmp_name'];
    $fileName = $_FILES[$fileInputName]['name'];
    $fileExtension = strtolower(pathinfo($fileName, PATHINFO_EXTENSION));

    // ตรวจสอบ Magic Bytes (MIME Type) จากเนื้อหาไฟล์ดิบเพื่อป้องกัน RCE / Web Shell
    $finfo = finfo_open(FILEINFO_MIME_TYPE);
    $mimeType = finfo_file($finfo, $fileTmpPath);
    finfo_close($finfo);

    $allowedMimes = [
        'jpg' => 'image/jpeg',
        'jpeg' => 'image/jpeg',
        'png' => 'image/png',
        'webp' => 'image/webp',
        'gif' => 'image/gif',
    ];

    if (!in_array($fileExtension, array_keys($allowedMimes)) || !in_array($mimeType, array_values($allowedMimes))) {
        echo json_encode([
            "status" => "error",
            "message" => "ไม่อนุญาตให้อัปโหลดไฟล์นี้"
        ], JSON_UNESCAPED_UNICODE);
        exit();
    }

    // สร้างชื่อไฟล์ใหม่แบบสุ่มและประทับเวลา เพื่อป้องกันชื่อไฟล์ซ้ำ
    $newFileName = uniqid($type . "_", true) . "." . $fileExtension;
    $destPath = $targetDir . $newFileName;

    if (optimizeAndSaveImage($fileTmpPath, $destPath, $mimeType)) {
        // Path สัมพัทธ์สำหรับบันทึกลง Database เช่น "uploads/profile/profile_123.jpg"
        $relativePath = "uploads/" . $type . "/" . $newFileName;

        // URL แบบเต็มสำหรับการเรียกใช้งานจากภายนอก/แอป
        $protocol = (!empty($_SERVER['HTTPS']) && $_SERVER['HTTPS'] !== 'off') ? "https://" : "http://";
        $currentUrl = $protocol . $_SERVER['HTTP_HOST'] . dirname($_SERVER['SCRIPT_NAME']);
        $fullUrl = rtrim($currentUrl, '/') . "/" . $relativePath;

        echo json_encode([
            "status" => "success",
            "message" => "อัปโหลดและบีบอัดรูปภาพสำเร็จ",
            "filePath" => $relativePath,   // <--- นำค่านี้ไปเก็บลง Database (Column sProfileImagePath / sImagePath)
            "fileUrl" => $fullUrl,        // <--- URL เต็ม สำหรับเปิดดูผ่าน Web / App
            "fileName" => $newFileName
        ], JSON_UNESCAPED_UNICODE);
        exit();
    } else {
        echo json_encode([
            "status" => "error",
            "message" => "ไม่สามารถบันทึกและย่อขนาดไฟล์ไปยังโฟลเดอร์ uploads ได้"
        ], JSON_UNESCAPED_UNICODE);
        exit();
    }
}

// 3. รองรับการส่งภาพแบบ Base64 (กรณีส่งผ่าน JSON body เช่น Flutter ถ่ายรูปแล้วส่งเป็น Base64)
$json = json_decode(file_get_contents("php://input"), true);
if ($json && !empty($json['base64Image'])) {
    $base64String = $json['base64Image'];
    $type = isset($json['type']) ? trim($json['type']) : 'general';
    $targetDir = $uploadBaseDir . $type . "/";
    if (!file_exists($targetDir)) {
        mkdir($targetDir, 0777, true);
    }

    // ตัดส่วน data:image/png;base64, ออกหากมี
    if (preg_match('/^data:image\/(\w+);base64,/', $base64String, $matches)) {
        $extension = strtolower($matches[1]);
        $base64String = substr($base64String, strpos($base64String, ',') + 1);
    } else {
        $extension = 'jpg';
    }

    $decodedData = base64_decode($base64String);
    if ($decodedData === false) {
        echo json_encode([
            "status" => "error",
            "message" => "ข้อมูล Base64 ไม่ถูกต้อง"
        ], JSON_UNESCAPED_UNICODE);
        exit();
    }

    // ตรวจสอบ Magic Bytes (MIME Type) ที่แท้จริงของไฟล์ป้องกันการอัปโหลดโค้ดอันตราย
    $finfo = finfo_open(FILEINFO_MIME_TYPE);
    $mimeType = finfo_buffer($finfo, $decodedData);
    finfo_close($finfo);

    $allowedMimes = ['image/jpeg', 'image/jpg', 'image/png', 'image/webp', 'image/gif'];
    if (!in_array($mimeType, $allowedMimes)) {
        echo json_encode([
            "status" => "error",
            "message" => "ไฟล์รูปภาพไม่ถูกต้อง หรือเป็นประเภทไฟล์ที่ไม่ได้รับอนุญาต ($mimeType)"
        ], JSON_UNESCAPED_UNICODE);
        exit();
    }

    $newFileName = uniqid($type . "_", true) . "." . $extension;
    $destPath = $targetDir . $newFileName;

    if (file_put_contents($destPath, $decodedData)) {
        $relativePath = "uploads/" . $type . "/" . $newFileName;
        $protocol = (!empty($_SERVER['HTTPS']) && $_SERVER['HTTPS'] !== 'off') ? "https://" : "http://";
        $currentUrl = $protocol . $_SERVER['HTTP_HOST'] . dirname($_SERVER['SCRIPT_NAME']);
        $fullUrl = rtrim($currentUrl, '/') . "/" . $relativePath;

        echo json_encode([
            "status" => "success",
            "message" => "บันทึกรูปภาพจาก Base64 สำเร็จ",
            "filePath" => $relativePath,
            "fileUrl" => $fullUrl,
            "fileName" => $newFileName
        ], JSON_UNESCAPED_UNICODE);
        exit();
    }
}

echo json_encode([
    "status" => "error",
    "message" => "ไม่พบไฟล์รูปภาพที่ส่งมา (กรุณาส่งผ่าน multipart/form-data key 'image' หรือ JSON body key 'base64Image')"
], JSON_UNESCAPED_UNICODE);

/**
 * ย่อขนาดและบีบอัดรูปภาพด้วย GD Library ให้ไม่เกิน 800x800 px เพื่อประหยัดพื้นที่และแบนด์วิดท์
 */
function optimizeAndSaveImage(string $sourcePath, string $destPath, string $mimeType, int $maxWidth = 800, int $maxHeight = 800, int $quality = 82): bool {
    if (!extension_loaded('gd')) {
        return move_uploaded_file($sourcePath, $destPath) || @copy($sourcePath, $destPath);
    }
    list($origWidth, $origHeight) = @getimagesize($sourcePath);
    if (!$origWidth || !$origHeight) {
        return move_uploaded_file($sourcePath, $destPath) || @copy($sourcePath, $destPath);
    }

    $ratio = min($maxWidth / $origWidth, $maxHeight / $origHeight);
    if ($ratio >= 1.0) {
        return move_uploaded_file($sourcePath, $destPath) || @copy($sourcePath, $destPath);
    }

    $newWidth = (int)round($origWidth * $ratio);
    $newHeight = (int)round($origHeight * $ratio);

    switch ($mimeType) {
        case 'image/jpeg':
        case 'image/jpg':
            $srcImg = @imagecreatefromjpeg($sourcePath);
            break;
        case 'image/png':
            $srcImg = @imagecreatefrompng($sourcePath);
            break;
        case 'image/webp':
            $srcImg = @imagecreatefromwebp($sourcePath);
            break;
        case 'image/gif':
            $srcImg = @imagecreatefromgif($sourcePath);
            break;
        default:
            $srcImg = false;
    }

    if (!$srcImg) {
        return move_uploaded_file($sourcePath, $destPath) || @copy($sourcePath, $destPath);
    }

    $dstImg = imagecreatetruecolor($newWidth, $newHeight);
    if ($mimeType === 'image/png' || $mimeType === 'image/webp') {
        imagealphablending($dstImg, false);
        imagesavealpha($dstImg, true);
    }

    imagecopyresampled($dstImg, $srcImg, 0, 0, 0, 0, $newWidth, $newHeight, $origWidth, $origHeight);

    $saved = false;
    switch ($mimeType) {
        case 'image/jpeg':
        case 'image/jpg':
            $saved = imagejpeg($dstImg, $destPath, $quality);
            break;
        case 'image/png':
            $saved = imagepng($dstImg, $destPath, 6);
            break;
        case 'image/webp':
            $saved = imagewebp($dstImg, $destPath, $quality);
            break;
        case 'image/gif':
            $saved = imagegif($dstImg, $destPath);
            break;
    }

    imagedestroy($srcImg);
    imagedestroy($dstImg);
    return $saved;
}
?>
