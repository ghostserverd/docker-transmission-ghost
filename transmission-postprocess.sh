#!/bin/sh -xu

# Input Parameters
ARG_PATH="$TR_TORRENT_DIR/$TR_TORRENT_NAME"
ARG_NAME="$TR_TORRENT_NAME"
ARG_LABEL="N/A"

# Configuration
CONFIG_OUTPUT="/media"
FILEBOT_PORT=${FILEBOT_PORT:-7676}

SONARR_CATEGORY=${SONARR_CATEGORY:-"sonarr"}
SONARR_PORT=${SONARR_PORT:-""}
SONARR_API_KEY=${SONARR_API_KEY:-""}

RADARR_CATEGORY=${RADARR_CATEGORY:-"radarr"}
RADARR_PORT=${RADARR_PORT:-""}
RADARR_API_KEY=${RADARR_API_KEY:-""}

FILEBOT_CMD=$(\
echo curl \
    --data-urlencode name=\"${ARG_NAME}\" \
    --data-urlencode path=\"${ARG_PATH}\" \
    --data-urlencode label=\"${ARG_LABEL}\" \
    http://filebot:${FILEBOT_PORT}/amc)

echo $FILEBOT_CMD >> /config/filebot.log
eval $FILEBOT_CMD

REFRESH_NAME=""
REFRESH_URL=""

case $TR_TORRENT_DIR in
    *$SONARR_CATEGORY*)
        if [ $SONARR_PORT != "" ] && [ $SONARR_API_KEY != "" ]; then
            REFRESH_NAME="RescanSeries"
            REFRESH_URL="http://sonarr:${SONARR_PORT}/api/command?apikey=${SONARR_API_KEY}"
	fi
    ;;

    *$RADARR_CATEGORY*)
        if [ $RADARR_PORT != "" ] && [ $RADARR_API_KEY != "" ]; then
            REFRESH_NAME="RescanMovie"
            REFRESH_URL="http://radarr:${RADARR_PORT}/api/command?apikey=${RADARR_API_KEY}"
        fi
    ;;
esac

if [ $REFRESH_URL != "" ]; then
    REFRESH_CMD=$(\
        echo curl \
            -d \"{\\\"name\\\":\\\"${REFRESH_NAME}\\\"}\" \
            -H \"Content-Type: application/json\" \
	    -X POST \
            ${REFRESH_URL})
    echo $REFRESH_CMD >> /config/pvr-refresh.log
    eval $REFRESH_CMD
fi
