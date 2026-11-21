# docker-nginx-oracle-php-fpm

![GitHub workflow](https://github.com/thesuhu/docker-nginx-oracle-php-fpm/actions/workflows/docker-image.yml/badge.svg) ![Docker pull](https://img.shields.io/docker/pulls/thesuhu/docker-nginx-oracle-php-fpm)

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
| **8.2.35** | **1.30.7 stable** | Debian Bookworm | `8.2.35`, `8.2`, `latest` |
| 7.3.33 (legacy, unsupported PHP) | **1.30.7 stable** | Debian Buster | `7.3.33`, `7.3` |

The release workflow builds and smoke-tests each PHP variant independently, then publishes its version tags. **`latest` follows PHP 8.2 only.** The PHP 7.3 job publishes only `7.3.33` and `7.3`.

The PHP 8.2 Dockerfile installs NGINX from the official stable repository, pinned to Debian package `1.30.7-1~bookworm` via the `NGINX_VERSION` build argument.

Historical releases (previous contents of these tags):

- PHP 7.3 and NGINX 1.23
- PHP 7.4 and NGINX 1.23
- PHP 8.1 and NGINX 1.23
- PHP 8.2 and NGINX 1.27
- PHP 8.2.27 and NGINX 1.27

If you need another version, you can fork and edit the `Dockerfile` and then build for your own.

## NGINX stable version and compatibility

As of 21 November 2026, the latest stable NGINX release is **1.30.7**. This update incorporates the security fixes listed in the [stable changelog](https://nginx.org/en/CHANGES-1.30). See the [official downloads](https://nginx.org/en/download.html). The Dockerfile uses the stable Debian repository at `https://nginx.org/packages/debian/`.

A review of the bundled NGINX 1.27 configuration against the changelog found no required directive changes for 1.30.7: FastCGI, caching, gzip, real IP handling, and the Laravel HTTPS map remain supported. NGINX 1.29.7 changed HTTP proxy defaults to HTTP/1.1 with keepalive; the bundled PHP upstream uses `fastcgi_pass`. NGINX 1.29.4 also changed Host validation and rejects bare LF line endings in chunked bodies, so clients sending malformed requests can observe different behavior.

The Dockerfile runs `nginx -t` and `php-fpm -t` after copying the configuration, so configuration errors fail the build. Application routing, authenticated responses, and cache behavior still need runtime verification. Check the installed version and configuration before deployment:

```sh
docker run --rm --platform linux/amd64 --entrypoint nginx thesuhu/docker-nginx-oracle-php-fpm:8.2.35 -v
docker run --rm --platform linux/amd64 --entrypoint nginx thesuhu/docker-nginx-oracle-php-fpm:8.2.35 -t
```

Before publishing each variant, CI starts a temporary container, validates NGINX and PHP-FPM configuration, checks that OCI8 is loaded, and checks that `nginx -v` reports exactly 1.30.7. It creates a small PHP probe inside that container and requests it through NGINX to verify that PHP-FPM serves the selected PHP version over HTTP. A failed check prevents that variant from being published. The probe is removed with the temporary container and is not included in the published image.

## Legacy PHP 7.3: NGINX update only

`Dockerfile.php73` updates NGINX to 1.30.7 while retaining PHP 7.3.33, its extensions, Oracle Instant Client, Supervisor, and configuration from the original `7.3` image. That original image is pinned by digest to prevent later builds from using the updated tag as their own base.

NGINX does not publish 1.30.7 packages for Debian Buster. The legacy Dockerfile builds NGINX from the [official source](https://nginx.org/en/docs/configure.html), verifies a pinned SHA-256 checksum, and uses the archived Debian repositories for build dependencies. It replaces the NGINX executable while keeping the legacy configuration; use `nginx -v` to check the version because the original Debian package metadata is retained.

```sh
docker build --pull --platform linux/amd64 -f Dockerfile.php73 -t thesuhu/docker-nginx-oracle-php-fpm:7.3 .
docker run --rm --platform linux/amd64 --entrypoint nginx thesuhu/docker-nginx-oracle-php-fpm:7.3 -v
docker run --rm --platform linux/amd64 --entrypoint php-fpm thesuhu/docker-nginx-oracle-php-fpm:7.3 -v
```

**This updates NGINX only. PHP 7.3 and Debian Buster remain unsupported, and this image does not include a PHP2Shell fix for PHP 7.3.** Migrate applications to the patched PHP 8.2 image or obtain maintained PHP and OS backports from a vendor. Recreate running `7.3` containers after pulling the rebuilt image to apply the NGINX update.

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
docker exec myweb nginx -v
```

The reported version should be PHP 8.2.35.
