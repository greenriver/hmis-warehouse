FROM justinhimself/sftp

LABEL org.opencontainers.image.source https://github.com/greenriver/hmis-warehouse

COPY sftp.conf /etc/sftp/users.conf

COPY ssh_host_ed25519_key ssh_host_ed25519_key.pub ssh_host_rsa_key ssh_host_rsa_key.pub /etc/ssh/

RUN chmod 0644 /etc/ssh/*.pub \
    && chmod 0600 /etc/ssh/*key
