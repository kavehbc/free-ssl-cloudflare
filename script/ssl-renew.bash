#!/bin/bash

echo "Renewing certificates..."

certbot renew --non-interactive

if [ $? -eq 0 ]; then
    echo "Certificates renewed successfully."
else
    echo "Failed to renew certificates."
    exit 1
fi
