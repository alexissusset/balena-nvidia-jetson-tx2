## Connectivity
FROM resin/%%RESIN_MACHINE_NAME%%-python:3

# Disable systemd
ENV INITSYSTEM off

CMD exec /bin/bash -c "echo 'online' && trap : TERM INT; sleep infinity & wait"