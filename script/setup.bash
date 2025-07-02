#!/bin/bash

# Default values for variables from environment
CRON_INTERVAL="${CRON_INTERVAL:-* 2 * * *}" # Default to everyday at 2 AM
CLOUDFLARE_API_TOKEN="${CLOUDFLARE_API_TOKEN:-}"
CLOUDFLARE_API_KEY="${CLOUDFLARE_API_KEY:-}"
CLOUDFLARE_EMAIL="${CLOUDFLARE_EMAIL:-}"
DOMAIN_NAME="${DOMAIN_NAME:-}"
SSL_EMAIL="${SSL_EMAIL:-}"

# Parse input arguments (override env if provided)
while getopts "i:z:r:t:d:" opt; do
  case $opt in
    i) CRON_INTERVAL="$OPTARG" ;;
    t) CLOUDFLARE_API_TOKEN="$OPTARG" ;;
    k) CLOUDFLARE_API_KEY="$OPTARG" ;; # Optional, Cloudflare API key
    e) CLOUDFLARE_EMAIL="$OPTARG" ;; # Optional, Cloudflare email
    d) DOMAIN_NAME="$OPTARG" ;;
    m) SSL_EMAIL="$OPTARG" ;;
    *)
      echo "Usage: $0 -i CRON_INTERVAL -t CLOUDFLARE_API_TOKEN -k CLOUDFLARE_API_KEY -e CLOUDFLARE_EMAIL -d DOMAIN_NAME -m SSL_EMAIL"
      ;;
  esac
done

# Check if all required variables are set
if [[ -z "$CRON_INTERVAL" || -z "$CLOUDFLARE_API_TOKEN" || -z "$DOMAIN_NAME" || -z "$SSL_EMAIL" ]]; then
  echo "Error: Missing required arguments."
  echo "Usage: $0 -i CRON_INTERVAL -t CLOUDFLARE_API_TOKEN -e CLOUDFLARE_EMAIL -d DOMAIN_NAME -m SSL_EMAIL"
  exit 1
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
echo "Issuing SSL certificate for $DOMAIN_NAME"
certbot certonly --non-interactive --agree-tos --email "$SSL_EMAIL" \
  --dns-cloudflare --dns-cloudflare-credentials /etc/letsencrypt/cloudflare.ini \
  -d "$DOMAIN_NAME" -d "*.$DOMAIN_NAME" --quiet

if [ $? -ne 0 ]; then
  echo "Failed to issue SSL certificate for $DOMAIN_NAME"
  exit 1
fi  

# Create the cron job
echo "$CRON_INTERVAL root /app/script/ssl-renew.bash" > /etc/cron.d/ssl-renew

# Give execution rights on the cron job file
chmod 0644 /etc/cron.d/ssl-renew

# Apply the cron job
crontab /etc/cron.d/ssl-renew

cron -f