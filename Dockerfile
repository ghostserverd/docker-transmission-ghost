FROM linuxserver/transmission

# add ghost config file
COPY root/ /

WORKDIR /usr/local/bin

# add default settings.json
COPY settings.json settings.json

# add jq for easier settings parsing
RUN apk add jq

# add transmission garbage collection
COPY transmission-garbagecollect.sh transmission-garbagecollect.sh
RUN chmod +rx transmission-garbagecollect.sh

RUN echo "0 3 * * * /usr/local/bin/transmission-garbagecollect.sh >> /media/transmissiongc.log 2>&1" >> /etc/crontabs/root

# add default post process
COPY transmission-postprocess.sh transmission-postprocess.sh
RUN chmod +rx transmission-postprocess.sh
