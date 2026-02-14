docker run --rm -it \
  --platform=linux/amd64 \
  -e http_proxy="http://host.docker.internal:10808" \
  -e https_proxy="http://host.docker.internal:10808" \
  -v "$PWD:/work" \
  alpine:latest \
  sh -c '
    apk add --no-cache build-base openssl-dev zlib-dev curl &&
    cd /work &&
    curl -LO https://matt.ucc.asn.au/dropbear/releases/dropbear-2025.89.tar.bz2 &&
    tar xf dropbear-2025.89.tar.bz2 &&
    cd dropbear-2025.89 &&
    CFLAGS="-Os" LDFLAGS="-static -s" \
    ./configure \
      --disable-syslog \
      --disable-lastlog \
      --disable-utmp \
      --disable-utmpx \
      --disable-wtmp \
      --disable-wtmpx \
      --disable-loginfunc \
      --disable-pututline \
      --disable-pututxline &&
    make
  '