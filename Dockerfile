FROM nginx:mainline-alpine-slim
MAINTAINER ifeng <https://t.me/HiaiFeng>
EXPOSE 80
USER root

RUN apk update && apk add --no-cache supervisor wget unzip curl

# UUID / paths
ENV UUID 90bfcba3-b9e8-4f4e-9d65-143c3536136f
ENV VMESS_WSPATH /vmess
ENV VLESS_WSPATH /vless

COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY nginx.conf /etc/nginx/nginx.conf

RUN mkdir -p /etc/v2ray /usr/local/v2ray
COPY config.json /etc/v2ray/
COPY entrypoint.sh /usr/local/v2ray/

# v2ray core: GitHub direct is unreachable on some build nodes, fall back through mirrors
RUN set -eux; \
    ok=0; \
    for u in \
      "https://gh-proxy.com/https://github.com/v2fly/v2ray-core/releases/download/v4.45.0/v2ray-linux-64.zip" \
      "https://ghfast.top/https://github.com/v2fly/v2ray-core/releases/download/v4.45.0/v2ray-linux-64.zip" \
      "https://github.com/v2fly/v2ray-core/releases/download/v4.45.0/v2ray-linux-64.zip" ; do \
      echo "trying $u"; \
      if wget -q -T 90 -O /tmp/v2ray.zip "$u"; then ok=1; break; fi; \
    done; \
    test "$ok" = "1" || { echo "all download sources failed"; exit 1; }; \
    unzip -o -d /usr/local/v2ray /tmp/v2ray.zip v2ray; \
    chmod a+x /usr/local/v2ray/entrypoint.sh /usr/local/v2ray/v2ray; \
    apk del wget unzip; \
    rm -rf /tmp/v2ray.zip /var/cache/apk/*

ENTRYPOINT [ "/usr/local/v2ray/entrypoint.sh" ]
