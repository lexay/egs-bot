FROM ruby:3.1.2-alpine AS base

FROM base AS dependancies
RUN apk update && apk add --no-cache \
  postgresql14-dev \
  build-base

COPY Gemfile Gemfile.lock ./
RUN bundle install

FROM base
RUN apk add --update libpq

RUN adduser -D deploy
USER deploy
WORKDIR /home/deploy/app

COPY --from=dependancies /usr/local/bundle /usr/local/bundle

COPY --chown=deploy . .
CMD ["bundle", "exec", "ruby", "./start.rb"]
