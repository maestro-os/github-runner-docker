FROM rust:1.91.1-slim-bookworm AS base

FROM base AS manager-build

# Build manager
WORKDIR /manager-build
COPY ./manager/ .
RUN --mount=type=cache,target=/home/user/manager-build/target \
	--mount=type=cache,target=/usr/local/cargo/git/db \
	--mount=type=cache,target=/usr/local/cargo/registry/ \
	--mount=type=cache,target=/var/cache/apt,sharing=locked \
	--mount=type=cache,target=/var/lib/apt,sharing=locked \
	apt update \
	&& apt-get --no-install-recommends install -y \
	libssl-dev \
	pkg-config \
	&& cargo build --release

# Build things for final image
FROM base AS prepare-final

WORKDIR /ld-build
COPY binutils-build.sh .
ADD --unpack=true https://ftp.gnu.org/gnu/binutils/binutils-2.45.1.tar.gz .
RUN \
	apt update && apt-get --no-install-recommends install -y \
	build-essential \
	texinfo \
	&& ./binutils-build.sh

WORKDIR /home/user/runner
ADD --checksum=sha256:194f1e1e4bd02f80b7e9633fc546084d8d4e19f3928a324d512ea53430102e1d \
	--unpack=true \
	https://github.com/actions/runner/releases/download/v2.329.0/actions-runner-linux-x64-2.329.0.tar.gz .
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
	--mount=type=cache,target=/var/lib/apt,sharing=locked \
	# Install GH runner dependencies
	./bin/installdependencies.sh \
	# Cleanup ld build
	&& rm -rf ../ld-build \
	# Install CI tools
	&& cargo install mdbook mdbook-mermaid \
	&& apt update && apt-get --no-install-recommends install -y \
	bash \
	clang \
	grub-pc-bin \
	lld \
	qemu-system \
	xorriso


# Final image
FROM prepare-final
WORKDIR /home/user
COPY --from=manager-build /manager-build/target/release/manager .
EXPOSE 8080

# Drop privileges
RUN chown -R 1000:1000 .
USER 1000

# Run
ENTRYPOINT ["./manager"]
