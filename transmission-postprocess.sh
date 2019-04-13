#!/bin/sh -xu

# Input Parameters
ARG_PATH="$TR_TORRENT_DIR/$TR_TORRENT_NAME"
ARG_NAME="$TR_TORRENT_NAME"
ARG_LABEL="N/A"

# Configuration
CONFIG_OUTPUT="/media"

curl http://filebot:7676/amc?name=${ARG_NAME}&path=${ARG_PATH}&label=${ARG_LABEL}
