# syntax=docker/dockerfile:1
# 設計勉強会用 BadBooks の開発用 Dockerfile
# 本番運用は想定しない。bin/rails server を development モードで起動する。

ARG RUBY_VERSION=3.4.8
FROM ruby:${RUBY_VERSION}-slim

ENV RAILS_ENV=development \
    BUNDLE_PATH=/usr/local/bundle \
    LANG=C.UTF-8 \
    TZ=Asia/Tokyo

WORKDIR /rails

RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
      build-essential \
      git \
      pkg-config \
      libsqlite3-dev \
      libyaml-dev \
      sqlite3 \
      curl && \
    rm -rf /var/lib/apt/lists/*

# Gemfile を先に入れてレイヤキャッシュを効かせる
COPY Gemfile Gemfile.lock ./
RUN bundle install

# compose では bind mount するためここでの COPY は上書きされる。
# `docker run` で単体起動した場合のフォールバック用。
COPY . .

EXPOSE 3000

ENTRYPOINT ["/rails/bin/docker-entrypoint"]
CMD ["bin/rails", "server", "-b", "0.0.0.0"]
