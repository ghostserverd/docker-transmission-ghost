FROM linuxserver/transmission

# add ghost config file
COPY root/ /

WORKDIR /usr/local/bin

# add transmission garbage collection
COPY transmission-garbagecollect.sh transmission-garbagecollect.sh
RUN chmod +rx transmission-garbagecollect.sh

RUN echo "0 3 * * * /usr/local/bin/transmission-garbagecollect.sh >> /media/transmissiongc.log 2>&1" >> /etc/crontabs/root

# add default post process
COPY transmission-postprocess.sh transmission-postprocess.sh
RUN chmod +rx transmission-postprocess.sh
