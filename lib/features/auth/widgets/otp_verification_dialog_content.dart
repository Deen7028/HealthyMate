// ส่วนนี้อธิบายบทบาทของไฟล์: วิดเจ็ตย่อยของ UI ในฟีเจอร์การยืนยันตัวตนและกู้รหัสผ่าน (otp verification dialog content)
// คอมเมนท์ภาษาไทยถูกใส่ไว้เป็นส่วนๆ เพื่อช่วยไล่ flow โดยไม่เปลี่ยนพฤติกรรมเดิมของโค้ด

part of 'otp_verification_dialog.dart';

/// Extension สำหรับสร้าง UI layout ของหน้าต่างยืนยันรหัส OTP (ช่องกรอก 6 หลัก และปุ่มยืนยัน)
extension _OtpVerificationDialogContent on _OtpVerificationDialogState {
  Widget _buildDialog(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            /// แถวหัวข้อและปุ่มปิด
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SizedBox(width: 24),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.mark_email_read_outlined,
                    color: AppTheme.primaryGreen,
                    size: 36,
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.close_rounded,
                    color: AppTheme.textTertiary,
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  tooltip: 'ปิดหน้านี้',
                ),
              ],
            ),
            const SizedBox(height: 16),
            /// หัวข้อ "ยืนยันรหัส OTP"
            const Text(
              'ยืนยันรหัส OTP',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'กรอกรหัส 6 หลักที่เราส่งไปยัง\n${widget.sEmail}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            /// แถวกรอกรหัส OTP
            AnimatedBuilder(
              animation: _shakeAnimation,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(_shakeAnimation.value, 0),
                  child: child,
                );
              },
              child: TextField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 8,
                ),
                decoration: InputDecoration(
                  counterText: '',
                  hintText: '••••••',
                  filled: true,
                  fillColor: AppTheme.subtleSurface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            /// ปุ่มยืนยัน
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleVerify,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreen,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'ยืนยันรหัส',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
              ),
            ),
            const SizedBox(height: 12),
            /// ปุ่มส่งรหัส OTP ใหม่
            TextButton(
              onPressed: _nCountdown > 0 ? null : _handleResend,
              child: Text(
                _nCountdown > 0
                    ? 'ขอรหัสใหม่ได้ใน ($_nCountdown วิ)'
                    : 'ส่งรหัส OTP ใหม่อีกครั้ง',
                style: TextStyle(
                  color: _nCountdown > 0
                      ? AppTheme.textTertiary
                      : AppTheme.primaryGreen,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            /// ปุ่มเปลี่ยนที่อยู่อีเมล
            TextButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(
                Icons.edit_note_rounded,
                size: 18,
                color: AppTheme.primaryGreen,
              ),
              label: const Text(
                'เปลี่ยนที่อยู่อีเมล (Change Email)',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryGreen,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
