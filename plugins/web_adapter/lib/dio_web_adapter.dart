library dio_web_adapter;

export 'src/html/adapter.dart'
    if (dart.library.js_interop) 'src/js_interop/adapter.dart';
export 'src/html/compute.dart'
    if (dart.library.js_interop) 'src/js_interop/compute.dart';
export 'src/html/dio_impl.dart'
    if (dart.library.js_interop) 'src/js_interop/dio_impl.dart';
export 'src/html/multipart_file.dart'
    if (dart.library.js_interop) 'src/js_interop/multipart_file.dart';
export 'src/html/progress_stream.dart'
    if (dart.library.js_interop) 'src/js_interop/progress_stream.dart';
