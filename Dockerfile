FROM php:8.2-apache

# ติดตั้ง extensions และเครื่องมือที่จำเป็น
RUN apt-get update && apt-get install -y \
    git \
    unzip \
    libzip-dev \
    && docker-php-ext-install pdo pdo_mysql mysqli zip \
    && rm -rf /var/lib/apt/lists/*

# ติดตั้ง Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# เปิดใช้งาน mod_rewrite และ headers สำหรับ Apache
RUN a2enmod rewrite headers

# กำหนด working directory
WORKDIR /var/www/html

# คัดลอกโค้ด
COPY api/ /var/www/html/api/
COPY ca.pem /var/www/html/ca.pem

# ติดตั้ง PHPMailer ในโฟลเดอร์ api/
RUN cd /var/www/html/api && composer require phpmailer/phpmailer

# ตั้งค่าสิทธิ์โฟลเดอร์
RUN chown -R www-data:www-data /var/www/html

EXPOSE 80
CMD ["apache2-foreground"]
