## Ubuntu
FROM aarch64/ubuntu

# Disable systemd
ENV INITSYSTEM off

CMD exec /bin/bash -c "echo 'online' && trap : TERM INT; sleep infinity & wait"