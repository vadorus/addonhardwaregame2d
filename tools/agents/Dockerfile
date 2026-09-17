FROM node:22-bookworm-slim

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        git \
        libasound2 \
        libfontconfig1 \
        libgl1 \
        libxi6 \
        libxinerama1 \
        libxrandr2 \
    && rm -rf /var/lib/apt/lists/*

RUN npm install --global @openai/codex@alpha \
    && git config --system --add safe.directory /workspace

WORKDIR /workspace

ENTRYPOINT ["codex", "exec-server"]
