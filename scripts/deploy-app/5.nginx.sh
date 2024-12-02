domain="<domain_name>"
well_known_path="~/.well-known" # must have .well-known in the pathname
conf_filename="microblog.conf"


cat scripts/deploy-app/resources/nginx.conf | sed "s/<domain>/$domain/; s|<.well-known-path>|$well_known_path|" > /etc/nginx/sites-available/$conf_filename

$(cd /etc/nginx/sites-enabled && sudo ln -s /etc/nginx/sites-available/$conf_filename)

sudo nginx -t && sudo service nginx restart


sudo apt-get update
sudo apt-get install -y python-certbot-nginx -t stretch-backports

sudo certbot --nginx # need manuell input

cat scripts/deploy-app/resources/nginx_https.conf | sed "s/<domain>/$domain/; s|<.well-known-path>|$well_known_path|" > /etc/nginx/sites-available/$conf_filename

sudo nginx -t && sudo service nginx restart
