import 'package:diox/diox.dart';

final dio = Dio(BaseOptions(
  connectTimeout: Duration(seconds: 3),
));
