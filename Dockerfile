FROM linuxserver/transmission

# add ghost config file
COPY root/ /

WORKDIR /usr/local/bin

# add transmission garbage collection
COPY transmission-garbagecollect.sh transmission-garbagecollect.sh
RUN chmod +rx transmission-garbagecollect.sh
