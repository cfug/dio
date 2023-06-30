# Cancel Token

A useful instance builds from `Completer` that helps control the cancellation of `Dio`(s) requests.

You can cancel requests by using a `CancelToken`.
One token can be shared between different requests.
When `cancel` is invoked, all requests using this token will be cancelled.

## Usage

```dart
final cancelToken = CancelToken();
dio.get(url, cancelToken: cancelToken).catchError((DioException ex) {
  if (CancelToken.isCancel(ex)) {
    print('Request canceled: ${ex.message}');
  } else {
    // handle other exceptions.
  }
});
// Cancel the requests with "cancelled" message.
token.cancel('cancelled');
```
