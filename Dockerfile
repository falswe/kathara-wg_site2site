FROM kathara/base

RUN apt-get update && \
    apt-get install -y wireguard iproute2 && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

CMD ["/bin/bash"]