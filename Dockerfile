FROM php:8.2-apache

# ติดตั้ง extensions ที่จำเป็น เช่น pdo, pdo_mysql, mysqli
RUN docker-php-ext-install pdo pdo_mysql mysqli

# เปิดใช้งาน mod_rewrite สำหรับ Apache
RUN a2enmod rewrite headers

# คัดลอกโฟลเดอร์ api ไปไว้ที่ root document ของ Apache
COPY api/ /var/www/html/api/
COPY ca.pem /var/www/html/ca.pem

# ตั้งค่า Apache DocumentRoot และสิทธิ์
RUN chown -R www-data:www-data /var/www/html

EXPOSE 80
CMD ["apache2-foreground"]
