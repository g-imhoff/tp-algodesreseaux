FROM debian:latest
RUN apt-get update && apt-get install -y \
    gcc \
    valgrind \
    netcat-openbsd \
    make \
    time \
    tshark \
    net-tools \
    strace

RUN useradd --create-home --shell /bin/bash alice

USER alice
WORKDIR /home/alice
