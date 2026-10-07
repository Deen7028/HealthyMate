<?php
// ส่วนนี้เป็น API endpoint สำหรับปรับขนาด/บีบอัดรูปก่อนจัดเก็บ
// คอมเมนท์ภาษาไทยช่วยแยกหน้าที่หลักของไฟล์โดยไม่แก้ logic เดิม


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
