####################
##   Dart Stage   ##
####################
FROM drydock-prod.workiva.net/workiva/dart2_base_image:1 as build

# Update image (required by aviary) and install tools
RUN apt-get update -qq && \
    apt-get dist-upgrade -y && \
    apt-get install -y jq && \
    apt-get autoremove -y && \
    apt-get clean all

# setup ssh
ARG GIT_SSH_KEY
ARG KNOWN_HOSTS_CONTENT
RUN mkdir /root/.ssh/ && \
  echo "$KNOWN_HOSTS_CONTENT" > "/root/.ssh/known_hosts" && \
  chmod 700 /root/.ssh/ && \
  umask 0077 && echo "$GIT_SSH_KEY" > /root/.ssh/id_rsa && \
  eval "$(ssh-agent -s)" && ssh-add /root/.ssh/id_rsa

WORKDIR /build/
COPY . /build/

# Build Environment Vars Required for wdesk app build, semver audit, and ddev's
# usage reporting.
ARG GIT_COMMIT
ARG GIT_TAG
ARG GIT_BRANCH
ARG GIT_MERGE_HEAD
ARG GIT_MERGE_BRANCH
ARG GIT_HEAD_REPO
ARG BUILD_ID

WORKDIR /build/dio
RUN timeout 5m dart pub get
RUN dart test
RUN dart analyze

RUN create_publishable_artifact.sh

ARG BUILD_ARTIFACTS_PUB=/build/dio/pub_package.pub.tgz

FROM scratch