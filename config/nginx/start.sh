#! /usr/bin/env sh

for i in $(seq 1 ${REPLICAS-1}); do
  cat << 'EOF' >/etc/nginx/conf.d/kowloon-$i.conf
server {
    listen 80;
    server_name <domain>;

    return 301 https://$host$request_uri;
}

server {
    listen 443 ssl;
    http2 on;
    server_name <domain>;

    ssl_certificate /etc/nginx/ssl/_wildcard.kowloon.dev.pem;
    ssl_certificate_key /etc/nginx/ssl/_wildcard.kowloon.dev-key.pem;
    ssl_protocols TLSv1.2 TLSv1.3;

    location / {
      proxy_pass http://kowloon-kowloon-<i>:3000;
    }
}
EOF
  sed -i "s|<i>|$i|g" /etc/nginx/conf.d/kowloon-$i.conf
  sed -i "s|<domain>|$i.kowloon.dev|g" /etc/nginx/conf.d/kowloon-$i.conf
done

nginx -g 'daemon off;'
