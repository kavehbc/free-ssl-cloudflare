FROM debian:stable-slim

# Set label metadata
LABEL version="1.0"
LABEL maintainer="Kaveh Bakhtiyari"
LABEL description="A Docker image to generate Let's Encrypt SSL certificates and renew them with Certbot using Cloudflare DNS."

# Install dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    curl \
    bash \
    ca-certificates \
    cron \
    openssl \
    certbot \
    python3-certbot-dns-cloudflare && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Create necessary directories
WORKDIR /app

# Copy application files
COPY . .

# Make the script executable
RUN chmod +x /app/script/ssl-renew.bash
RUN chmod +x /app/script/setup.bash

# Start the cron service
ENTRYPOINT [ "/app/script/setup.bash" ]

# CMD [ "sleep", "infinity" ]
