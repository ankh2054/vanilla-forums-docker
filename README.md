
![License MIT](https://img.shields.io/badge/license-MIT-blue.svg)

### TO-DO

update settings.py with following:

	STATIC_URL = '/static/'
	STATIC_ROOT = os.path.join(BASE_DIR, 'static')


# DJANGO-DOCKER

django-docker sets up a container running django, gunicorn python, based on variables provided. It will automatically start gunicorn using the WSGI variable provided. 

If using Letsencrypt to automate the creation of a SSL certificate, you need to follow the Nginx-proxy Usage - to enable SSL support guidelines at the bottom of this page.


### Vanilla-DOCKER Usage


Firstly you need to create the necessary folders on your docker host. The container will expose directories created below directly into the container to ensure our WWW, and LOG folders are persistent.
This ensures that even if your container is lost or deleted, you won't loose your Vanilla database or website files.

	$ mkdir -p /data/sites/www.test.co.uk/www
	$ mkdir -p /data/sites/www.test.co.uk/logs



### To buld the docker django image:

		$ docker build https://github.com/ankh2054/vanila-forums-docker.git -t vanilla-nginx

### To run it with LETENCRYPT:

    $ docker run  --name vanilla.docker --expose 80 \
	 -d -e "VIRTUAL_HOST=www.test.co.uk" \
 	 -e "LETSENCRYPT_HOST=www.test.co.uk" \
	 -e "LETSENCRYPT_EMAIL=info@test.co.uk" \
	 -e 'DB_NAME=vanilla' \
	 -e 'DB_USER=vanilla' \
	 -e 'DB_PASS=vanilla' \
	 -e 'ROOT_PWD=test' \
	 -v /data/sites/www.test.co.uk/mysql:/var/lib/mysql \
	 -v /data/sites/www.test.co.uk:/DATA vanilla-nginx


This will create a new Vanilla Forum with the following values:

	$ Virtual Host: - www.test.co.uk
	$ Mysql DB: vanilla
	$ Mysql user to access vanilla DB: vanilla
	$ Mysql password for user: vanilla
	$ Mysql root password: test
	$ SSL certificate created for the hostname www.test.co.uk with email address info@test.co.uk.
	
	Note that your container can still be listening on port 80, since all external connections will hit your NGINX proxy 	     first, whcih will force users onto HTTPS. 
	


# NGINX-PROXY


nginx-proxy sets up a container running nginx and [docker-gen][1].  docker-gen generates reverse proxy configs for nginx and reloads nginx when containers are started and stopped.

See [Automated Nginx Reverse Proxy for Docker][2] for why you might want to use this.

### Nginx-proxy Usage - to enable SSL support

To use it with original [nginx-proxy](https://github.com/jwilder/nginx-proxy) container you must declare 3 writable volumes from the [nginx-proxy](https://github.com/jwilder/nginx-proxy) container:
* `/etc/nginx/certs` to create/renew Let's Encrypt certificates
* `/etc/nginx/vhost.d` to change the configuration of vhosts (needed by Let's Encrypt)
* `/usr/share/nginx/html` to write challenge files.

Example of use:

* First start nginx with the 3 volumes declared:
```bash
$ docker run -d -p 80:80 -p 443:443 \
    --name nginx-proxy \
    -v /path/to/certs:/etc/nginx/certs:ro \
    -v /etc/nginx/vhost.d \
    -v /usr/share/nginx/html \
    -v /var/run/docker.sock:/tmp/docker.sock:ro \
    --label com.github.jrcs.letsencrypt_nginx_proxy_companion.nginx_proxy \
    jwilder/nginx-proxy
```
The "com.github.jrcs.letsencrypt_nginx_proxy_companion.nginx_proxy" label is needed so that the letsencrypt container knows which nginx proxy container to use.

* Second start this container:
```bash
$ docker run -d \
    -v /path/to/certs:/etc/nginx/certs:rw \
    -v /var/run/docker.sock:/var/run/docker.sock:ro \
    --volumes-from nginx-proxy \
    jrcs/letsencrypt-nginx-proxy-companion
```

Then start any containers you want proxied with a env var `VIRTUAL_HOST=subdomain.youdomain.com`

    $ docker run -e "VIRTUAL_HOST=foo.bar.com" ..




[1]: https://github.com/etopian/docker-gen
[2]: http://jasonwilder.com/blog/2014/03/25/automated-nginx-reverse-proxy-for-docker/

