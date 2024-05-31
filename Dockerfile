FROM debian:11.9-slim

# Install packages
RUN apt update
RUN apt install -y \
	bash \
	build-essential \
	clang \
	curl \
	git \
	libicu-dev \
	lld \
	perl \
	qemu
# Prepare
RUN mkdir /home/user
RUN chown 1000:1000 /home/user
USER 1000
ENV HOME=/home/user
RUN mkdir /home/user/runner
WORKDIR /home/user/runner
# Install Rust
RUN curl https://sh.rustup.rs -sSf | sh -s -- -y
ENV PATH="/home/user/.cargo/bin:${PATH}"

# Build health probe
RUN mkdir /home/user/runner/health-probe-build
ADD ./health-probe /home/user/runner/health-probe-build
WORKDIR /home/user/runner/health-probe-build
RUN cargo build --release
RUN cp target/release/health-probe ..
WORKDIR /home/user/runner
# Cleanup
USER 0
RUN rm -rf /home/user/runner/health-probe-build
USER 1000

# Install build toolchain
# TODO

# Install runner
RUN curl -o actions-runner-linux-x64-2.316.1.tar.gz -L https://github.com/actions/runner/releases/download/v2.316.1/actions-runner-linux-x64-2.316.1.tar.gz
RUN echo "d62de2400eeeacd195db91e2ff011bfb646cd5d85545e81d8f78c436183e09a8  actions-runner-linux-x64-2.316.1.tar.gz" | shasum -a 256 -c
RUN tar xzf ./actions-runner-linux-x64-2.316.1.tar.gz
RUN rm actions-runner-linux-x64-2.316.1.tar.gz

# Configure
ARG URL
ARG TOKEN
RUN yes '' | ./config.sh --url $URL --token $TOKEN

# Run
EXPOSE 8080
ENTRYPOINT ["./health-probe"]
