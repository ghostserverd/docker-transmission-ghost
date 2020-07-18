#!/bin/bash

#
# INFO
#

# This works if sonarr and radarr are set up to have a Category of sonarr and radarr respectively
# If you are using other Categories to save your automated downloads, set TRANS_GC_CATEGORIES.
# The variable content should be space separated for multiple categories i.e "cat1 cat2 cat3".
# This script will not touch anything outside those Categories.

# Set this file on a cron for every 5 minutes
# Using Docker? Make your cron something like this:
#   /usr/bin/docker exec $(/usr/bin/docker ps | grep "linuxserver/transmission:latest" | awk '{print $1}') bash "/path/to/transmission-gc.sh"

# Set =~ to be insensitive
shopt -s nocasematch

TRANS_REMOTE_BIN="/usr/bin/transmission-remote"
TRANS_HOST="127.0.0.1:${TRANS_WEBUI_PORT}"
TRANS_GC_CATEGORIES=${TRANS_GC_CATEGORIES:-"radarr sonarr tv-sonarr"}

# Amount of time (in seconds) after a torrent completes to delete them
# default to 0 which disables entirely
RETENTION=${TRANS_MAX_RETENTION:-0}

# Delete torrents only when ratio is above
# default to 0 which disables entirely
RATIO=${TRANS_MAX_RATIO:-0}

# Create categories list out of env variable
IFS=' ' read -a TORRENT_CATEGORIES_LIST <<< "$TRANS_GC_CATEGORIES"

# Clean up torrents where trackers have torrent not registered
# filter list by * (which signifies a tracker error)
TORRENT_DEAD_LIST=($("${TRANS_REMOTE_BIN}" "${TRANS_HOST}" -n "${TRANS_WEBUI_USER}":"${TRANS_WEBUI_PASS}" -l | sed -e '1d;$d;s/^ *//' | cut --only-delimited --delimiter=' ' --fields=1 | egrep '[0-9]+' | sed 's/\*$//'))
for torrent_id in "${TORRENT_DEAD_LIST[@]}"
do
  # Get the torrents metadata
  torrent_info=$("${TRANS_REMOTE_BIN}" "${TRANS_HOST}" -n "${TRANS_WEBUI_USER}":"${TRANS_WEBUI_PASS}" --torrent "${torrent_id}" -i -it)
  torrent_name=$(echo "${torrent_info}" | grep "Name: *" | sed 's/Name\:\s//i' | awk '{$1=$1};1')
  torrent_path=$(echo "${torrent_info}" | grep "Location: *" | sed 's/Location\:\s//i' | awk '{$1=$1};1')
  torrent_size=$(echo "${torrent_info}" | grep "Downloaded: *" | sed 's/Downloaded\:\s//i' | awk '{$1=$1};1')
  torrent_label=$(basename "${torrent_path}")
  case "${torrent_label}" in ${TORRENT_CATEGORIES_LIST[@]})
      torrent_error=$(echo "${torrent_info}" | grep "Got an error" | cut -d \" -f2)
      if [[ "${torrent_error}" =~ "unregistered" ]] || [[ "${torrent_error}" =~ "not registered" ]]; then
        # Delete torrent
        "${TRANS_REMOTE_BIN}" "${TRANS_HOST}" -n "${TRANS_WEBUI_USER}":"${TRANS_WEBUI_PASS}" --torrent "${torrent_id}" --remove-and-delete > /dev/null
      fi
  esac
done

# Clean up torrent where ratio is > ${RATIO} or seeding time > ${RETENTION} seconds
# do not filter the list, get all the torrents
echo "Deleting torrents with these criteria"
echo "Age > ${RETENTION}"
echo "Ratio > ${RATIO}"
echo "==========================================="
echo ""
TORRENT_ALL_LIST=($("${TRANS_REMOTE_BIN}" "${TRANS_HOST}" -n "${TRANS_WEBUI_USER}":"${TRANS_WEBUI_PASS}" -l | sed -e '1d;$d;s/^ *//' | cut --only-delimited --delimiter=' ' --fields=1))
for torrent_id in "${TORRENT_ALL_LIST[@]}"
do
  # Get the torrents metadata
  torrent_info=$("${TRANS_REMOTE_BIN}" "${TRANS_HOST}" -n "${TRANS_WEBUI_USER}":"${TRANS_WEBUI_PASS}" --torrent "${torrent_id}" -i -it)
  torrent_name=$(echo "${torrent_info}" | grep "Name: *" | sed 's/Name\:\s//i' | awk '{$1=$1};1')
  torrent_path=$(echo "${torrent_info}" | grep "Location: *" | sed 's/Location\:\s//i' | awk '{$1=$1};1')
  torrent_size=$(echo "${torrent_info}" | grep "Downloaded: *" | sed 's/Downloaded\:\s//i' | awk '{$1=$1};1')
  torrent_label=$(basename "${torrent_path}")
  torrent_seeding_seconds=$(echo "${torrent_info}" | grep "Seeding Time: *" | awk -F"[()]" '{print $2}' | sed 's/\sseconds//i')
  torrent_ratio=$(echo "${torrent_info}" | grep "Ratio: *" | sed 's/Ratio\:\s//i' | awk '{$1=$1};1')

  # Debug
  # echo "${torrent_id} - ${torrent_ratio} - ${torrent_seeding_seconds} - ${torrent_label} - ${torrent_name}"
  case "${torrent_label}" in
    "radarr"|"sonarr"|"tv-sonarr")
      # Torrents without a ratio have "None" instead of "0.0" let's fix that
      if [[ "${torrent_ratio}" =~ "None" ]]; then
        torrent_ratio="0.0"
      fi

      # delete torrents greater than ${RETENTION}
      if [[ "${RETENTION}" -ne "0" && "${RETENTION}" -ne "" && "${torrent_seeding_seconds}" -gt "${RETENTION}" ]]; then
        echo "AGE ${torrent_seeding_seconds}"
        echo "${torrent_label} ${torrent_name}"
        echo ""
        "${TRANS_REMOTE_BIN}" "${TRANS_HOST}" -n "${TRANS_WEBUI_USER}":"${TRANS_WEBUI_PASS}" --torrent "${torrent_id}" --remove-and-delete > /dev/null
      fi

      # delete torrents greater than ${RATIO}
      if [[ "${RATIO}" -ne "0" && "${RATIO}" -ne "" ]] && (( $(echo "${torrent_ratio} ${RATIO}" | awk '{print ($1 > $2)}') )); then
        echo "RATIO ${torrent_ratio}"
        echo "${torrent_label} ${torrent_name}"
        echo ""
        "${TRANS_REMOTE_BIN}" "${TRANS_HOST}" -n "${TRANS_WEBUI_USER}":"${TRANS_WEBUI_PASS}" --torrent "${torrent_id}" --remove-and-delete > /dev/null
      fi
  esac
done
