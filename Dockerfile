FROM rust:1.91.1-slim-trixie

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
	--mount=type=cache,target=/var/lib/apt,sharing=locked \
	# Install packages
	apt update && apt-get --no-install-recommends install -y \
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
	xorriso \
	# ---
	# Prepare 
	&& mkdir /home/user \
	&& chown 1000:1000 /home/user

USER 1000
ENV HOME=/home/user
RUN cargo install mdbook mdbook-mermaid
WORKDIR /home/user

# Build linker
USER 0
RUN mkdir ld-build
WORKDIR /home/user/ld-build
RUN \
	curl -o binutils.tar.gz https://ftp.gnu.org/gnu/binutils/binutils-2.45.tar.gz \
	&& tar xzf binutils.tar.gz \
	&& rm binutils.tar.gz
ADD binutils-build.sh .
RUN ./binutils-build.sh
WORKDIR /home/user
RUN rm -rf ld-build/
USER 1000

# Install runner
RUN \
	curl -o actions-runner.tar.gz -L https://github.com/actions/runner/releases/download/v2.329.0/actions-runner-linux-x64-2.329.0.tar.gz \
	&& echo "194f1e1e4bd02f80b7e9633fc546084d8d4e19f3928a324d512ea53430102e1d  actions-runner.tar.gz" | shasum -a 256 -c \
	&& mkdir runner \
	&& tar xzf actions-runner.tar.gz -C runner \
	&& rm actions-runner.tar.gz
USER 0
RUN runner/bin/installdependencies.sh
USER 1000

# Build manager
RUN mkdir manager-build
ADD ./manager manager-build
WORKDIR /home/user/manager-build
RUN cargo build --release && cp target/release/manager ..
WORKDIR /home/user
# Cleanup
USER 0
RUN rm -rf manager-build/
USER 1000

# Remove unused packages
USER 0
RUN apt remove -y curl texinfo && apt clean
USER 1000

# Run
EXPOSE 8080
ENTRYPOINT ["./manager"]
