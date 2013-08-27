Installation process
====================

Nginx & PHP5-FPM
----------------

```unix
sudo apt-get install nginx
sudo /etc/init.d/nginx start
```

Test if working: http://127.0.0.1

```unix
sudo apt-get install php5-fpm
sudo /etc/init.d/php5-fpm reload
vi /usr/share/nginx/www/info.php
````

Test PHP INFO in this info.php file:
```php
<?php
phpinfo();
?>
````

Test if working: http://127.0.0.1/info.php

```unix 
sudo apt-get install php5-mysql php5-curl php5-gd php5-intl php-pear php5-memcache php5-xmlrpc php-apc
sudo /etc/init.d/php5-fpm reload
```

Apply configurations for *nginx* and *PHP5* from this repository */etc* folder.

More info: http://www.howtoforge.com/installing-nginx-with-php5-and-php-fpm-and-mysql-support-lemp-on-debian-wheezy
