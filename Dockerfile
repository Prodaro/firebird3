# Firebird 3.0.14 fuer NAS-Systeme (QNAP/Synology), amd64 + arm64.
# Fuer arm64-Linux gibt es keine offiziellen Firebird-3-Binaerpakete
# (die arm64-Release-Tarballs sind Android-Builds), daher wird aus
# den offiziellen Quellen kompiliert.
#
# Achtung: Dieselben Build-Anweisungen stecken als Fallback im
# internen install-firebird.sh - Aenderungen dort nachziehen!

FROM debian:bookworm AS build

ARG FB_VERSION=3.0.14.33856-0
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        g++ make wget ca-certificates bzip2 \
        zlib1g-dev libtommath-dev libicu-dev libncurses-dev autotools-dev && \
    rm -rf /var/lib/apt/lists/*

RUN wget -q -O /tmp/fb-src.tar.bz2 \
      "https://github.com/FirebirdSQL/firebird/releases/download/v3.0.14/Firebird-${FB_VERSION}.tar.bz2" && \
    mkdir /src && \
    tar xjf /tmp/fb-src.tar.bz2 -C /src --strip-components=1 && \
    rm /tmp/fb-src.tar.bz2

WORKDIR /src

# Das mitgelieferte config.guess/config.sub (Stand 2010) kennt
# aarch64 nicht - aktuelle Fassungen aus autotools-dev einsetzen
RUN find /src -name config.guess -exec cp /usr/share/misc/config.guess {} \; && \
    find /src -name config.sub -exec cp /usr/share/misc/config.sub {} \;

RUN ./configure --prefix=/opt/firebird

RUN make -j2 || make -j1

RUN cp -r gen/Release/firebird /opt/firebird && \
    test -x /opt/firebird/bin/firebird && \
    test -f /opt/firebird/firebird.msg && \
    test -f /opt/firebird/security3.fdb

FROM debian:bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        procps netbase libicu72 libtommath1 libncurses6 zlib1g && \
    rm -rf /var/lib/apt/lists/*

COPY --from=build /opt/firebird /opt/firebird

RUN useradd -r -s /usr/sbin/nologin -d /opt/firebird firebird && \
    chown -R firebird:firebird /opt/firebird && \
    echo "/opt/firebird/lib" > /etc/ld.so.conf.d/firebird.conf && \
    ldconfig && \
    echo "WireCrypt = Enabled" >> /opt/firebird/firebird.conf && \
    echo "DatabaseAccess = Restrict /var/lib/firebird/data" >> /opt/firebird/firebird.conf

ENV FIREBIRD=/opt/firebird

# Ohne UTF-8-Locale laeuft Firebird in der C-Locale (nur ASCII) und lehnt
# Clients mit Umlaut im Rechner- oder Benutzernamen beim Verbinden ab
# ("Cannot transliterate character between character sets")
ENV LANG=C.UTF-8

COPY entrypoint.sh /entrypoint.sh
RUN chmod 755 /entrypoint.sh

EXPOSE 3050
VOLUME /var/lib/firebird/data

ENTRYPOINT ["/entrypoint.sh"]
