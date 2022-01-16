import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../http.dart';

class RequestRoute extends StatefulWidget {
  @override
  _RequestRouteState createState() => _RequestRouteState();
}

class _RequestRouteState extends State<RequestRoute> {
  String _text = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("New Page"),
      ),
      body: Container(
        padding: EdgeInsets.all(16),
        child: Column(children: [
          ElevatedButton(
            child: Text("get"),
            onPressed: () {
              dio.get<String>("http://httpbin.org/get").then((r) {
                setState(() {
                  _text = r.data!;
                });
              });
            },
          ),
          ElevatedButton(
            child: Text("post"),
            onPressed: () {
              var formData = FormData.fromMap({
                'file': MultipartFile.fromString('x' * 1024 * 1024),
              });

              dio
                  .post(
                "http://httpbin.org/post",
                data: formData,
                options: Options(),
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
        ]),
      ),
    );
  }
}
