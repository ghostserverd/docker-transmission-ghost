#!/bin/sh -xu

# Input Parameters
ARG_PATH="$TR_TORRENT_DIR/$TR_TORRENT_NAME"
ARG_NAME="$TR_TORRENT_NAME"
ARG_LABEL="N/A"

# Configuration
CONFIG_OUTPUT="/media"

curl \
    --data-urlencode "name=${ARG_NAME}" \
    --data-urlencode "path=${ARG_PATH}" \
    --data-urlencode "label=${ARG_LABEL}" \
    http://filebot:7676/amc
