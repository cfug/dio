FROM dart:2.19.6
WORKDIR /build/
COPY . /build/
WORKDIR /build/dio
RUN timeout 5m dart pub get
FROM scratch