import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import 'http.dart'; // make dio as global top-level variable
import 'routes/request.dart';

void main() {
  dio.interceptors.add(LogInterceptor());
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
  MyHomePage({
    super.key,
    this.title = '',
  });

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String _text = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ElevatedButton(
              child: const Text('Request'),
              onPressed: () async {
                try {
                  await dio
                      .get<String>('https://httpbin.org/status/404')
                      .then((r) {
                    setState(() {
                      print(r.data);
                      _text = r.data!.replaceAll(RegExp(r'\s'), '');
                    });
                  });
                } catch (e) {
                  print(e);
                }
              },
            ),
            ElevatedButton(
              child: const Text('Open new page5'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) {
                      return RequestRoute();
                    },
                  ),
                );
              },
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Text(_text),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
