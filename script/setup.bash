#!/bin/bash

# Default values for variables from environment
CRON_INTERVAL="${CRON_INTERVAL:-0 2 * * *}" # Default to everyday at 2 AM
CLOUDFLARE_API_TOKEN="${CLOUDFLARE_API_TOKEN:-}"
CLOUDFLARE_API_KEY="${CLOUDFLARE_API_KEY:-}"
CLOUDFLARE_EMAIL="${CLOUDFLARE_EMAIL:-}"
DOMAIN="${DOMAIN:-}"
SSL_EMAIL="${SSL_EMAIL:-}"
AUTO_RENEW="${AUTO_RENEW:-true}" # Default to true for auto-renewal

# Prompt for CRON_INTERVAL if not set
if [[ -z "$CRON_INTERVAL" ]]; then
  echo "Warning: CRON_INTERVAL not set, defaulting to '0 2 * * *'"
  CRON_INTERVAL="0 2 * * *"
fi

echo "Domain: $DOMAIN"

# Check Cloudflare credentials
if [[ -z "$CLOUDFLARE_API_TOKEN" ]] && [[ -z "$CLOUDFLARE_API_KEY" || -z "$CLOUDFLARE_EMAIL" ]]; then
  echo "Error: You must set either CLOUDFLARE_API_TOKEN or both CLOUDFLARE_API_KEY and CLOUDFLARE_EMAIL."
  exit 1
fi

# Check DOMAIN
if [[ -z "$DOMAIN" ]]; then
  echo "Error: DOMAIN environment variable is not set."
  exit 1
fi

# Check SSL_EMAIL
if [[ -z "$SSL_EMAIL" ]]; then
  echo "Error: SSL_EMAIL environment variable is not set."
  exit 1
fi

# Create the Cloudflare credentials file
echo "Creating Cloudflare credentials file..."

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

# Build domain arguments
DOMAIN_ARGS=""
IFS=',' read -ra DOMAINS <<< "$DOMAIN"
for i in "${DOMAINS[@]}"; do
  # Trim whitespace
  d=$(echo "$i" | xargs)
  DOMAIN_ARGS="$DOMAIN_ARGS -d $d -d *.$d"
done

# Prepare additional arguments
ADDITIONAL_ARGS=""
if [[ "$STAGING" == "true" ]]; then
  echo "Enabling STAGING mode..."
  ADDITIONAL_ARGS="$ADDITIONAL_ARGS --test-cert"
fi

PROPAGATION_SECONDS="${PROPAGATION_SECONDS:-30}"

# Issuing the certificate
# We check the first domain to see if we should skip, assuming all usually go together in this simple script
FIRST_DOMAIN=$(echo "${DOMAINS[0]}" | xargs)

echo "Checking if SSL certificate for $FIRST_DOMAIN and friends already exists"
if [ -d "/etc/letsencrypt/live/$FIRST_DOMAIN" ]; then
  echo "Certificate for $FIRST_DOMAIN already exists. Skipping issuance."
else
  echo "Issuing SSL certificate for: $DOMAIN_ARGS"
  certbot certonly --non-interactive --agree-tos --email "$SSL_EMAIL" \
    --dns-cloudflare --dns-cloudflare-credentials /etc/letsencrypt/cloudflare.ini \
    --dns-cloudflare-propagation-seconds "$PROPAGATION_SECONDS" \
    $ADDITIONAL_ARGS \
    $DOMAIN_ARGS \
    --quiet

  if [ $? -ne 0 ]; then
    echo "Failed to issue SSL certificate for $DOMAIN"
    exit 1
  else
    echo "SSL certificate issued successfully"
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

  echo "Cron service created with interval: $CRON_INTERVAL"
  echo "Starting cron service..."  
  exec cron -f
else
  echo "AUTO_RENEW is not enabled. Certificate issued. Container will sleep to keep alive."
  exec sleep infinity
fi