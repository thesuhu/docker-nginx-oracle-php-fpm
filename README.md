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

```sh
FROM thesuhu/docker-nginx-oracle-php-fpm

COPY myweb /var/www/html
```

## Release

Current build:

| PHP | NGINX | Base OS | Image tags |
| --- | --- | --- | --- |
| **8.2.35** | **1.30.6 stable** | Debian Bookworm | `8.2.35`, `8.2`, `latest` |

The release workflow builds and publishes these tags. NGINX is installed from the official stable repository, pinned to Debian package `1.30.6-1~bookworm` via the `NGINX_VERSION` build argument.

Historical releases (the versions below describe older images):

- PHP 7.3 and NGINX 1.23
- PHP 7.4 and NGINX 1.23
- PHP 8.1 and NGINX 1.23
- PHP 8.2 and NGINX 1.27
- PHP 8.2.27 and NGINX 1.27

If you need another version, you can fork and edit the `Dockerfile` and then build for your own.

## NGINX stable version and compatibility

As of 28 October 2026, the latest stable NGINX release is **1.30.6**. See the [official downloads](https://nginx.org/en/download.html) and [stable changelog](https://nginx.org/en/CHANGES-1.30). The Dockerfile uses the stable Debian repository at `https://nginx.org/packages/debian/`.

A review of the bundled NGINX 1.27 configuration against the changelog found no required directive changes for 1.30.6: FastCGI, caching, gzip, real IP handling, and the Laravel HTTPS map remain supported. NGINX 1.29.7 changed HTTP proxy defaults to HTTP/1.1 with keepalive; the bundled PHP upstream uses `fastcgi_pass`. NGINX 1.29.4 also changed Host validation and rejects bare LF line endings in chunked bodies, so clients sending malformed requests can observe different behavior.

The Dockerfile runs `nginx -t` and `php-fpm -t` after copying the configuration, so configuration errors fail the build. Application routing, authenticated responses, and cache behavior still need runtime verification. Check the installed version and configuration before deployment:

```sh
docker run --rm --platform linux/amd64 --entrypoint nginx thesuhu/docker-nginx-oracle-php-fpm:8.2.35 -v
docker run --rm --platform linux/amd64 --entrypoint nginx thesuhu/docker-nginx-oracle-php-fpm:8.2.35 -t
```

## PHP2Shell security update

PHP 8.2.35 includes fixes for PHP2Shell (CVE-2026-109618 and CVE-2026-109619). See the [PHP release announcement](https://www.php.net/releases/8_2_35.php), [PHP changelog](https://www.php.net/ChangeLog-8.php#8.2.35), and [Docker security advisory](https://www.docker.com/blog/security-update-on-php2shell-impact-for-docker-customers/).

Rebuild the image using the patched base image. Use `linux/amd64` because the bundled Oracle Instant Client is an x86-64 binary:

```sh
docker build --pull --no-cache --platform linux/amd64 -t thesuhu/docker-nginx-oracle-php-fpm:8.2.35 .
docker run --rm --platform linux/amd64 --entrypoint php thesuhu/docker-nginx-oracle-php-fpm:8.2.35 -v
```

Recreate deployed containers using the rebuilt image; restarting a container using the old image does not apply the patch. Verify the running container's PHP version:

```sh
docker exec myweb php -v
```

The reported version should be PHP 8.2.35.
