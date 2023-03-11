import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../http.dart';

class RequestRoute extends StatefulWidget {
  @override
  State<RequestRoute> createState() => _RequestRouteState();
}

class _RequestRouteState extends State<RequestRoute> {
  String _text = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('New Page'),
      ),
      body: Container(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            ElevatedButton(
              child: Text('get'),
              onPressed: () {
                dio.get<String>('https://httpbin.org/get').then((r) {
                  setState(() {
                    _text = r.data!;
                  });
                });
              },
            ),
            ElevatedButton(
              child: Text('post'),
              onPressed: () {
                final formData = FormData.fromMap({
                  'file': MultipartFile.fromString('x' * 1024 * 1024),
                });

                dio
                    .post(
                  'https://httpbin.org/post',
                  data: formData,
                  options: Options(
                    sendTimeout: Duration(seconds: 2),
                    receiveTimeout: Duration(seconds: 0),
                  ),
                  onSendProgress: (a, b) => print('send ${a / b}'),
                  onReceiveProgress: (a, b) => print('received ${a / b}'),
                )
                    .then((r) {
                  setState(() {
                    _text = r.headers.toString();
                  });
                });
              },
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Text(_text),
              ),
            )
          ],
        ),
      ),
    );
  }
}
