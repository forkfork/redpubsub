FROM openresty/openresty:alpine

ADD *.lua /app/
ADD conf/nginx.conf /usr/local/openresty/nginx/conf/
