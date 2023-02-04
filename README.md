# docker-nginx-oracle-php-fpm
Docker image to run PHP and Nginx with Oracle client

## Usage

Pull the latest image from Docker hub.

```sh
docker pull thesuhu/docker-nginx-oracle-php-fpm
```

If you want to serve your web directly from host, just mount your web directory into container. Example:

```sh
docker run -itd -p 8080:80  --name myweb -v ~/myweb:/var/www/html thesuhu/docker-nginx-oracle-php-fpm
```

Or you can build new image with your web files. Just create `Dockerfile` file and then build new image.

```
FROM thesuhu/docker-nginx-oracle-php-fpm

COPY myweb /var/www/html
```

## Release

The latest Docker image use PHP version 7.3 and NGINX version 1.23. If you need another version, you can fork and edit the `Dockerfile` and then build for your own.