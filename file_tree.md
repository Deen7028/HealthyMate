# File Tree: lib (พร้อมคำอธิบายหน้าที่ของแต่ละไฟล์)

**Generated:** 10/8/2026, 2:10:12 AM
**Root Path:** `/home/kamaruding/modile/flutter/healthymate/lib`

```text
├── 📁 core      # แกนหลักของแอปพลิเคชัน (Config, Database, Services ทั่วไป)
│   ├── 📁 config
│   │   └── 📄 app_config.dart # จัดการค่า Configuration และ Environment Variables ของแอป
│   ├── 📁 database
│   │   ├── 📁 daos # Data Access Objects สำหรับจัดการตารางฐานข้อมูล SQLite
│   │   │   ├── 📁 activity_and_goals    # จัดการข้อมูลกิจกรรม สุขภาพ โภชนาการ และการแจ้งเตือน
│   │   │   │   ├── 📄 goal_preference_dao.dart       # บันทึกและดึงข้อมูลเป้าหมายและการตั้งค่า
│   │   │   │   ├── 📄 goal_preference_dao_devices.dart # จัดการข้อมูลอุปกรณ์ที่เชื่อมต่อ (เช่น Smartwatch)
│   │   │   │   ├── 📄 goal_preference_dao_keys.dart # จัดการเก็บ API Key (Gemini Vision)
│   │   │   │   ├── 📄 goal_preference_dao_pending_sync.dart # จัดการคิวข้อมูลที่รอซิงค์ขึ้น Cloud
│   │   │   │   ├── 📄 goal_preference_dao_sync_records.dart # จัดการบันทึกสถานะการซิงค์ข้อมูล
│   │   │   │   ├── 📄 health_record_dao.dart # จัดการประวัติการบันทึกค่าน้ำหนัก ส่วนสูง BMI
│   │   │   │   ├── 📄 notification_dao.dart               # จัดการรายการแจ้งเตือนในระบบ
│   │   │   │   ├── 📄 nutrition_dao.dart     # จัดการประวัติการบันทึกสารอาหารและมื้ออาหาร
│   │   │   │   └── 📄 workout_dao.dart       # จัดการประวัติการออกกำลังกายและพิกัดเส้นทาง
│   │   │   ├── 📁 routine                    # จัดการข้อมูลกิจวัตรประจำวัน
│   │   │   │   ├── 📄 routine_dao.dart         # ดึงข้อมูลรายการกิจวัตรของผู้ใช้
│   │   │   │   ├── 📄 routine_dao_history.dart  # ดึงประวัติความสำเร็จของกิจวัตรย้อนหลัง
│   │   │   │   ├── 📄 routine_dao_logs.dart     # บันทึก Log การปฏิบัติกิจวัตรในแต่ละวัน
│   │   │   │   └── 📄 routine_dao_mutations.dart  # เพิ่ม ลบ แก้ไข ข้อมูลกิจวัตร
│   │   │   └── 📁 user                        # จัดการข้อมูลบัญชีผู้ใช้
│   │   │       ├── 📄 user_dao.dart              # ค้นหาและดึงข้อมูลโปรไฟล์ผู้ใช้
│   │   │       ├── 📄 user_dao_credentials.dart  # ตรวจสอบรหัสผ่านและความปลอดภัย
│   │   │       ├── 📄 user_dao_registration.dart # สมัครสมาชิกและบันทึกผู้ใช้ใหม่
│   │   │       └── 📄 user_dao_session.dart      # จัดการสถานะการเข้าสู่ระบบและ Session
│   │   ├── 📄 app_database.dart           # คลาสหลักเชื่อมต่อฐานข้อมูล SQLite
│   │   ├── 📄 app_database_lifecycle.dart # จัดการเปิด-ปิด และการเริ่มต้น Database Connection
│   │   └── 📄 app_database_schema.dart        # สร้างตารางและโครงสร้าง Schema ของ SQLite
│   ├── 📁 services
│   │   ├── 📁 device                          # เซอร์วิสระดับฮาร์ดแวร์ของอุปกรณ์
│   │   │   ├── 📄 audio_service.dart                      # เล่นเสียงเอฟเฟกต์และแจ้งเตือน
│   │   │   ├── 📄 biometric_apple_auth_service.dart       # สแกนลายนิ้วมือ / ใบหน้า (Biometrics)
│   │   │   ├── 📄 location_background_service.dart        # ติดตามพิกัด GPS ขณะล็อกหน้าจอในเบื้องหลัง
│   │   │   ├── 📄 notification_service.dart               # ยิง Local Notification บนอุปกรณ์
│   │   │   ├── 📄 notification_service_scheduling.dart    # ตั้งเวลาเตือนกิจวัตรล่วงหน้า (Cron Scheduling)
│   │   │   └── 📄 tts_service.dart                        # แปลงข้อความเป็นเสียงพูด (Text-to-Speech)
│   │   ├── 📁 export
│   │   │   └── 📄 data_export_service.dart                # ส่งออกข้อมูลสุขภาพเป็นไฟล์ JSON / CSV
│   │   ├── 📁 health_kit
│   │   │   └── 📄 health_kit_connect_service.dart         # เชื่อมต่อ Apple Health / Google Fit
│   │   ├── 📁 routine_state                   # แจ้งเตือนสถานะความก้าวหน้าของกิจวัตรทั่วแอป
│   │   │   ├── 📄 routine_state_notifier.dart             # ตัวกระจาย State การอัปเดตกิจวัตร (Global Notifier)
│   │   │   ├── 📄 routine_state_notifier_goal_progress.dart # คำนวณความคืบหน้าของเป้าหมายหลัก
│   │   │   ├── 📄 routine_state_notifier_goals.dart       # โหลดและอัปเดตเป้าหมายหลัก
│   │   │   ├── 📄 routine_state_notifier_loading.dart     # โหลดรายการกิจวัตรทั้งหมด
│   │   │   └── 📄 routine_state_notifier_routines.dart    # จัดการสถานะความสำเร็จของกิจวัตร
│   │   ├── 📁 sync                            # เซอร์วิสซิงค์ข้อมูลกับระบบ Cloud
│   │   │   ├── 📄 sync_service.dart                       # ตัวจัดการคิวและวงจรการซิงค์ข้อมูล
│   │   │   ├── 📄 sync_service_downstream.dart            # ดึงข้อมูลล่าสุดจาก Cloud ลงเครื่อง (Downstream)
│   │   │   ├── 📄 sync_service_lifecycle.dart             # ตรวจสอบสถานะเน็ตและการเปิดแอปเพื่อซิงค์
│   │   │   ├── 📄 sync_service_sync_activity.dart         # ซิงค์ข้อมูลการออกกำลังกายขึ้นเซิร์ฟเวอร์
│   │   │   ├── 📄 sync_service_sync_records.dart          # ซิงค์ข้อมูลสถิติสุขภาพขึ้นเซิร์ฟเวอร์
│   │   │   ├── 📄 sync_service_sync_routines.dart         # ซิงค์ข้อมูลกิจวัตรขึ้นเซิร์ฟเวอร์
│   │   │   └── 📄 sync_service_upstream.dart              # ส่งข้อมูลที่รอซิงค์ขึ้น Cloud (Upstream)
│   │   ├── 📄 api_service.dart                # แม่แบบการยิง HTTP REST API
│   │   ├── 📄 api_service_config.dart         # กำหนด Base URL และ Headers สำหรับ API
│   │   ├── 📄 auth_service.dart               # ตรวจสอบ Token และจัดการสถานะ Authentication
│   │   ├── 📄 index.dart                      # Export เซอร์วิสหลักของ Core
│   │   ├── 📄 supabase_service.dart           # เชื่อมต่อฐานข้อมูลและ Authentication ของ Supabase
│   │   └── 📄 theme_service.dart              # จัดการสลับธีม Light / Dark Mode
│   ├── 📁 utils
│   │   ├── 📄 health_calculator.dart          # สูตรคำนวณ BMI, BMR, TDEE และแคลอรีที่เหมาะสม
│   │   └── 📄 route_utils.dart                # ยูทิลิตี้ช่วยนำทางเปลี่ยนหน้าจอ (Navigation Helpers)
│   └── 📄 index.dart                          # Export โมดูล Core ทั้งหมด
├── 📁 features                                # ฟีเจอร์หลักแบ่งตามโดเมนการใช้งาน
│   ├── 📁 auth                                # ระบบยืนยันตัวตน (เข้าสู่ระบบ, สมัครสมาชิก, ลืมรหัสผ่าน)
│   │   ├── 📁 forgot_password
│   │   │   ├── 📁 controllers
│   │   │   │   └── 📄 forgot_password_controller.dart     # จัดการ State และขั้นตอนขอรีเซ็ตรหัสผ่าน
│   │   │   ├── 📁 pages
│   │   │   │   └── 📄 forgot_password_page.dart           # หน้าจอขอรีเซ็ตรหัสผ่านและตั้งรหัสผ่านใหม่
│   │   │   ├── 📁 widgets
│   │   │   │   ├── 📄 forgot_password_email_form.dart     # ฟอร์มกรอกอีเมลรับ OTP รีเซ็ตรหัสผ่าน
│   │   │   │   ├── 📄 forgot_password_new_password_form.dart # ฟอร์มกรอกรหัสผ่านใหม่และยืนยัน
│   │   │   │   └── 📄 index.dart                          # Export วิดเจ็ตของ Forgot Password
│   │   │   └── 📄 index.dart
│   │   ├── 📁 login
│   │   │   ├── 📁 controllers
│   │   │   │   └── 📄 login_controller.dart               # จัดการ State และการตรวจสอบข้อมูลเข้าสู่ระบบ
│   │   │   ├── 📁 pages
│   │   │   │   └── 📄 login_page.dart                     # หน้าจอเข้าสู่ระบบ
│   │   │   ├── 📁 widgets
│   │   │   │   ├── 📄 index.dart
│   │   │   │   ├── 📄 login_error_banner.dart             # แบนเนอร์แสดงข้อผิดพลาดเมื่อเข้าสู่ระบบไม่ผ่าน
│   │   │   │   ├── 📄 login_footer_link.dart              # ลิงก์ด้านล่างไปหน้าสมัครสมาชิก
│   │   │   │   ├── 📄 login_form_fields.dart              # ช่องกรอกอีเมลและรหัสผ่าน
│   │   │   │   ├── 📄 login_header.dart                   # โลโก้และหัวข้อต้อนรับหน้าเข้าสู่ระบบ
│   │   │   │   ├── 📄 login_submit_button.dart            # ปุ่มกดยืนยันเข้าสู่ระบบ
│   │   │   │   └── 📄 social_login_buttons.dart           # ปุ่มเข้าสู่ระบบด้วย Google / Apple
│   │   │   └── 📄 index.dart
│   │   ├── 📁 register
│   │   │   ├── 📁 controllers
│   │   │   │   └── 📄 register_controller.dart            # จัดการ State และบันทึกข้อมูลผู้ใช้ใหม่
│   │   │   ├── 📁 pages
│   │   │   │   ├── 📄 register_fade_slide_entrance.dart   # แอนิเมชันเปิดหน้าจอ Register
│   │   │   │   ├── 📄 register_page.dart                  # หน้าจอสมัครสมาชิก
│   │   │   │   ├── 📄 register_page_actions.dart          # จัดการ Action ปุ่มกดและ Event หน้าสมัครสมาชิก
│   │   │   │   └── 📄 register_page_content.dart          # เลย์เอาต์และโครงสร้าง UI หน้าสมัครสมาชิก
│   │   │   ├── 📁 utils
│   │   │   │   └── 📄 password_validator.dart             # ตรวจสอบความยากง่ายของรหัสผ่าน (Validation Rules)
│   │   │   ├── 📁 widgets
│   │   │   │   ├── 📄 index.dart
│   │   │   │   ├── 📄 password_requirements_card.dart     # การ์ดแสดงเงื่อนไขรหัสผ่าน (เช่น ตัวพิมพ์เล็ก/ใหญ่/ตัวเลข)
│   │   │   │   ├── 📄 register_consent_section.dart       # ช่องติ๊กยินยอมข้อกำหนดและนโยบายความเป็นส่วนตัว
│   │   │   │   ├── 📄 register_footer_link.dart           # ลิงก์กลับไปหน้าเข้าสู่ระบบ
│   │   │   │   ├── 📄 register_form_fields.dart           # ฟิลด์กรอกข้อมูลชื่อ อีเมล รหัสผ่าน วันเกิด เพศ
│   │   │   │   ├── 📄 register_form_fields_content.dart   # โครงสร้างจัดวางฟิลด์ข้อมูลการสมัคร
│   │   │   │   ├── 📄 register_header.dart                # หัวข้อหน้าจอสมัครสมาชิก
│   │   │   │   ├── 📄 register_submit_button.dart         # ปุ่มกดยืนยันการสมัคร
│   │   │   │   └── 📄 terms_privacy_sheets.dart           # ป๊อบอัพแสดงข้อตกลงและนโยบายความเป็นส่วนตัว
│   │   │   └── 📄 index.dart
│   │   ├── 📁 services
│   │   │   ├── 📄 auth_api_service.dart                   # ยิง API สมัครสมาชิก/เข้าสู่ระบบกับเซิร์ฟเวอร์
│   │   │   └── 📄 email_api_service.dart                  # ส่งอีเมลรหัส OTP สำหรับยืนยันตัวตน
│   │   ├── 📁 widgets
│   │   │   ├── 📄 index.dart
│   │   │   ├── 📄 otp_verification_dialog.dart            # หน้าต่าง Dialog กรอกรหัส OTP ยืนยันอีเมล
│   │   │   ├── 📄 otp_verification_dialog_actions.dart    # จัดการ Action ส่งซ้ำและตรวจสอบรหัส OTP
│   │   │   └── 📄 otp_verification_dialog_content.dart    # เลย์เอาต์ช่องกรอกตัวเลข OTP
│   │   └── 📄 index.dart
│   ├── 📁 dashboard                           # แดชบอร์ดสรุปภาพรวมสุขภาพและกิจกรรมประจำวัน
│   │   ├── 📁 controllers
│   │   │   ├── 📄 dashboard_controller.dart               # จัดการ State ภาพรวมบนหน้าแดชบอร์ด
│   │   │   ├── 📄 dashboard_controller_loading.dart       # โหลดข้อมูลสรุปกิจวัตร แคลอรี และน้ำหนัก
│   │   │   └── 📄 dashboard_controller_sync.dart          # ติดตามและอัปเดตข้อมูลอัตโนมัติเมื่อมีการเปลี่ยนแปลง
│   │   ├── 📁 models
│   │   │   └── 📄 dashboard_data.dart                     # โมเดลข้อมูลสถิติและการสรุปผลบนแดชบอร์ด
│   │   ├── 📁 pages
│   │   │   ├── 📄 dashboard_page.dart                     # หน้าจอแดชบอร์ดหลัก
│   │   │   ├── 📄 dashboard_page_actions.dart             # จัดการ Action นำทางไปแท็บอื่นหรือเริ่มกิจกรรม
│   │   │   └── 📄 dashboard_page_content.dart             # เลย์เอาต์และโครงสร้างคอมโพเนนต์หน้าแดชบอร์ด
│   │   ├── 📁 services
│   │   │   └── 📄 dashboard_api_service.dart              # ดึงข้อมูลสรุปสถิติสุขภาพจากเซิร์ฟเวอร์
│   │   ├── 📁 utils
│   │   │   └── 📄 dashboard_ui_helpers.dart               # ฟังก์ชันแปลงวันที่ไทย ไอคอน และรูปแบบข้อความ
│   │   ├── 📁 widgets
│   │   │   ├── 📁 header_and_stats                        # ส่วนหัว แถบปฏิทิน และการ์ดสถิติด่วน
│   │   │   │   ├── 📄 activity_progress_ring.dart         # วงแหวนแสดงเปอร์เซ็นต์ความสำเร็จของกิจกรรม
│   │   │   │   ├── 📄 calendar_strip_day_item.dart        # ช่องแสดงวันในแถบปฏิทินสัปดาห์
│   │   │   │   ├── 📄 calendar_strip_widget.dart          # แถบปฏิทินสัปดาห์พร้อมสรุปสถิติรวม
│   │   │   │   ├── 📄 dashboard_header.dart               # ส่วนหัวทักทายผู้ใช้ รูปโปรไฟล์ และแจ้งเตือน
│   │   │   │   ├── 📄 key_stats_grid.dart                 # กริดแสดงสถิติหลัก (ระยะทาง, แคลอรี, เวลา)
│   │   │   │   └── 📄 key_stats_grid_cards.dart           # การ์ดสถิติย่อยแต่ละประเภท
│   │   │   ├── 📁 health_summary                          # การ์ดสรุปสุขภาพและโภชนาการ
│   │   │   │   ├── 📄 dashboard_health_summary_card.dart  # การ์ดสรุปสุขภาพและสารอาหารประจำวัน
│   │   │   │   ├── 📄 dashboard_health_summary_card_burn.dart # สรุปแคลอรีที่เผาผลาญจากการออกกำลังกาย
│   │   │   │   ├── 📄 dashboard_health_summary_card_layout.dart # โครงสร้างการจัดวางการ์ดสรุปสุขภาพ
│   │   │   │   ├── 📄 dashboard_health_summary_card_nutrition.dart # สรุปแคลอรีและสารอาหารที่ได้รับ
│   │   │   │   ├── 📄 dashboard_health_summary_card_nutrition_energy.dart # แถบเปรียบเทียบแคลอรี In/Out
│   │   │   │   ├── 📄 dashboard_health_summary_card_nutrition_header.dart # ส่วนหัวการ์ดโภชนาการ
│   │   │   │   ├── 📄 dashboard_health_summary_card_nutrition_preview.dart # พรีวิวรายการอาหารที่สแกนล่าสุด
│   │   │   │   ├── 📄 dashboard_health_summary_card_personal.dart # สรุปน้ำหนักและค่า BMI ปัจจุบัน
│   │   │   │   └── 📄 dashboard_health_summary_card_stat_ui.dart # การ์ดแสดงผลตัวเลขสถิติ
│   │   │   ├── 📁 main_goal                               # คอมโพเนนต์เป้าหมายหลัก
│   │   │   │   ├── 📄 dashboard_main_goal_card.dart       # การ์ดแสดงเป้าหมายหลักบนแดชบอร์ด
│   │   │   │   ├── 📄 dashboard_main_goal_card_helpers.dart # ฟังก์ชันช่วยคำนวณเปอร์เซ็นต์และข้อความเป้าหมาย
│   │   │   │   ├── 📄 dashboard_main_goal_card_presentation.dart # ส่วนแสดงผล UI และธีมสีเป้าหมาย
│   │   │   │   ├── 📄 dashboard_main_goal_stats.dart      # สถิติและจำนวนวันที่เหลือของเป้าหมาย
│   │   │   │   ├── 📄 main_goal_card.dart                 # วิดเจ็ตการ์ดเป้าหมายหลัก
│   │   │   │   ├── 📄 main_goal_card_calculations.dart    # คำนวณความคืบหน้ารวมของเป้าหมาย
│   │   │   │   ├── 📄 main_goal_card_presentation.dart    # ดีไซน์และการตกแต่งการ์ดเป้าหมาย
│   │   │   │   ├── 📄 main_goal_card_setup_button.dart    # ปุ่มสำหรับตั้งเป้าหมายหลักใหม่
│   │   │   │   ├── 📄 main_goal_card_stat_ui.dart         # แถบ Progress Bar ของเป้าหมาย
│   │   │   │   └── 📄 main_goal_card_status_footer.dart   # ข้อความสรุปสถานะด้านล่างการ์ดเป้าหมาย
│   │   │   ├── 📁 other_goals                             # เป้าหมายอื่นๆ และปุ่ม Action
│   │   │   │   ├── 📄 daily_routine_checklist.dart        # เช็กลิสต์กิจวัตรประจำวัน
│   │   │   │   ├── 📄 dashboard_action_buttons.dart       # ปุ่มลัดเริ่มกิจกรรมและตั้งเป้าหมาย
│   │   │   │   ├── 📄 dashboard_other_goals_card.dart     # การ์ดแสดงรายการเป้าหมายย่อยอื่นๆ
│   │   │   │   ├── 📄 dashboard_other_goals_card_item.dart # แถวแสดงรายการกิจวัตรแต่ละอัน
│   │   │   │   └── 📄 start_workout_cta.dart              # ปุ่ม Call-To-Action เริ่มออกกำลังกายทันที
│   │   │   └── 📄 index.dart
│   │   └── 📄 index.dart
│   ├── 📁 food_recognition                    # ระบบวิเคราะห์อาหารและโภชนาการด้วย AI (Gemini Vision)
│   │   ├── 📁 models
│   │   │   └── 📄 food_recognition_models.dart            # โมเดลรายการอาหาร, โภชนาการ, และมื้ออาหาร
│   │   ├── 📁 services
│   │   │   ├── 📄 food_recognition_analysis.dart          # ฟังก์ชันหลักสั่งวิเคราะห์ภาพอาหาร
│   │   │   ├── 📄 food_recognition_gemini.dart            # เชื่อมต่อ Google Gemini 1.5 Flash Vision API
│   │   │   ├── 📄 food_recognition_parsing.dart           # ถอดรหัสและแปลงผลลัพธ์ JSON จาก AI
│   │   │   ├── 📄 food_recognition_service.dart           # เซอร์วิสหลักในการสแกนและวิเคราะห์อาหาร
│   │   │   └── 📄 food_recognition_values.dart            # ฟังก์ชันตรวจสอบและปรับเทียบค่าตัวเลขสารอาหาร
│   │   ├── 📁 widgets
│   │   │   ├── 📁 cards                                   # การ์ดสรุปผลและคำแนะนำ
│   │   │   │   ├── 📄 burn_it_off_advisor_card.dart       # การ์ดแนะนำเวลาออกกำลังกายเพื่อเผาผลาญอาหารมื้อนี้
│   │   │   │   ├── 📄 detected_food_item_card.dart        # การ์ดรายการอาหารแต่ละจานที่ AI ตรวจพบ
│   │   │   │   ├── 📄 empty_food_recognition_card.dart    # การ์ดแจ้งเตือนกรณีตรวจไม่พบอาหารในภาพ
│   │   │   │   └── 📄 food_nutrition_summary_card.dart    # การ์ดสรุปแคลอรีรวมและสารอาหาร 3 หมู่
│   │   │   ├── 📁 dialogs                                 # Dialogs แก้ไขข้อมูลและ API Key
│   │   │   │   ├── 📄 edit_food_item_dialog.dart          # กล่องข้อความแก้ไขชื่อและแคลอรีของอาหาร
│   │   │   │   ├── 📄 edit_food_item_dialog_content.dart  # เลย์เอาต์ฟอร์มแก้ไขอาหาร
│   │   │   │   ├── 📄 edit_food_item_dialog_sections.dart # ช่องกรอกสารอาหารโปรตีน คาร์บ ไขมัน
│   │   │   │   ├── 📄 gemini_api_key_dialog.dart          # กล่องข้อความสำหรับตั้งค่า Gemini API Key
│   │   │   │   ├── 📄 gemini_api_key_dialog_content.dart  # เลย์เอาต์และคำแนะนำการขอ API Key
│   │   │   │   └── 📄 gemini_api_key_dialog_save.dart     # ฟังก์ชันบันทึก API Key ลงเครื่อง
│   │   │   ├── 📁 result_sheet                            # หน้าต่าง BottomSheet แสดงผลการสแกนอาหาร
│   │   │   │   ├── 📄 food_recognition_result_sheet.dart  # BottomSheet แสดงผลวิเคราะห์ภาพอาหาร
│   │   │   │   ├── 📄 food_recognition_result_sheet_actions.dart # Action แก้ไข ลบ หรือเพิ่มรายการอาหาร
│   │   │   │   ├── 📄 food_recognition_result_sheet_body.dart # โครงสร้างเนื้อหาใน Result Sheet
│   │   │   │   ├── 📄 food_recognition_result_sheet_chrome.dart # แถบหัวและภาพอาหารด้านบน
│   │   │   │   ├── 📄 food_recognition_result_sheet_content.dart # เลย์เอาต์สรุปข้อมูลอาหาร
│   │   │   │   ├── 📄 food_recognition_result_sheet_items.dart # ลิสต์รายการอาหารที่ตรวจพบ
│   │   │   │   └── 📄 food_recognition_result_sheet_save.dart # บันทึกข้อมูลมื้ออาหารและซิงค์กับกิจวัตร
│   │   │   └── 📄 index.dart
│   │   └── 📄 index.dart
│   ├── 📁 health_calculator                   # เครื่องคำนวณสุขภาพ (BMI, BMR, TDEE, แคลอรีเป้าหมาย)
│   │   ├── 📁 controllers
│   │   │   ├── 📄 health_calculator_controller.dart       # ควบคุม State และการคำนวณสุขภาพ
│   │   │   ├── 📄 health_calculator_controller_calculation.dart # สูตรประมวลผล BMI, BMR, TDEE
│   │   │   ├── 📄 health_calculator_controller_inputs.dart # จัดการค่า Input น้ำหนัก ส่วนสูง อายุ เพศ
│   │   │   ├── 📄 health_calculator_controller_loading.dart # โหลดข้อมูลสุขภาพล่าสุดของผู้ใช้
│   │   │   └── 📄 health_calculator_controller_persistence.dart # บันทึกสถิติสุขภาพลง SQLite และ Cloud
│   │   ├── 📁 models
│   │   │   ├── 📄 activity_level.dart                     # Enum ระดับกิจกรรมประจำวัน (Activity Level)
│   │   │   ├── 📄 calculation_record.dart                 # โมเดลประวัติการคำนวณสุขภาพ
│   │   │   ├── 📄 health_record_model.dart                # โมเดลข้อมูลสถิติร่างกาย (น้ำหนัก, BMI)
│   │   │   └── 📄 user_model.dart                         # โมเดลโปรไฟล์ผู้ใช้งาน
│   │   ├── 📁 pages
│   │   │   ├── 📄 health_calculator_page.dart             # หน้าจอหลักเครื่องคำนวณสุขภาพ
│   │   │   ├── 📄 health_calculator_page_actions.dart     # Action บันทึกค่าและดูประวัติ
│   │   │   ├── 📄 health_calculator_page_content.dart     # โครงสร้างเลย์เอาต์หน้าจอคำนวณ
│   │   │   └── 📄 health_calculator_page_inputs.dart      # โซนฟอร์มกรอกข้อมูลร่างกาย
│   │   ├── 📁 widgets
│   │   │   ├── 📁 history                                 # ประวัติและกราฟแนวโน้มน้ำหนัก
│   │   │   │   ├── 📄 history_bottom_sheet.dart           # BottomSheet แสดงประวัติสุขภาพย้อนหลัง
│   │   │   │   ├── 📄 history_bottom_sheet_graph.dart     # กราฟแสดงแนวโน้มน้ำหนักตามช่วงเวลา
│   │   │   │   ├── 📄 history_bottom_sheet_items.dart     # ลิสต์รายการบันทึกประวัติสุขภาพ
│   │   │   │   └── 📄 weight_chart_painter.dart           # CustomPainter วาดเส้นกราฟน้ำหนัก
│   │   │   ├── 📁 inputs                                  # ฟอร์มรับข้อมูลร่างกาย
│   │   │   │   ├── 📄 activity_level_picker.dart          # ตัวเลือกระดับกิจกรรม (ไม่ออกกำลังกาย - หนักมาก)
│   │   │   │   ├── 📄 gender_selector.dart                # ตัวเลือกเพศ (ชาย / หญิง)
│   │   │   │   └── 📄 health_calculator_input_field.dart  # ช่องกรอกน้ำหนัก ส่วนสูง อายุ
│   │   │   ├── 📁 results                                 # การ์ดแสดงผลลัพธ์สุขภาพ
│   │   │   │   ├── 📄 bmi_indicator_bar.dart              # แถบสเกลสีแสดงระดับค่า BMI
│   │   │   │   ├── 📄 calorie_target_card.dart            # การ์ดเป้าหมายแคลอรีเพื่อรักษาน้ำหนัก/ลดไขมัน
│   │   │   │   ├── 📄 health_calculator_result_content.dart # รายละเอียดผลลัพธ์ BMR และ TDEE
│   │   │   │   ├── 📄 health_calculator_result_section.dart # ส่วนแสดงผลรวมค่าสุขภาพ
│   │   │   │   └── 📄 result_card.dart                    # การ์ดแสดงตัวเลขผลลัพธ์เดี่ยว
│   │   │   └── 📄 index.dart
│   │   └── 📄 index.dart
│   ├── 📁 notifications                       # ศูนย์การแจ้งเตือนและการตั้งค่าแจ้งเตือน
│   │   ├── 📁 controllers
│   │   │   └── 📄 notification_controller.dart            # จัดการ State รายการแจ้งเตือนและการกรอง
│   │   ├── 📁 models
│   │   │   └── 📄 notification_item.dart                  # โมเดลรายการแจ้งเตือนและหมวดหมู่
│   │   ├── 📁 pages
│   │   │   ├── 📄 notification_settings_page.dart         # หน้าจอตั้งค่าการแจ้งเตือน (เปิด/ปิด เสียง/สั่น)
│   │   │   └── 📄 notifications_page.dart                 # หน้าจอศูนย์รวมการแจ้งเตือนทั้งหมด
│   │   ├── 📁 services
│   │   │   └── 📄 app_notification_service.dart           # เซอร์วิสสร้างและจัดการแจ้งเตือนภายในแอป
│   │   └── 📁 widgets
│   │       ├── 📄 notification_empty_view.dart            # หน้าระบุว่าไม่มีการแจ้งเตือนใหม่
│   │       ├── 📄 notification_filter_bar.dart            # แถบแท็บกรองหมวดหมู่การแจ้งเตือน
│   │       └── 📄 notification_item_card.dart             # การ์ดแสดงรายการแจ้งเตือนแต่ละข้อความ
│   ├── 📁 onboarding                          # หน้าจอต้อนรับและตั้งค่าเริ่มต้นสำหรับผู้ใช้ใหม่
│   │   ├── 📁 models
│   │   │   └── 📄 onboarding_goal_template.dart           # โมเดลเทมเพลตเป้าหมายเริ่มต้น
│   │   ├── 📁 pages
│   │   │   ├── 📄 onboarding_slides_page.dart             # สไลด์แนะนำฟีเจอร์เด่นของแอป
│   │   │   ├── 📄 onboarding_wizard_page.dart             # ขั้นตอน Wizard แนะนำการใช้งาน
│   │   │   └── 📄 profile_setup_wizard_page.dart          # วิซาร์ดกรอกข้อมูลร่างกายครั้งแรก
│   │   ├── 📁 services
│   │   │   └── 📄 onboarding_service.dart                 # บันทึกสถานะว่าผู้ใช้ผ่านหน้า Onboarding แล้ว
│   │   ├── 📁 widgets
│   │   │   ├── 📄 step1_welcome_view.dart                 # สเต็ปที่ 1: หน้าจอต้อนรับ
│   │   │   ├── 📄 step2_body_metrics_view.dart            # สเต็ปที่ 2: กรอกน้ำหนัก ส่วนสูง เพศ
│   │   │   └── 📄 step3_primary_goal_view.dart            # สเต็ปที่ 3: เลือกเป้าหมายหลักเริ่มต้น
│   │   └── 📄 index.dart
│   ├── 📁 practice                            # ระบบกิจวัตรประจำวันและเป้าหมายสุขภาพ (Routines & Goals)
│   │   ├── 📁 controllers
│   │   │   ├── 📁 crud                                    # จัดการข้อมูลกิจวัตรพื้นฐาน
│   │   │   │   ├── 📄 routine_controller_create.dart      # สร้างกิจวัตรใหม่พร้อมตั้งเวลาเตือน
│   │   │   │   ├── 📄 routine_controller_goals.dart       # จัดการเป้าหมายหลัก
│   │   │   │   ├── 📄 routine_controller_load.dart        # โหลดข้อมูลกิจวัตรและประวัติ
│   │   │   │   ├── 📄 routine_controller_load_rows.dart   # แปลงแถวข้อมูลจาก Database
│   │   │   │   ├── 📄 routine_controller_mutations.dart   # แก้ไขและลบกิจวัตร
│   │   │   │   └── 📄 routine_controller_progress.dart    # อัปเดตความคืบหน้าของกิจวัตร (Check/Uncheck)
│   │   │   ├── 📁 sync                                    # ซิงค์ข้อมูลกิจวัตรและการออกกำลังกาย
│   │   │   │   ├── 📄 routine_controller_goal_sync.dart   # ซิงค์ความคืบหน้าเข้ากับเป้าหมายหลัก
│   │   │   │   ├── 📄 routine_controller_overall_progress.dart # คำนวณเปอร์เซ็นต์ความสำเร็จรวม
│   │   │   │   ├── 📄 routine_controller_sync.dart        # ตรวจจับการเปลี่ยนแปลงเพื่ออัปเดต State
│   │   │   │   ├── 📄 routine_controller_workout_stats.dart # คำนวณสถิติกิจวัตรที่เชื่อมกับ Workout
│   │   │   │   └── 📄 routine_controller_workout_sync.dart # ซิงค์ผลการออกกำลังกายเข้าสู่กิจวัตร
│   │   │   └── 📄 routine_controller.dart                 # Controller หลักของหน้า My Routines
│   │   ├── 📁 models
│   │   │   └── 📄 routine_item.dart                       # โมเดลข้อมูลกิจวัตร, หมวดหมู่, และประเภทปุ่ม
│   │   ├── 📁 pages
│   │   │   ├── 📁 completed_goals                         # หน้าประวัติความสำเร็จ
│   │   │   │   ├── 📄 completed_goals_and_routines_page.dart # หน้าจอรวมเป้าหมายและกิจวัตรที่ทำสำเร็จ
│   │   │   │   ├── 📄 completed_goals_empty_state.dart    # แสดงผลเมื่อยังไม่มีประวัติความสำเร็จ
│   │   │   │   ├── 📄 completed_goals_history.dart        # สรุปภาพรวมประวัติความสำเร็จ
│   │   │   │   ├── 📄 completed_goals_page_content.dart   # โครงสร้างแท็บประวัติ
│   │   │   │   ├── 📄 completed_goals_tab.dart            # แท็บรายการเป้าหมายหลักที่พิชิตได้
│   │   │   │   └── 📄 completed_routines_tab.dart         # แท็บรายการกิจวัตรที่ทำสำเร็จ
│   │   │   └── 📁 routine_notification                    # หน้าจัดการรายการกิจวัตรประจำวัน
│   │   │       ├── 📄 routine_notification_page.dart      # หน้าจอรายการกิจวัตรของฉัน (My Routines)
│   │   │       ├── 📄 routine_notification_page_actions.dart # Action เพิ่ม ลบ แก้ไข กิจวัตร
│   │   │       ├── 📄 routine_notification_page_card.dart # การ์ดแสดงกิจวัตรแต่ละรายการ
│   │   │       ├── 📄 routine_notification_page_card_actions.dart # จัดการปุ่มกดติ๊กถูก/นับครั้ง/จับเวลา
│   │   │       ├── 📄 routine_notification_page_content.dart # เลย์เอาต์และโครงสร้างหน้า My Routines
│   │   │       ├── 📄 routine_notification_page_dialogs.dart # ป๊อบอัพยืนยันลบหรือแก้ไขกิจวัตร
│   │   │       ├── 📄 routine_notification_page_grouping.dart # จัดกลุ่มกิจวัตรตามหมวดหมู่
│   │   │       └── 📄 routine_notification_page_sections.dart # แบนเนอร์หัวหน้าและส่วนแสดงเป้าหมาย
│   │   ├── 📁 services
│   │   │   ├── 📄 goal_api_service.dart                   # ยิง API บันทึกและซิงค์เป้าหมายกับเซิร์ฟเวอร์
│   │   │   └── 📄 routine_api_service.dart                # ยิง API จัดการกิจวัตรกับเซิร์ฟเวอร์
│   │   ├── 📁 widgets
│   │   │   ├── 📁 add_routine                             # คอมโพเนนต์สำหรับสร้างกิจวัตรใหม่
│   │   │   │   ├── 📁 dialog
│   │   │   │   │   ├── 📄 add_routine_dialog.dart         # Dialog หลักสร้างกิจวัตรใหม่ 3 ขั้นตอน
│   │   │   │   │   ├── 📄 add_routine_dialog_actions.dart # Action ควบคุมการเปลี่ยนขั้นตอนและบันทึก
│   │   │   │   │   ├── 📄 add_routine_dialog_content.dart # โครงสร้าง PageView ภายใน Dialog
│   │   │   │   │   └── 📄 add_routine_dialog_steps.dart   # แถบแสดงขั้นตอนความคืบหน้า (Step Indicator)
│   │   │   │   ├── 📁 steps
│   │   │   │   │   ├── 📄 routine_step_category.dart      # ขั้นตอนที่ 1: เลือกหมวดหมู่กิจวัตร
│   │   │   │   │   ├── 📄 routine_step_goal.dart          # ขั้นตอนที่ 2: ตั้งชื่อและเป้าหมายตัวเลข
│   │   │   │   │   ├── 📄 routine_step_goal_content.dart  # ฟอร์มกรอกเป้าหมายและเลือกลิงก์ GPS
│   │   │   │   │   └── 📄 routine_step_goal_unit_button.dart # ปุ่มเลือกหน่วยนับ (เช่น ครั้ง, แก้ว, นาที)
│   │   │   │   └── 📁 style
│   │   │   │       ├── 📄 routine_step_style.dart         # ขั้นตอนที่ 3: เลือกรูปแบบการทำกิจวัตร
│   │   │   │       ├── 📄 routine_step_style_content.dart # โครงสร้างตัวเลือกสไตล์กิจวัตร
│   │   │   │       ├── 📄 routine_step_style_interval.dart # ตั้งค่าช่วงเวลาเตือนทุกๆ X นาที/ชั่วโมง
│   │   │   │       ├── 📄 routine_step_style_modes.dart   # เลือกโหมด (ทำครั้งเดียว, หลายครั้ง, ช่วงเวลา)
│   │   │   │       ├── 📄 routine_step_style_multiple_times.dart # ตั้งเวลาเตือนหลายช่วงเวลาต่อวัน
│   │   │   │       ├── 📄 routine_step_style_selectors.dart # วิดเจ็ตเลือกเวลา (Time Picker)
│   │   │   │       └── 📄 routine_step_style_single_time.dart # ตั้งเวลาเตือนแบบระบุเวลาเดียว
│   │   │   ├── 📁 cards                                   # การ์ดแสดงผลกิจวัตร
│   │   │   │   ├── 📄 progress_summary_card.dart          # การ์ดสรุปจำนวนกิจวัตรที่ทำเสร็จในวันนี้
│   │   │   │   ├── 📄 routine_card.dart                   # การ์ดกิจวัตรแบบย่อ
│   │   │   │   ├── 📄 routine_card_progress.dart          # แถบแสดงความคืบหน้าในกิจวัตร
│   │   │   │   ├── 📄 routine_card_widget.dart            # การ์ดกิจวัตรแบบเต็มพร้อมปุ่มสั่งการ
│   │   │   │   ├── 📄 routine_top_overview_banner.dart    # แบนเนอร์สรุปภาพรวมด้านบนสุด
│   │   │   │   └── 📄 routine_top_overview_workout_summary.dart # สรุปการออกกำลังกายที่เชื่อมโยง
│   │   │   ├── 📁 common                                  # วิดเจ็ตทั่วไป
│   │   │   │   ├── 📄 routine_empty_view.dart             # แสดงเมื่อยังไม่มีกิจวัตรในระบบ
│   │   │   │   └── 📄 routine_gps_sync_option.dart        # สวิตช์เปิด-ปิดการซิงค์อัตโนมัติกับ GPS
│   │   │   ├── 📁 main_goal                               # วิดเจ็ตเป้าหมายหลัก
│   │   │   │   ├── 📄 add_main_goal_bottom_sheet.dart     # BottomSheet ตั้งค่าเป้าหมายหลักใหม่
│   │   │   │   ├── 📄 add_main_goal_bottom_sheet_actions.dart # Action บันทึกเป้าหมายหลัก
│   │   │   │   ├── 📄 add_main_goal_bottom_sheet_actions_ui.dart # ปุ่มกดยืนยันบันทึกเป้าหมาย
│   │   │   │   ├── 📄 add_main_goal_bottom_sheet_sections.dart # ฟอร์มกรอกชื่อ ค่าเป้าหมาย และวันสิ้นสุด
│   │   │   │   ├── 📄 main_goal_template.dart             # เทมเพลตเป้าหมายยอดนิยม (ลดน้ำหนัก, วิ่ง)
│   │   │   │   ├── 📄 routine_main_goal_card.dart         # การ์ดแสดงเป้าหมายหลักในหน้า Routines
│   │   │   │   ├── 📄 routine_main_goal_card_empty.dart   # การ์ดแสดงเมื่อยังไม่ได้ตั้งเป้าหมายหลัก
│   │   │   │   └── 📄 routine_main_goal_card_header.dart  # ส่วนหัวของการ์ดเป้าหมายหลัก
│   │   │   ├── 📁 timer                                   # ตัวจับเวลาถอยหลังการปฏิบัติ
│   │   │   │   ├── 📄 routine_countdown_timer_actions.dart # Action เริ่ม/หยุด/รีเซ็ต ตัวนับเวลา
│   │   │   │   ├── 📄 routine_countdown_timer_content.dart # หน้าปัดนาฬิกาและวงแหวนนับถอยหลัง
│   │   │   │   └── 📄 routine_countdown_timer_modal.dart  # หน้าต่าง Modal ป๊อบอัพจับเวลาถอยหลัง
│   │   │   └── 📄 index.dart
│   │   └── 📄 index.dart
│   ├── 📁 profile                             # ข้อมูลส่วนตัว บัญชีผู้ใช้ และการตั้งค่าระบบ
│   │   ├── 📁 controllers
│   │   │   ├── 📄 profile_controller.dart                 # จัดการ State ภาพรวมของหน้า Profile
│   │   │   ├── 📄 profile_controller_account.dart         # จัดการข้อมูลบัญชี อีเมล และรหัสผ่าน
│   │   │   ├── 📄 profile_controller_api_key.dart         # จัดการบันทึก Gemini API Key
│   │   │   ├── 📄 profile_controller_devices.dart         # จัดการเชื่อมต่ออุปกรณ์สุขภาพ
│   │   │   ├── 📄 profile_controller_images.dart          # อัปโหลดและเปลี่ยนรูปโปรไฟล์
│   │   │   ├── 📄 profile_controller_loading.dart         # โหลดข้อมูลผู้ใช้และสถิติจากฐานข้อมูล
│   │   │   └── 📄 profile_controller_preferences.dart     # จัดการการตั้งค่าหน่วยวัด (กก./ปอนด์, ซม./นิ้ว)
│   │   ├── 📁 pages
│   │   │   ├── 📄 profile_page.dart                       # หน้าจอโปรไฟล์หลัก
│   │   │   ├── 📄 profile_page_account_actions.dart       # Action แก้ไขบัญชีและออกจากระบบ
│   │   │   ├── 📄 profile_page_content.dart               # เลย์เอาต์และโครงสร้างหน้าโปรไฟล์
│   │   │   ├── 📄 profile_page_image_actions.dart         # Action ถ่ายภาพหรือเลือกรูปจากแกลเลอรี
│   │   │   └── 📄 profile_page_sheets.dart                # เปิด BottomSheet การตั้งค่าต่างๆ
│   │   ├── 📁 services
│   │   │   ├── 📄 health_record_api_service.dart          # ยิง API บันทึกประวัติสุขภาพ
│   │   │   └── 📄 profile_api_service.dart                # ยิง API อัปเดตข้อมูลโปรไฟล์ผู้ใช้
│   │   ├── 📁 widgets
│   │   │   ├── 📁 bottom_sheets                           # BottomSheet การตั้งค่าต่างๆ
│   │   │   │   ├── 📄 connected_devices_bottom_sheet.dart # จัดการอุปกรณ์และเซ็นเซอร์ที่เชื่อมต่อ
│   │   │   │   ├── 📄 personal_info_bottom_sheet.dart     # ดูข้อมูลส่วนตัว (น้ำหนัก, ส่วนสูง, วันเกิด)
│   │   │   │   └── 📄 unit_picker_bottom_sheet.dart       # เลือกหน่วยวัดน้ำหนักและระยะทาง
│   │   │   ├── 📁 cards                                   # การ์ดข้อมูลโปรไฟล์
│   │   │   │   ├── 📄 account_card.dart                   # การ์ดจัดการข้อมูลบัญชีผู้ใช้
│   │   │   │   ├── 📄 profile_header_card.dart            # การ์ดส่วนหัวแสดงรูปโปรไฟล์ ชื่อ และอีเมล
│   │   │   │   ├── 📄 profile_header_card_goal.dart       # แถบแสดงเป้าหมายหลักในโปรไฟล์
│   │   │   │   ├── 📄 profile_header_card_sections.dart   # สถิติสรุปภาพรวมในส่วนหัวโปรไฟล์
│   │   │   │   ├── 📄 quick_stats_card.dart               # การ์ดสถิติด่วน (กิจวัตรสำเร็จ, แคลอรีสะสม)
│   │   │   │   ├── 📄 settings_card.dart                  # การ์ดการตั้งค่าแอปและการแจ้งเตือน
│   │   │   │   └── 📄 settings_card_action_row.dart       # แถวเมนูย่อยในการตั้งค่า
│   │   │   ├── 📁 common                                  # วิดเจ็ตทั่วไป
│   │   │   │   ├── 📄 profile_footer.dart                 # ส่วนท้ายหน้าโปรไฟล์ (ปุ่มออกจากระบบ, เวอร์ชันแอป)
│   │   │   │   └── 📄 profile_top_bar.dart                # แถบ App Bar ด้านบนหน้าโปรไฟล์
│   │   │   ├── 📁 dialogs                                 # Dialogs แก้ไขโปรไฟล์
│   │   │   │   ├── 📄 edit_profile_dialog.dart            # Dialog แก้ไขข้อมูลส่วนตัว
│   │   │   │   ├── 📄 edit_profile_dialog_content.dart    # เลย์เอาต์ฟอร์มแก้ไขโปรไฟล์
│   │   │   │   ├── 📄 edit_profile_dialog_fields.dart     # ช่องกรอกชื่อ นามสกุล วันเกิด
│   │   │   │   ├── 📄 edit_profile_dialog_gender.dart     # ปุ่มเลือกเพศใน Dialog
│   │   │   │   ├── 📄 edit_profile_dialog_header.dart     # ส่วนหัวของ Dialog แก้ไขโปรไฟล์
│   │   │   │   ├── 📄 edit_profile_dialog_labels.dart     # ข้อความกำกับฟิลด์ข้อมูล
│   │   │   │   ├── 📄 edit_profile_dialog_save.dart       # ฟังก์ชันบันทึกการแก้ไขโปรไฟล์
│   │   │   │   └── 📄 logout_confirm_dialog.dart          # Dialog ยืนยันการออกจากระบบ
│   │   │   └── 📄 index.dart
│   │   └── 📄 index.dart
│   ├── 📁 workout                             # ระบบติดตามการออกกำลังกายและบันทึกเส้นทาง GPS
│   │   ├── 📁 controllers
│   │   │   ├── 📄 workout_history_controller.dart         # จัดการ State และโหลดประวัติการออกกำลังกาย
│   │   │   ├── 📄 workout_tracking_controller.dart        # Controller หลักขณะกำลังออกกำลังกาย
│   │   │   ├── 📄 workout_tracking_controller_lifecycle.dart # วงจรการทำงานของ Session ออกกำลังกาย
│   │   │   ├── 📄 workout_tracking_controller_location.dart # สตรีมและรับค่าพิกัด GPS
│   │   │   ├── 📄 workout_tracking_controller_persistence.dart # บันทึกผลการออกกำลังกายลงเครื่องและ Cloud
│   │   │   ├── 📄 workout_tracking_controller_selection.dart # จัดการการเลือกหมวดหมู่กิจกรรม
│   │   │   └── 📄 workout_tracking_controller_session.dart # ควบคุมตัวจับเวลา ระยะทาง Pace และแคลอรี
│   │   ├── 📁 models
│   │   │   └── 📄 workout_models.dart                     # โมเดลประเภทกีฬา, สถิติ, และประเภทแผนที่
│   │   ├── 📁 pages
│   │   │   ├── 📄 workout_history_page.dart               # หน้าจอประวัติการออกกำลังกายย้อนหลัง
│   │   │   ├── 📄 workout_share_page.dart                 # หน้าจอสร้างภาพสรุปการออกกำลังกายเพื่อแชร์
│   │   │   ├── 📄 workout_tracking_page.dart              # หน้าจอติดตามการออกกำลังกาย Real-Time
│   │   │   ├── 📄 workout_tracking_page_actions.dart      # Action เริ่ม/หยุด/บันทึก/ละทิ้ง การออกกำลังกาย
│   │   │   ├── 📄 workout_tracking_page_content.dart      # เลย์เอาต์หน้าจอแผนที่และสถิติ
│   │   │   └── 📄 workout_tracking_page_location.dart     # จัดการขอสิทธิ์ GPS และควบคุมกล้องแผนที่
│   │   ├── 📁 services
│   │   │   ├── 📄 activity_api_service.dart               # ยิง API บันทึกและดึงประวัติการออกกำลังกาย
│   │   │   ├── 📄 kalman_location_filter.dart             # ตัวกรอง Kalman Filter กรองสัญญาณ GPS แกว่ง
│   │   │   ├── 📄 map_matching_service.dart               # ปรับพิกัดเส้นทางให้แนบสนิทกับถนนจริง (Map Matching)
│   │   │   └── 📄 workout_recovery_service.dart           # กู้คืนกิจกรรมอัตโนมัติกรณีแอปดับหรือเครื่องดับ
│   │   ├── 📁 widgets
│   │   │   ├── 📁 common                                  # วิดเจ็ตเลือกกีฬาและขอสิทธิ์
│   │   │   │   ├── 📄 category_selection_view.dart        # หน้ารายการเลือกประเภทกีฬา (วิ่ง, ปั่น, โยคะ ฯลฯ)
│   │   │   │   ├── 📄 workout_dialog_utils.dart           # ยูทิลิตี้เรียกเปิด Dialog ต่างๆ
│   │   │   │   └── 📄 workout_gps_permission_dialog.dart  # Dialog แนะนำให้เปิดสิทธิ์ GPS
│   │   │   ├── 📁 history                                 # การ์ดประวัติและเส้นทาง
│   │   │   │   ├── 📄 history_route_painter.dart          # วาดเส้นทางวิ่งลงบนการ์ดประวัติ
│   │   │   │   ├── 📄 mini_route_painter.dart             # วาดมินิแมปเส้นทางแบบ Vector
│   │   │   │   ├── 📄 workout_history_card_sections.dart  # สถิติย่อยในการ์ดประวัติ (เวลา, ความเร็ว, แคลอรี)
│   │   │   │   ├── 📄 workout_history_empty_card.dart     # แสดงเมื่อยังไม่มีประวัติการออกกำลังกาย
│   │   │   │   └── 📄 workout_history_item_card.dart      # การ์ดแสดงผลกิจกรรมการออกกำลังกายแต่ละครั้ง
│   │   │   ├── 📁 map                                     # แผนที่และปุ่มควบคุม
│   │   │   │   ├── 📄 map_floating_buttons.dart           # ปุ่มลอยเปลี่ยนเลเยอร์และดึงตำแหน่งปัจจุบัน
│   │   │   │   ├── 📄 workout_map_type_selector.dart      # เมนูเลือกประเภทแผนที่ (Standard, Satellite, Hybrid)
│   │   │   │   └── 📄 workout_map_view.dart               # Google Maps สำหรับแสดงตำแหน่งและเส้นทาง Real-Time
│   │   │   ├── 📁 share                                   # การ์ดแชร์ผลลัพธ์
│   │   │   │   ├── 📄 workout_share_actions.dart          # Action บันทึกภาพลงเครื่องหรือแชร์ไปยังแอปอื่น
│   │   │   │   └── 📄 workout_share_card.dart             # การ์ดดีไซน์พรีเมียมพร้อมสถิติและเส้นทางสำหรับแชร์
│   │   │   ├── 📁 tracking                                # ตัวควบคุมขณะออกกำลังกาย
│   │   │   │   ├── 📄 workout_bottom_controls.dart        # แผงปุ่มควบคุมด้านล่าง (เริ่ม, พัก, หยุด)
│   │   │   │   ├── 📄 workout_bottom_controls_action.dart # ปุ่มวงกลมควบคุมกิจกรรม
│   │   │   │   ├── 📄 workout_stop_action_sheet.dart      # ป๊อบอัพเมื่อกดหยุด ให้เลือก บันทึก/ละทิ้ง/เล่นต่อ
│   │   │   │   ├── 📄 workout_top_stats_card.dart         # แผงสถิติด้านบน (เวลา, ระยะทาง, แคลอรี, Pace)
│   │   │   │   ├── 📄 workout_top_stats_card_header.dart  # ส่วนหัวแผงสถิติแสดงชื่อประเภทกิจกรรม
│   │   │   │   └── 📄 zen_focus_background.dart           # พื้นหลังแอนิเมชันหายใจสำหรับโยคะ/สมาธิ (Zen Mode)
│   │   │   └── 📄 index.dart
│   │   └── 📄 index.dart
│   └── 📄 index.dart
├── 📁 shared                                  # คอมโพเนนต์ ธีม และวิดเจ็ตที่ใช้ร่วมกันทั้งแอป
│   ├── 📁 bottom_sheets
│   │   ├── 📄 food_source_bottom_sheet.dart       # ป๊อบอัพเลือกวิธีสแกนอาหาร (ถ่ายรูป / เลือกจากอัลบั้ม)
│   │   └── 📄 food_source_bottom_sheet_option.dart # ตัวเลือกใน BottomSheet ถ่ายภาพอาหาร
│   ├── 📁 theme
│   │   ├── 📄 app_theme.dart                      # ชุดสี (Color Palette) และ Typography กลางของแอป
│   │   ├── 📄 index.dart
│   │   └── 📄 theme_service.dart                  # เซอร์วิสควบคุมธีมสว่าง/มืด
│   ├── 📁 widgets
│   │   ├── 📄 fade_slide_entrance.dart            # วิดเจ็ตแอนิเมชันเลื่อนปรากฏอย่างนุ่มนวล (Fade & Slide In)
│   │   ├── 📄 sync_status_badge.dart              # ไอคอนแสดงสถานะการซิงค์ข้อมูล Cloud (กำลังซิงค์ / สำเร็จ)
│   │   ├── 📄 vitality_bottom_nav_bar.dart        # แถบเมนูด้านล่างสุดของแอป (Bottom Navigation Bar 5 แท็บ)
│   │   └── 📄 vitality_bottom_nav_bar_item.dart   # ปุ่มไอคอนแต่ละแท็บบน Bottom Navigation Bar
│   └── 📄 index.dart
├── 📄 main.dart                               # จุดเริ่มต้นของแอปพลิเคชัน (Entry Point & Initialization)
└── 📄 main_app.dart                           # วิดเจ็ตรากฐาน (Root App Widget, Theme Provider, Router)
```