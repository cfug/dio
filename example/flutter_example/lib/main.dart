import 'dart:convert';

//import 'package:cookie_jar/cookie_jar.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'http.dart'; // make dio as global top-level variable
import 'routes/request.dart';

// Must be top-level function
_parseAndDecode(String response) {
  return jsonDecode(response);
}

parseJson(String text) {
  return compute(_parseAndDecode, text);
}

void main() {
  // add interceptors
  //dio.interceptors.add(CookieManager(CookieJar()));
  dio.interceptors.add(LogInterceptor());
  //(dio.transformer as DefaultTransformer).jsonDecodeCallback = parseJson;
  dio.options.receiveTimeout = 15000;
//  (dio.httpClientAdapter as DefaultHttpClientAdapter).onHttpClientCreate =
//      (client) {
//    client.findProxy = (uri) {
//      //proxy to my PC(charles)
//      return "PROXY 10.1.10.250:8888";
//    };
//  };
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String _text = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Container(
        padding: EdgeInsets.all(16),
        child: Column(children: [
          RaisedButton(
            child: Text("Request"),
            onPressed: () {
              dio
                  .get<String>(
                      "https://www.thelotent.com/WSVistaWebClient/OData.svc/GetNowShowingSessions?\$format=json&\$filter=CinemaId+eq+%27100%27")
                  .then((r) {
                setState(() {
                  print(r.data);
                  _text = r.data.replaceAll(RegExp(r"\s"), "");
                });
              }).catchError(print);
            },
          ),
          RaisedButton(
            child: Text("Open new page5"),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) {
                return RequestRoute();
              }));
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
