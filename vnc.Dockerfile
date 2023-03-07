FROM rust:latest as cargo-build
WORKDIR /usr/src/
RUN USER=root cargo new myapp
COPY Cargo.toml Cargo.lock /usr/src/myapp/
WORKDIR /usr/src/myapp/
RUN cargo build --release
# copy src
COPY src /usr/src/myapp/src/
# modify mtime to force cargo to rebuild
RUN touch /usr/src/myapp/src/main.rs
RUN cargo build --release
RUN strip /usr/src/myapp/target/release/patch-cd

FROM debian:sid

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update -qqy && apt-get install -y --no-install-recommends ca-certificates
RUN update-ca-certificates
RUN apt-get install -y xvfb dbus-x11 gnupg wget curl unzip --no-install-recommends && \
    wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub > /usr/share/keyrings/chrome.pub && \
    echo 'deb [arch=amd64 signed-by=/usr/share/keyrings/chrome.pub] http://dl.google.com/linux/chrome/deb/ stable main' > /etc/apt/sources.list.d/google-chrome.list && \
    apt-get update -qqy && \
    apt-get install -y google-chrome-stable && \
    CHROME_VERSION=$(google-chrome --product-version | grep -o "[^\.]*\.[^\.]*\.[^\.]*") && \
    CHROMEDRIVER_VERSION=$(curl -s "https://chromedriver.storage.googleapis.com/LATEST_RELEASE_$CHROME_VERSION") && \
    wget -q --continue -P /chromedriver "http://chromedriver.storage.googleapis.com/$CHROMEDRIVER_VERSION/chromedriver_linux64.zip" && \
    unzip /chromedriver/chromedriver* -d /usr/local/bin/

RUN apt-get install -y x11vnc fluxbox psmisc xrdp

ENV DBUS_SESSION_BUS_ADDRESS=/dev/null

COPY --from=cargo-build /usr/src/myapp/target/release/patch-cd /usr/local/bin/patch-cd
COPY entrypoint_vnc.sh /

ENTRYPOINT ["/entrypoint_vnc.sh", "/usr/local/bin/patch-cd"]
