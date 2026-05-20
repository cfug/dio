# Test fixtures: pinning

`server_cert.pem` and `server_key.pem` are a self-signed TLS keypair used by
`pinning_test.dart`'s pre-emission validation tests to spin up local
`HttpServer.bindSecure` instances on `localhost`.

These files are committed to keep the test suite hermetic (no network
dependency for the load-bearing regression test that asserts request bytes
do not leak when `validateCertificate` rejects).

The current pair has 10-year validity. To regenerate when it expires:

```sh
openssl req -x509 -newkey rsa:2048 \
  -keyout server_key.pem -out server_cert.pem \
  -days 3650 -nodes \
  -subj "/CN=localhost" \
  -addext "subjectAltName=DNS:localhost,IP:127.0.0.1"
```

The private key is for localhost-only testing and has no production value.
