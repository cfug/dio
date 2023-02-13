// ignore_for_file: use_build_context_synchronously

import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:native_dio_adapter/native_dio_adapter.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.max,
        children: [
          ElevatedButton(
            onPressed: _doGetRequest,
            child: const Text('make get request'),
          ),
          ElevatedButton(
            onPressed: _doPostRequest,
            child: const Text('make post request'),
          ),
          ElevatedButton(
            onPressed: _doHttpClientRequest,
            child: const Text('make client request'),
          ),
          ElevatedButton(
            onPressed: _doHttpClientPostRequest,
            child: const Text('make client post request'),
          ),
        ],
      ),
    );
  }

  void _doGetRequest() async {
    final dio = Dio();

    dio.httpClientAdapter = NativeAdapter(
      cupertinoConfiguration:
          URLSessionConfiguration.ephemeralSessionConfiguration()
            ..allowsCellularAccess = false
            ..allowsConstrainedNetworkAccess = false
            ..allowsExpensiveNetworkAccess = false,
    );
    final response = await dio.get<String>('https://flutter.dev');

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Response ${response.statusCode}'),
          content: SingleChildScrollView(
            child: Text(response.data ?? 'No response'),
          ),
          actions: [
            MaterialButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            )
          ],
        );
      },
    );
  }

  void _doPostRequest() async {
    final dio = Dio();

    dio.httpClientAdapter = NativeAdapter(
      cupertinoConfiguration:
          URLSessionConfiguration.ephemeralSessionConfiguration()
            ..allowsCellularAccess = false
            ..allowsConstrainedNetworkAccess = false
            ..allowsExpensiveNetworkAccess = false,
    );
    final response = await dio.post<String>(
      'https://httpbin.org/post',
      queryParameters: <String, dynamic>{'foo': 'bar'},
      data: jsonEncode(<String, dynamic>{'foo': 'bar'}),
      options: Options(headers: <String, dynamic>{'foo': 'bar'}),
    );

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Response ${response.statusCode}'),
          content: SingleChildScrollView(
            child: Text(response.data ?? 'No response'),
          ),
          actions: [
            MaterialButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            )
          ],
        );
      },
    );
  }

  void _doHttpClientRequest() async {
    final config = URLSessionConfiguration.ephemeralSessionConfiguration()
      ..allowsCellularAccess = false
      ..allowsConstrainedNetworkAccess = false
      ..allowsExpensiveNetworkAccess = false;
    final client = CupertinoClient.fromSessionConfiguration(config);
    final response = await client.get(Uri.parse('https://flutter.dev/'));
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Response ${response.statusCode}'),
          content: SingleChildScrollView(
            child: Text(response.body),
          ),
          actions: [
            MaterialButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            )
          ],
        );
      },
    );
  }

  void _doHttpClientPostRequest() async {
    final config = URLSessionConfiguration.ephemeralSessionConfiguration()
      ..allowsCellularAccess = false
      ..allowsConstrainedNetworkAccess = false
      ..allowsExpensiveNetworkAccess = false;
    final client = CupertinoClient.fromSessionConfiguration(config);

    final response = await client.post(
      Uri.parse('https://httpbin.org/post'),
      body: jsonEncode(<String, dynamic>{'foo': 'bar'}),
    );

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Response ${response.statusCode}'),
          content: SingleChildScrollView(
            child: Text(response.body),
          ),
          actions: [
            MaterialButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            )
          ],
        );
      },
    );
  }
}
