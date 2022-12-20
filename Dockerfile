FROM ruby:3.1.2-alpine AS builder


# Postgress dependancies
RUN apk update && apk add --no-cache \
  postgresql14-dev \
  postgresql14-client \
  build-base


# Postgress Gemfile for build
RUN echo 'source "https://rubygems.org"; gem "pg"' > Gemfile

RUN bundle install

# Clean image
FROM ruby:3.1.2-alpine

RUN apk add --no-cache bash

# Copy artifacts
COPY --from=builder /usr/local/bundle /usr/local/bundle

# RUN adduser -D deploy
# USER deploy

# WORKDIR /home/deploy/app

# COPY --chown=deploy Gemfile Gemfile.lock ./
# RUN bundle install

# COPY --chown=deploy test.rb .
# CMD ["ruby", "/home/app/test.rb"]
