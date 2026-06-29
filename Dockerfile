FROM node:lts-trixie-slim AS base
RUN apt-get update \
  && apt-get install -y --no-install-recommends ca-certificates curl git wget ripgrep python3 \
  && rm -rf /var/lib/apt/lists/* \
  && corepack enable

FROM base AS deps
WORKDIR /app
RUN git clone --depth 1 https://github.com/paperclipai/paperclip.git . \
  && pnpm install --frozen-lockfile

FROM base AS build
WORKDIR /app
COPY --from=deps /app /app
RUN pnpm --filter @paperclipai/ui build \
  && pnpm --filter @paperclipai/plugin-sdk build \
  && pnpm --filter @paperclipai/server build \
  && test -f server/dist/index.js

FROM base AS production
WORKDIR /app
COPY --from=build /app /app
RUN apt-get update \
  && apt-get install -y --no-install-recommends openssh-client jq gosu \
  && rm -rf /var/lib/apt/lists/* \
  && mkdir -p /paperclip

# Install all AI CLIs
RUN npm install -g \
  @anthropic-ai/claude-code@latest \
  @openai/codex@latest \
  opencode-ai@latest \
  @google/gemini-cli@latest

# OpenCode - all 11 providers configure
ARG ANTHROPIC_API_KEY
ARG OPENAI_API_KEY
ARG GEMINI_API_KEY
ARG GROQ_API_KEY
ARG OPENROUTER_API_KEY
ARG MISTRAL_API_KEY
ARG DEEPSEEK_API_KEY
ARG CEREBRAS_API_KEY
ARG TOGETHER_API_KEY
ARG NOVITA_API_KEY
ARG NVIDIA_API_KEY

RUN opencode config set --global providers.anthropic.apiKey "${ANTHROPIC_API_KEY}" || true
RUN opencode config set --global providers.openai.apiKey "${OPENAI_API_KEY}" || true
RUN opencode config set --global providers.google.apiKey "${GEMINI_API_KEY}" || true
RUN opencode config set --global providers.groq.apiKey "${GROQ_API_KEY}" || true
RUN opencode config set --global providers.openrouter.apiKey "${OPENROUTER_API_KEY}" || true
RUN opencode config set --global providers.mistral.apiKey "${MISTRAL_API_KEY}" || true
RUN opencode config set --global providers.deepseek.apiKey "${DEEPSEEK_API_KEY}" || true
RUN opencode config set --global providers.cerebras.apiKey "${CEREBRAS_API_KEY}" || true
RUN opencode config set --global providers.together.apiKey "${TOGETHER_API_KEY}" || true
RUN opencode config set --global providers.novita.apiKey "${NOVITA_API_KEY}" || true

COPY start.sh /usr/local/bin/start.sh
RUN chmod +x /usr/local/bin/start.sh

ENV NODE_ENV=production \
  HOME=/paperclip \
  HOST=0.0.0.0 \
  PORT=3100 \
  SERVE_UI=true \
  PAPERCLIP_HOME=/paperclip \
  PAPERCLIP_INSTANCE_ID=default \
  PAPERCLIP_CONFIG=/paperclip/instances/default/config.json \
  PAPERCLIP_DEPLOYMENT_MODE=authenticated \
  PAPERCLIP_DEPLOYMENT_EXPOSURE=public \
  ANTHROPIC_API_KEY=${ANTHROPIC_API_KEY} \
  OPENAI_API_KEY=${OPENAI_API_KEY} \
  GEMINI_API_KEY=${GEMINI_API_KEY} \
  GOOGLE_API_KEY=${GEMINI_API_KEY} \
  GOOGLE_GENERATIVE_AI_API_KEY=${GEMINI_API_KEY} \
  GROQ_API_KEY=${GROQ_API_KEY} \
  OPENROUTER_API_KEY=${OPENROUTER_API_KEY} \
  MISTRAL_API_KEY=${MISTRAL_API_KEY} \
  DEEPSEEK_API_KEY=${DEEPSEEK_API_KEY} \
  CEREBRAS_API_KEY=${CEREBRAS_API_KEY} \
  TOGETHER_API_KEY=${TOGETHER_API_KEY} \
  NOVITA_API_KEY=${NOVITA_API_KEY} \
  NVIDIA_API_KEY=${NVIDIA_API_KEY}

EXPOSE 3100
CMD ["start.sh"]
