FROM ruby:2.7-alpine

RUN apk add --update --no-cache \
    build-base \
    gcc \
    cmake \
    bash \
    git \
    git-bash-completion

RUN gem update bundler && \
    gem install bundler jekyll commonmarker

EXPOSE 4000

CMD /bin/sh