import 'package:flutter/material.dart';
import '../http.dart';

class RequestRoute extends StatefulWidget {
  @override
  _RequestRouteState createState() => _RequestRouteState();
}

class _RequestRouteState extends State<RequestRoute> {
  String _text="";
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("New Page"),
      ),
      body: Container(
        padding: EdgeInsets.all(16),
        child: Column(children: [
          RaisedButton(
            child: Text("Request"),
            onPressed: () {
              dio.get("https://baidu.com").then((r){
                setState(() {
                  _text=r.data.replaceAll(RegExp(r"\s"), "");
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
