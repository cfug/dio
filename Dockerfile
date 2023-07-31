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
RUN create_publishable_artifact.sh

WORKDIR /build/json_annotation-3.1.1
RUN create_publishable_artifact.sh

WORKDIR /build/json_serializable-3.5.2
RUN create_publishable_artifact.sh

ARG BUILD_ARTIFACTS_PUB=/build/dio/pub_package.pub.tgz:/build/json_annotation-3.1.1/pub_package.pub.tgz:/build/json_serializable-3.5.2/pub_package.pub.tgz

FROM scratch