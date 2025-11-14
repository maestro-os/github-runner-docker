FROM rust:1.91.1-slim-trixie AS builder

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
	--mount=type=cache,target=/var/lib/apt,sharing=locked \
	# Install packages
	apt update && apt-get --no-install-recommends install -y \
	bash \
	build-essential \
	clang \
	grub-pc-bin \
	libssl-dev \
	lld \
	perl \
	pkg-config \
	qemu-system \
	texinfo \
	xorriso \
	# Prepare 
	&& mkdir /home/user \
	&& chown 1000:1000 /home/user \
	&& cargo install mdbook mdbook-mermaid

# Build linker
WORKDIR /home/user/ld-build
COPY binutils-build.sh .
ADD https://ftp.gnu.org/gnu/binutils/binutils-2.45.1.tar.gz binutils.tar.gz
RUN \
	tar xzf binutils.tar.gz \
	&& rm binutils.tar.gz \
	&& ./binutils-build.sh \
	&& cd .. \
	&& rm -rf ld-build/

# Install runner
ADD --checksum=sha256:194f1e1e4bd02f80b7e9633fc546084d8d4e19f3928a324d512ea53430102e1d \
	https://github.com/actions/runner/releases/download/v2.329.0/actions-runner-linux-x64-2.329.0.tar.gz \
	actions-runner.tar.gz
RUN \ 
	mkdir runner \
	&& tar xzf actions-runner.tar.gz -C runner \
	&& rm actions-runner.tar.gz \
	&& ./runner/bin/installdependencies.sh

# Build manager
WORKDIR /home/user/manager-build
COPY ./manager .
RUN --mount=type=cache,target=/home/user/manager-build/target \
	--mount=type=cache,target=/usr/local/cargo/git/db \
	--mount=type=cache,target=/usr/local/cargo/registry/ \
	cargo build --release \
	&& cp target/release/manager ..

# Cleanup
# Note: different RUN layer because of docker layer caching
# preventing from deleting the manager-build/target folder
WORKDIR /home/user
RUN	rm -rf manager-build/ \
	&& apt remove -y texinfo \
	&& apt clean

# Final image
FROM scratch
COPY --from=builder / /
EXPOSE 8080

# Drop privileges
USER 1000

# Run
WORKDIR /home/user
ENTRYPOINT ["./manager"]
