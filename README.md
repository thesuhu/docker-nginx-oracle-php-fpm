# docker-nginx-oracle-php-fpm
Docker image to run PHP and Nginx with Oracle client

## Usage

Pull the latest image from Docker hub.

```sh
docker pull thesuhu/docker-nginx-oracle-php-fpm:<version>
```

If you want to serve your web directly from host, just mount your web directory into container. Example:

```sh
docker run -itd -p 8080:80  --name myweb -v ~/myweb:/var/www/html thesuhu/docker-nginx-oracle-php-fpm:<version>
```

If you have permission issue with your web directory, try to change the permission to `777` before running container.

```sh
chmod 777 -R myweb
```

Or you can build new image with your web files. Just create `Dockerfile` file and then build new image.

```
FROM thesuhu/docker-nginx-oracle-php-fpm

COPY myweb /var/www/html
```

## Release

The latest Docker image use PHP version 8.2 and NGINX version 1.23. You can pull other version. The following version are available:

- PHP 7.3 and NGINX 1.23
- PHP 7.4 and NGINX 1.23
- PHP 8.2 and NGINX 1.23 (latest)

If you need another version, you can fork and edit the `Dockerfile` and then build for your own.
