FROM python:3.10 as tmp

WORKDIR /tmp

ENV PATH="${PATH}:/root/.local/bin"

COPY ./pyproject.toml ./poetry.lock* /tmp/
RUN pip install poetry \
  && poetry config virtualenvs.in-project true \
  && poetry install --only main --no-interaction --no-ansi

FROM python:3.10-slim as app

WORKDIR /app

EXPOSE 2233

VOLUME /data

COPY --from=tmp /tmp/.venv /app/.venv

COPY ./resources/fonts/* /usr/share/fonts/meme-fonts/
RUN apt-get update \
  && apt-get install -y --no-install-recommends locales fontconfig fonts-noto-color-emoji gettext \
  && localedef -i zh_CN -c -f UTF-8 -A /usr/share/locale/locale.alias zh_CN.UTF-8 \
  && fc-cache -fv \
  && apt-get purge -y --auto-remove \
  && rm -rf /var/lib/apt/lists/*

ENV TZ=Asia/Shanghai \
  LC_ALL=zh_CN.UTF-8 \
  PATH="/app/.venv/bin:${PATH}" \
  VIRTUAL_ENV="/app/.venv" \
  LOAD_BUILTIN_MEMES=true \
  MEME_DIRS="[\"/data/memes\"]" \
  MEME_DISABLED_LIST="[]" \
  GIF_MAX_SIZE=10.0 \
  GIF_MAX_FRAMES=100 \
  BAIDU_TRANS_APPID="" \
  BAIDU_TRANS_APIKEY="" \
  LOG_LEVEL="INFO"

COPY ./meme_generator /app/meme_generator

COPY ./docker/config.toml.template /app/config.toml.template
COPY ./docker/start.sh /app/start.sh
RUN chmod +x /app/start.sh

CMD ["/app/start.sh"]
