FROM debian:bullseye

# Prepare
RUN apt update
RUN apt install -y build-essential gcc binutils-i686-linux-gnu clang lld git make curl perl libicu-dev
RUN mkdir /home/user
RUN chown 1000:1000 /home/user
USER 1000
ENV HOME=/home/user
RUN mkdir /home/user/runner
WORKDIR /home/user/runner
RUN curl https://sh.rustup.rs -sSf | bash -s -- -y
ENV PATH="/home/user/.cargo/bin:${PATH}"

# Install runner
RUN curl -o actions-runner-linux-x64-2.316.1.tar.gz -L https://github.com/actions/runner/releases/download/v2.316.1/actions-runner-linux-x64-2.316.1.tar.gz
RUN echo "d62de2400eeeacd195db91e2ff011bfb646cd5d85545e81d8f78c436183e09a8  actions-runner-linux-x64-2.316.1.tar.gz" | shasum -a 256 -c
RUN tar xzf ./actions-runner-linux-x64-2.316.1.tar.gz

# Configure
ARG URL
ARG TOKEN
RUN yes '' | ./config.sh --url $URL --token $TOKEN

# Run
ENTRYPOINT ["./run.sh"]
