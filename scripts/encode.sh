#!/bin/bash

if [ -f .env ]; then
    while IFS='=' read -r key value; do
        if [[ $key != \#* ]] && [[ ! -z "$key" ]]; then
            echo "SECRET_$key=$(echo -n "$value" | base64)";
        fi
    done < .env > .env_encoded
else
    echo "Error: .env file not found."
fi
