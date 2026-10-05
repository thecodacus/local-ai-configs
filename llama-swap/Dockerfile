# llama-swap front door: proxies :8080 to either the llama.cpp router (a sibling docker container,
# started through the host's docker socket) or Strata (run inside this container from the mounted Strata venv).
FROM docker:27-cli AS dockercli
FROM ubuntu:24.04
ARG LLAMA_SWAP_VERSION=261
ENV DEBIAN_FRONTEND=noninteractive PYTHONUNBUFFERED=1
# python3.12 matches the venv Strata installs; libgomp/libatomic for the Strata engine
RUN apt-get update && apt-get install -y --no-install-recommends python3 python3-venv libgomp1 libatomic1 \
      ca-certificates curl tini procps \
    && rm -rf /var/lib/apt/lists/*
COPY --from=dockercli /usr/local/bin/docker /usr/local/bin/docker
RUN curl -fsSL "https://github.com/mostlygeek/llama-swap/releases/download/v${LLAMA_SWAP_VERSION}/llama-swap_${LLAMA_SWAP_VERSION}_linux_amd64.tar.gz" \
      | tar -xz -C /usr/local/bin llama-swap && /usr/local/bin/llama-swap --version
ENTRYPOINT ["/usr/bin/tini", "--", "/usr/local/bin/llama-swap", "--config", "/config/config.yaml", "--listen", ":8080", "--watch-config"]
