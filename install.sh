#!/usr/bin/env bash
set -e

# === CONFIG ===
PORT=8000
DOC_ROOT="/var/www/html"

echo "🚀 เริ่มติดตั้ง Apache + PHP + Extensions สำหรับ VPS เล็ก..."

# === Update OS ===
sudo apt update -y && sudo apt upgrade -y

# === ติดตั้ง Apache ===
sudo apt install -y apache2
sudo systemctl enable apache2

# === เปลี่ยน Apache Port เป็น 8000 ===
sudo sed -i "s/80/$PORT/g" /etc/apache2/ports.conf
sudo sed -i "s/:80/:$PORT/g" /etc/apache2/sites-available/000-default.conf

# === ติดตั้ง PHP และ Extensions ===
sudo apt install -y php php-cli php-common php-sqlite3 php-curl php-mbstring php-xml php-zip php-gd php-intl libapache2-mod-php

# === ตรวจสอบ PHP เวอร์ชันจริง ===
PHP_VERSION=$(php -r 'echo PHP_MAJOR_VERSION.".".PHP_MINOR_VERSION;')
echo "🔍 ตรวจพบ PHP เวอร์ชัน: $PHP_VERSION"

# === เปิดโมดูล Apache ที่จำเป็น ===
if sudo a2enmod "php${PHP_VERSION}" >/dev/null 2>&1; then
  echo "✅ เปิดโมดูล php${PHP_VERSION} แล้ว"
else
  echo "⚠️ ไม่พบ php${PHP_VERSION} module, ลองเปิด mod-php เอง"
  sudo a2enmod php || true
fi
sudo a2enmod rewrite
sudo systemctl restart apache2

# === ปรับ php.ini ===
PHP_INI=$(php -i | grep "Loaded Configuration File" | awk '{print $5}')
echo "🔧 แก้ค่า php.ini: $PHP_INI"

# แก้ค่า memory, upload, post, execution time
sudo sed -i 's/^\s*memory_limit\s*=.*/memory_limit = 256M/' $PHP_INI
sudo sed -i 's/^\s*upload_max_filesize\s*=.*/upload_max_filesize = 32M/' $PHP_INI
sudo sed -i 's/^\s*post_max_size\s*=.*/post_max_size = 32M/' $PHP_INI
sudo sed -i 's/^\s*max_execution_time\s*=.*/max_execution_time = 60/' $PHP_INI

PHP_APACHE_INI=$(find /etc/php/ -type f -path "*/apache2/php.ini" | head -n1)
echo "🔧 แก้ค่า Apache php.ini: $PHP_APACHE_INI"

sudo sed -i 's/^\s*memory_limit\s*=.*/memory_limit = 256M/' $PHP_APACHE_INI
sudo sed -i 's/^\s*upload_max_filesize\s*=.*/upload_max_filesize = 32M/' $PHP_APACHE_INI
sudo sed -i 's/^\s*post_max_size\s*=.*/post_max_size = 32M/' $PHP_APACHE_INI
sudo sed -i 's/^\s*max_execution_time\s*=.*/max_execution_time = 60/' $PHP_APACHE_INI



# === เปิด AllowOverride เพื่อใช้ .htaccess ได้ ===
sudo sed -i '/<Directory \/var\/www\/>/,/<\/Directory>/ s/AllowOverride None/AllowOverride All/' /etc/apache2/apache2.conf

# === สร้าง index.php ทดสอบ ===
sudo bash -c "cat > $DOC_ROOT/index.php" <<'EOL'
<?php
phpinfo();
?>
EOL

# === Restart Apache ===
sudo systemctl restart apache2

# === แสดงผลสำเร็จ ===
IP=$(hostname -I | awk '{print $1}')
echo "✅ ติดตั้งเสร็จแล้ว"
echo "🌐 เปิดเว็บ: http://$IP:$PORT"
echo "📂 Document Root: $DOC_ROOT"
echo "🧰 PHP Extensions:"
php -m | grep -E 'curl|sqlite3|mbstring|zip|xml|gd|intl'



