#!/bin/bash

# Function to parse YAML file
parse_yaml() {
    local prefix=$2
    local s='[[:space:]]*' w='[a-zA-Z0-9_]*' fs=$(echo @|tr @ '\034')
    sed -ne "s|^\($s\)\($w\)$s:$s\"\(.*\)\"$s\$|\1$fs\2$fs\3|p" \
        -e "s|^\($s\)\($w\)$s:$s\(.*\)$s\$|\1$fs\2$fs\3|p" $1 | \
    awk -F$fs '{
        indent = length($1)/2;
        vname[indent] = $2;
        for (i in vname) {if (i > indent) {delete vname[i]}}
        if (length($3) > 0) {
            vn=""; for (i=0; i<indent; i++) {vn=(vn)(vname[i])("_")}
            printf("%s%s%s=\"%s\"\n", "'$prefix'",vn, $2, $3);
        }
    }'
}

# Load YAML configuration
load_config() {
    local config_file=$1
    if [ -f "$config_file" ]; then
        # Parse YAML and export variables
        eval $(parse_yaml "$config_file" "CONFIG_")
        
        # Map YAML variables to script variables
        PORT="${CONFIG_network_port:-3000}"
        TRAEFIK_PORT="${CONFIG_network_traefik_port:-80}"
        TRAEFIK_SSL_PORT="${CONFIG_network_traefik_ssl_port:-443}"
        ADVERTISE_ADDR="${CONFIG_network_advertise_addr:-}"
        RELEASE_TAG="${CONFIG_release_tag:-latest}"
        DATABASE_URL="${CONFIG_database_url:-}"
        REDIS_HOST="${CONFIG_redis_host:-}"
        ACME_EMAIL="${CONFIG_acme_email:-}"
        
        # Export variables
        export PORT TRAEFIK_PORT TRAEFIK_SSL_PORT ADVERTISE_ADDR RELEASE_TAG DATABASE_URL REDIS_HOST ACME_EMAIL
    else
        echo "Configuration file not found: $config_file"
        exit 1
    fi
} 