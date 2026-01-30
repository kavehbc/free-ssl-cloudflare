# Free Let's Encrypt Wildcard SSL with Cloudflare

## Overview
This project provides an automated solution to obtain and renew free Let's Encrypt wildcard SSL certificates using Cloudflare DNS for domain validation. It is designed to simplify SSL management for domains managed via Cloudflare, making it easy to secure your websites and services with trusted HTTPS certificates.

The container automatically handles the DNS-01 challenge required for wildcard certificates and sets up a cron job for automated renewals.

## Features
- **Automated Issuance & Renewal**: Obtains and renews Let's Encrypt wildcard SSL certificates automatically.
- **Wildcard Support**: Automatically requests certificates for both `domain.com` and `*.domain.com`.
- **Cloudflare DNS Integration**: Uses Cloudflare API for seamless DNS-01 challenge validation.
- **Multi-Domain Support**: specific multiple domains (e.g., `example.com,example.net`) in one go.
- **Dockerized**: Easy to deploy and integrates well with other containerized services.
- **Configurable**: extensive environment variables for customization.

## Prerequisites
- A domain name managed by Cloudflare.
- Cloudflare API Token (recommended) with `Zone:DNS:Edit` permissions, OR Global API Key.
- Docker and Docker Compose installed on your system.

## Usage

### Environment Variables

| Variable | Required | Default | Description |
|----------|:--------:|:-------:|-------------|
| `DOMAIN` | **Yes** | - | Comma-separated list of domains (e.g., `example.com`). The script automatically adds `*.example.com` for each. |
| `SSL_EMAIL` | **Yes** | - | Email address used for Let's Encrypt registration and expiration notices. |
| `CLOUDFLARE_API_TOKEN` | *Yes | - | Cloudflare API Token with DNS edit permissions. (Recommended) |
| `CLOUDFLARE_API_KEY` | *Yes | - | Cloudflare Global API Key. (*Req. if Token not used) |
| `CLOUDFLARE_EMAIL` | *Yes | - | Cloudflare account email. (*Req. if Global API Key is used) |
| `CRON_INTERVAL` | No | `0 2 * * *` | Cron schedule for certificate renewal checks (Default: Every day at 2:00 AM). |
| `AUTO_RENEW` | No | `true` | Enable automated renewal via cron. Set to `false` for one-time issuance. |
| `PROPAGATION_SECONDS` | No | `30` | Seconds to wait for DNS propagation before validation. Increase if validation fails. |
| `STAGING` | No | `false` | Set to `true` to use Let's Encrypt Staging environment (for testing to avoid rate limits). |

**Note:** You must provide either `CLOUDFLARE_API_TOKEN` OR (`CLOUDFLARE_API_KEY` + `CLOUDFLARE_EMAIL`).

### Running with Docker Compose (Recommended)

1.  **Clone the repository:**
    ```bash
    git clone https://github.com/kavehbc/free-ssl-cloudflare.git
    cd free-ssl-cloudflare
    ```

2.  **Edit `docker-compose.yml` or create a `.env` file:**
    Update the environment variables with your details.

    ```yaml
    services:
      wildcard-ssl:
        image: kavehbc/free-ssl-cloudflare
        container_name: wildcard-ssl
        environment:
          - CRON_INTERVAL=0 2 * * *
          - DOMAIN=example.com
          - CLOUDFLARE_API_TOKEN=your_cloudflare_api_token
          - SSL_EMAIL=your@email.com
          - AUTO_RENEW=true
        volumes:
          - ./letsencrypt:/etc/letsencrypt
        restart: unless-stopped
    ```

3.  **Start the container:**
    ```bash
    docker compose up -d
    ```

4.  **Access Certificates:**
    Your certificates will be generated in the `./letsencrypt/live/<your-domain>/` directory.
    - `fullchain.pem`: The certificate including the chain.
    - `privkey.pem`: The private key.

### Running with Docker CLI

You can also run the container directly without Docker Compose:

```bash
docker run -d --name wildcard-ssl \
  -e DOMAIN=example.com \
  -e CLOUDFLARE_API_TOKEN=your_token_here \
  -e SSL_EMAIL=your@email.com \
  -e CRON_INTERVAL="0 2 * * *" \
  -v $(pwd)/letsencrypt:/etc/letsencrypt \
  kavehbc/free-ssl-cloudflare
```

## Building the Image Manually (Multi-Platform)

If you need to build the image locally for different architectures (e.g., AMD64, ARM64 for Apple Silicon, or ARMv7 for Raspberry Pi), you can use `docker buildx`.

1.  **Enable Docker Buildx:**
    Ensure Docker Desktop or Docker Engine is installed and supports `buildx`.

2.  **Build and Push (Multi-arch):**
    To build for multiple platforms and push to a registry:
    ```bash
    docker buildx build --platform linux/amd64,linux/arm64,linux/arm/v7 -t youruser/free-ssl-cloudflare:latest --push .
    ```

3.  **Build Locally (Single-arch):**
    To build just for your current architecture and load it into your local Docker daemon:
    ```bash
    docker build -t free-ssl-cloudflare:latest .
    ```

## How It Works

1.  **Startup**: When the container starts, it attempts to issue a certificate for the specified `DOMAIN`.
2.  **DNS Validation**: Certbot uses the Cloudflare plugin to create a TXT record `_acme-challenge.yourdomain.com`.
3.  **Issuance**: Upon verification, Let's Encrypt issues the certificate.
4.  **Auto-Renewal**: If `AUTO_RENEW` is true, a cron job is installed to run a renewal check daily (based on `CRON_INTERVAL`). Certbot only renews certificates that are close to expiration (usually < 30 days).

## License

This project is licensed under the Apache License 2.0 - see the [LICENSE](LICENSE) file for details.

## References
- [Docker Hub](https://hub.docker.com/repository/docker/kavehbc/free-ssl-cloudflare)
- [GitHub Repository](https://github.com/kavehbc/free-ssl-cloudflare)

## Developer(s)
**Kaveh Bakhtiyari** - [Website](http://bakhtiyari.com) | [Medium](https://medium.com/@bakhtiyari) | [LinkedIn](https://www.linkedin.com/in/bakhtiyari) | [GitHub](https://github.com/kavehbc)

## Contribution
Feel free to join the open-source community and contribute to this repository. Pull requests and issues are welcome!