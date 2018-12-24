#!/bin/bash
nginx_path=${PWD}
echo "This script will install NGINX v1.9 and RTMP Module v1.7 in "
echo $nginx_path

echo "Installing OpenSSL and PCRE first"
apt-get install -y libssl-dev libpcre3-dev libpcre++-dev 

echo "Installing nginx with modules"
./configure --prefix=$nginx_path/build                          \
            --with-cc-opt="-Wno-error"                          \
            --error-log-path=logs/error.log                     \
            --http-log-path=logs/access.log                     \
            --with-http_ssl_module                              \
            --add-module=$nginx_path/nginx-rtmp-module-1.1.7    
make
make install
