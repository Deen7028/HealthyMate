-- HealthyMate MySQL Database Schema Migration Script
-- รันไฟล์นี้ครั้งเดียวใน phpMyAdmin หรือ MySQL Client สำหรับการ Setup / Upgrade ฐานข้อมูล

-- 1. เพิ่มคอลัมน์ sIpAddress ในตาราง TbEmailOtps สำหรับระบบ IP Rate Limiting
ALTER TABLE TbEmailOtps ADD COLUMN IF NOT EXISTS sIpAddress VARCHAR(45) DEFAULT NULL;

-- 2. เพิ่มคอลัมน์ nProgressValue ในตาราง TbRoutineLogs สำหรับบันทึกความคืบหน้าย่อยของกิจวัตร
ALTER TABLE TbRoutineLogs ADD COLUMN IF NOT EXISTS nProgressValue INT DEFAULT 0;

-- 3. เพิ่ม UNIQUE Constraint ป้องกันข้อมูลซ้ำซ้อนใน TbRoutineLogs
-- (หาก DB ไม่รองรับ IF NOT EXISTS ให้รันคำสั่ง ALTER TABLE โดยตรง)
ALTER TABLE TbRoutineLogs ADD CONSTRAINT uk_routine_date UNIQUE (nRoutineId, dtLogDate);
