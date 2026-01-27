# Free Let's Encrypt Wildcard SSL with Cloudflare

## Overview
This project provides an automated solution to obtain and renew free Let's Encrypt wildcard SSL certificates using Cloudflare DNS for domain validation. It is designed to simplify SSL management for domains managed via Cloudflare, making it easy to secure your websites and services with trusted HTTPS certificates.

## Features
- Automated issuance and renewal of Let's Encrypt wildcard SSL certificates
- Uses Cloudflare DNS API for DNS-01 challenge validation
- Dockerized for easy deployment and portability
- Supports multiple domains and subdomains
- Minimal configuration required

## Usage

### Docker Environment Variables

| Variable                | Required | Description                                                                 |
|-------------------------|----------|-----------------------------------------------------------------------------|
| `CLOUDFLARE_API_TOKEN`  | No       | Cloudflare API token with DNS edit permissions                               |
| `CLOUDFLARE_API_KEY`    | No       | Cloudflare Global API (Optional)                                            |
| `CLOUDFLARE_EMAIL`      | No       | Cloudflare Email if Global API is used (Optional)                           |
| `DOMAIN`                | Yes      | The domain or comma-separated domains to issue certificates for              |
| `SSL_EMAIL`             | Yes      | Email address for Let's Encrypt registration and renewal notifications       |
| `CRON_INTERVAL`         | No       | Cron expression for renewal schedule (default: `* 2 * * *` Every day at 2 AM)|
| `AUTO_RENEW`          | No       | Enable automatic renewal via cron (`true` to enable, `false` to disable, default: `true`) |
| `STAGING`               | No       | Set to `true` to use Let's Encrypt Staging environment (avoid rate limits during test) |
| `PROPAGATION_SECONDS`   | No       | Time in seconds to wait for DNS propagation before validation (default: 30) |

**Notes:**
- `CLOUDFLARE_API_TOKEN` must have permissions to manage DNS records for the specified domain(s).
- `CLOUDFLARE_API_KEY` is required if Cloudflare Global Key is set.
- `CLOUDFLARE_EMAIL` is required if `CLOUDFLARE_API_KEY` is set.
- `DOMAIN` supports wildcard domains (e.g., `*.example.com`).
- `CRON_INTERVAL` controls how often the renewal process runs.

### Prerequisites
- A domain managed by Cloudflare
- Cloudflare API token with DNS edit permissions
- Docker installed on your system

### Quick Start

1. **Clone the repository:**
   ```bash
   git clone https://github.com/kavehbc/free-ssl-cloudflare
   cd free-ssl-cloudflare
   ```

2. **Configure environment variables:**
   Create a `.env` file or set the docker variables

3. **Run with Docker:**
   ```bash
   docker run -d --name wildcard-ssl \
      --env CRON_INTERVAL="* 2 * * *" \
      --env DOMAIN=example.com \
      --env CLOUDFLARE_API_TOKEN=your_cloudflare_api_token \
      --env SSL_EMAIL=your@email.com \
      --env AUTO_RENEW=true \
      -v ./letsencrypt:/etc/letsencrypt \
      kavehbc/free-ssl-cloudflare
   ```

or

   ```bash
   docker compose --env-file ./docker.env up
   ```

4. **Access your certificates:**
   Certificates will be available in the `letsencrypt/live/<domain>` directory.

## References
- [Docker Hub](https://hub.docker.com/repository/docker/kavehbc/free-ssl-cloudflare)
- [GitHub Repository](https://github.com/kavehbc/free-ssl-cloudflare)

## Developer(s)
Kaveh Bakhtiyari - [Website](http://bakhtiyari.com) | [Medium](https://medium.com/@bakhtiyari)
  | [LinkedIn](https://www.linkedin.com/in/bakhtiyari) | [Github](https://github.com/kavehbc)

## Contribution
Feel free to join the open-source community and contribute to this repository.