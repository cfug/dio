

# Migration to 4.x

This guide is primarily for users with prior dio 3.x experience who want to learn about the new features and changes in dio 4.x . 

## New Features

1. **Interceptors:** Add  `handler` for Interceptor APIs which can specify the subsequent interceptors processing logic more finely（whether to skip them or not)）
2. Support multiple encoding styles ( `options.listFormat` ) for request `List` parameters.
3. Make keys of request headers be case-insensitive.
4. New API:  `Future<Response> dio.fetch( RequestOptions )`.
5. New API: `RequestOptions options.compose(BaseOptions baseOpt,...)`.

##  Breaking Changes

1. **Null safety support** (Dart >=2.12).

2. **The `Interceptor` APIs signature has changed**.

3. Rename `options.merge` to `options.copyWith`.

4. Rename `DioErrorType` enums from uppercase to camel style.

5. Delete `dio.resolve` and `dio.reject` APIs (use `handler` instead in  interceptors).

6. Class `BaseOptions`  no longer inherits from `Options` class.

7. Change `requestStream` type of `HttpClientAdapter.fetch` from `Stream<List<int>>` to `Stream<Uint8List>`.

8. Download API: Add real uri and redirect information to headers.

   

