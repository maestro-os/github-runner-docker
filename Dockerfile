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
	libssl-dev \
	lld \
	perl \
	pkg-config \
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
RUN cargo install mdbook

# Install build toolchain
# TODO

# Install runner
RUN curl -o actions-runner.tar.gz -L https://github.com/actions/runner/releases/download/v2.316.1/actions-runner-linux-x64-2.316.1.tar.gz
RUN echo "d62de2400eeeacd195db91e2ff011bfb646cd5d85545e81d8f78c436183e09a8  actions-runner.tar.gz" | shasum -a 256 -c

# Build health probe
RUN mkdir /home/user/runner/manager-build
ADD ./manager /home/user/runner/manager-build
WORKDIR /home/user/runner/manager-build
RUN cargo build --release
RUN cp target/release/manager ..
WORKDIR /home/user/runner
# Cleanup
USER 0
RUN rm -rf /home/user/runner/manager-build
USER 1000

# Run
ARG GITHUB_ACCESS_TOKEN
ARG GITHUB_USER
ARG REPOS
ENV GITHUB_ACCESS_TOKEN=$GITHUB_ACCESS_TOKEN
ENV GITHUB_USER=$GITHUB_USER
ENV REPOS=$REPOS
EXPOSE 8080
ENTRYPOINT ["./manager"]
