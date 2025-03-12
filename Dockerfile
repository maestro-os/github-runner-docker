FROM debian:12.7-slim

# Install packages
RUN apt update
RUN apt install -y \
	bash \
	build-essential \
	clang \
	curl \
	grub-pc-bin \
	libssl-dev \
	lld \
	perl \
	pkg-config \
	qemu-system \
	texinfo \
	xorriso
# Prepare
RUN mkdir /home/user
RUN chown 1000:1000 /home/user
USER 1000
ENV HOME=/home/user
# Install Rust
RUN curl https://sh.rustup.rs -sSf | sh -s -- -y
ENV PATH="/home/user/.cargo/bin:${PATH}"
RUN cargo install mdbook
WORKDIR /home/user

# Build linker
USER 0
RUN mkdir ld-build
WORKDIR /home/user/ld-build
RUN curl -o binutils.tar.gz https://ftp.gnu.org/gnu/binutils/binutils-2.44.tar.gz
RUN tar xzf binutils.tar.gz
RUN rm binutils.tar.gz
ADD binutils-build.sh .
RUN ./binutils-build.sh
WORKDIR /home/user
RUN rm -rf ld-build/
USER 1000

# Install runner
RUN curl -o actions-runner.tar.gz -L https://github.com/actions/runner/releases/download/v2.322.0/actions-runner-linux-x64-2.322.0.tar.gz
RUN echo "b13b784808359f31bc79b08a191f5f83757852957dd8fe3dbfcc38202ccf5768  actions-runner.tar.gz" | shasum -a 256 -c
RUN mkdir runner
RUN tar xzf actions-runner.tar.gz -C runner
RUN rm actions-runner.tar.gz
USER 0
RUN runner/bin/installdependencies.sh
USER 1000

# Build manager
RUN mkdir manager-build
ADD ./manager manager-build
WORKDIR /home/user/manager-build
RUN cargo build --release
RUN cp target/release/manager ..
WORKDIR /home/user
# Cleanup
USER 0
RUN rm -rf manager-build/
USER 1000

# Remove unused packages
USER 0
RUN apt remove -y curl texinfo
RUN apt clean
USER 1000

# Run
ARG GITHUB_ACCESS_TOKEN
ARG GITHUB_ORG
ENV GITHUB_ACCESS_TOKEN=$GITHUB_ACCESS_TOKEN
ENV GITHUB_ORG=$GITHUB_ORG
EXPOSE 8080
ENTRYPOINT ["./manager"]
