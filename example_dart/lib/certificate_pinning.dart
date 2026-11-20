import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';

void main() async {
  final dio = Dio();

  // TODO: always update to the latest fingerprint.
  // openssl s_client -servername pinning-test.badssl.com \
  //    -connect pinning-test.badssl.com:443 < /dev/null 2>/dev/null \
  //    | openssl x509 -noout -fingerprint -sha256
  final fingerprint =
      // 'update-with-latest-sha256-hex-ee5ce1dfa7a53657c545c62b65802e4272';
      // should look like this:
      'ee5ce1dfa7a53657c545c62b65802e4272878dabd65c0aadcf85783ebb0b4d5c';

  // Without createHttpClient, validateCertificate is called after the TLS
  // handshake and before the request is sent, so a rejected certificate never
  // receives the request. The default trust store must accept the
  // certificate chain first.
  dio.httpClientAdapter = IOHttpClientAdapter(
    validateCertificate: (cert, host, port) {
      // Check that the cert fingerprint matches the one we expect.
      // We definitely require _some_ certificate.
      if (cert == null) {
        return false;
      }
      // Validate it any way you want. Here we only check that
      // the fingerprint matches the OpenSSL SHA256.
      final f = sha256.convert(cert.der).toString();
      print(f);
      return fingerprint == f;
    },
  );

  // The certificate is trusted and its fingerprint matches.
  final response = await dio.get('https://sha256.badssl.com/');
  print(response.data);

  try {
    // The certificate is trusted, but its fingerprint doesn't match, so the
    // connection is closed before the request is sent.
    await dio.get('https://example.com/');
  } on DioException catch (e) {
    print(e.message);
  }

  try {
    // The certificate doesn't cover this host, so the handshake fails before
    // validateCertificate is called.
    await dio.get('https://wrong.host.badssl.com/');
  } on DioException catch (e) {
    print(e.message);
  }

  dio.close(force: true);
}
