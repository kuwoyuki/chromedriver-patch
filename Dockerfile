FROM rust:latest as cargo-build
WORKDIR /usr/src/myapp
COPY Cargo.toml Cargo.lock ./
RUN mkdir src/ && echo "fn main() {println!(\"broken build\")}" > src/main.rs
RUN cargo build --release
RUN rm -f target/release/deps/patch_cd*
COPY . .
RUN cargo build --release
RUN cargo install --path .

FROM debian:sid-slim

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update -qqy && apt-get install -y --no-install-recommends ca-certificates
RUN update-ca-certificates
RUN apt-get install -y gnupg wget curl unzip --no-install-recommends && \
    wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub > /usr/share/keyrings/chrome.pub && \
    echo 'deb [arch=amd64 signed-by=/usr/share/keyrings/chrome.pub] http://dl.google.com/linux/chrome/deb/ stable main' > /etc/apt/sources.list.d/google-chrome.list && \
    apt-get update -qqy && \
    apt-get install -y google-chrome-stable && \
    CHROME_VERSION=$(google-chrome --product-version | grep -o "[^\.]*\.[^\.]*\.[^\.]*") && \
    CHROMEDRIVER_VERSION=$(curl -s "https://chromedriver.storage.googleapis.com/LATEST_RELEASE_$CHROME_VERSION") && \
    wget -q --continue -P /chromedriver "http://chromedriver.storage.googleapis.com/$CHROMEDRIVER_VERSION/chromedriver_linux64.zip" && \
    unzip /chromedriver/chromedriver* -d /usr/local/bin/

COPY --from=cargo-build /usr/local/cargo/bin/patch-cd /usr/local/bin/patch-cd

ENTRYPOINT ["/usr/local/bin/patch-cd"]
