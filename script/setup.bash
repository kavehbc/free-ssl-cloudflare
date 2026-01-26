#!/bin/bash

# Default values for variables from environment
CRON_INTERVAL="${CRON_INTERVAL:-* 2 * * *}" # Default to everyday at 2 AM
CLOUDFLARE_API_TOKEN="${CLOUDFLARE_API_TOKEN:-}"
CLOUDFLARE_API_KEY="${CLOUDFLARE_API_KEY:-}"
CLOUDFLARE_EMAIL="${CLOUDFLARE_EMAIL:-}"
DOMAIN="${DOMAIN:-}"
SSL_EMAIL="${SSL_EMAIL:-}"
AUTO_RENEW="${AUTO_RENEW:-true}" # Default to true for auto-renewal

# Prompt for CRON_INTERVAL if not set
if [[ -z "$CRON_INTERVAL" ]]; then
  read -p "Enter CRON_INTERVAL (default '* 2 * * *'): " CRON_INTERVAL
  CRON_INTERVAL="${CRON_INTERVAL:-* 2 * * *}"
fi

# Check if all required variables are set
if [[ -z "$CRON_INTERVAL" ]]; then
  echo "Error: CRON_INTERVAL environment variable is not set."
  exit 1
fi

echo "Using API TOKEN: $CLOUDFLARE_API_TOKEN"

# Prompt for Cloudflare credentials if not set
if [[ -z "$CLOUDFLARE_API_TOKEN" ]] && [[ -z "$CLOUDFLARE_API_KEY" || -z "$CLOUDFLARE_EMAIL" ]]; then
  echo "Cloudflare credentials not set."
  read -p "Enter CLOUDFLARE_API_TOKEN (leave empty if using API key): " CLOUDFLARE_API_TOKEN
  if [[ -z "$CLOUDFLARE_API_TOKEN" ]]; then
    read -p "Enter CLOUDFLARE_API_KEY: " CLOUDFLARE_API_KEY
    read -p "Enter CLOUDFLARE_EMAIL: " CLOUDFLARE_EMAIL
    if [[ -z "$CLOUDFLARE_API_KEY" || -z "$CLOUDFLARE_EMAIL" ]]; then
      echo "Error: You must set either CLOUDFLARE_API_TOKEN or both CLOUDFLARE_API_KEY and CLOUDFLARE_EMAIL."
      exit 1
    fi
  fi
fi

# Prompt for DOMAIN if not set
if [[ -z "$DOMAIN" ]]; then
  read -p "Enter DOMAIN: " DOMAIN
  if [[ -z "$DOMAIN" ]]; then
    echo "Error: DOMAIN environment variable is not set."
    exit 1
  fi
fi

# Prompt for SSL_EMAIL if not set
if [[ -z "$SSL_EMAIL" ]]; then
  read -p "Enter SSL_EMAIL: " SSL_EMAIL
  if [[ -z "$SSL_EMAIL" ]]; then
    echo "Error: SSL_EMAIL environment variable is not set."
    exit 1
  fi
fi

# Create the Cloudflare credentials file
echo "Creating Cloudflare credentials file"

# if api key and email are provided, use them
if [[ -n "$CLOUDFLARE_API_KEY" && -n "$CLOUDFLARE_EMAIL" ]]; then
  echo "dns_cloudflare_email = $CLOUDFLARE_EMAIL" > /etc/letsencrypt/cloudflare.ini
  echo "dns_cloudflare_api_key = $CLOUDFLARE_API_KEY" >> /etc/letsencrypt/cloudflare.ini
else
  # if only api token is provided, use it
  if [[ -n "$CLOUDFLARE_API_TOKEN" ]]; then
    echo "dns_cloudflare_api_token = $CLOUDFLARE_API_TOKEN" > /etc/letsencrypt/cloudflare.ini
  else
    echo "Error: Either CLOUDFLARE_API_KEY and CLOUDFLARE_EMAIL or CLOUDFLARE_API_TOKEN must be provided."
    exit 1
  fi
fi

# Set permissions for the credentials file
chmod 0600 /etc/letsencrypt/cloudflare.ini

# Issuing the certificate
echo "Checking if SSL certificate for $DOMAIN already exists"
if [ -d "/etc/letsencrypt/live/$DOMAIN" ]; then
  echo "Certificate for $DOMAIN already exists. Skipping issuance."
else
  echo "Issuing SSL certificate for $DOMAIN"
  certbot certonly --non-interactive --agree-tos --email "$SSL_EMAIL" \
    --dns-cloudflare --dns-cloudflare-credentials /etc/letsencrypt/cloudflare.ini \
    -d "$DOMAIN" -d "*.$DOMAIN" --quiet

  if [ $? -ne 0 ]; then
    echo "Failed to issue SSL certificate for $DOMAIN"
    exit 1
  else
    echo "SSL certificate issued successfully for $DOMAIN"
  fi
fi


# Create the cron job only if AUTO_RENEW is true
if [[ "$AUTO_RENEW" == "true" ]]; then
  echo "Creating cron job for SSL renewal"
  echo "$CRON_INTERVAL root /app/script/ssl-renew.bash" > /etc/cron.d/ssl-renew

  # Give execution rights on the cron job file
  chmod 0644 /etc/cron.d/ssl-renew

  # Apply the cron job
  crontab /etc/cron.d/ssl-renew

  cron -f
  echo "Cron service started"
else
  echo "AUTO_RENEW is not enabled. Skipping cron job setup."
fi