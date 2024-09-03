import 'dart:async';
import 'dart:typed_data';

/// A [StreamTransformer] that replaces an empty stream of Uint8List with a default value
/// - the utf8-encoded string "null".
/// Feeding an empty stream to a JSON decoder will throw an exception, so this transformer
/// is used to prevent that; the JSON decoder will instead return null.
class DefaultNullIfEmptyStreamTransformer
    extends StreamTransformerBase<Uint8List, Uint8List> {
  const DefaultNullIfEmptyStreamTransformer();

  @override
  Stream<Uint8List> bind(Stream<Uint8List> stream) {
    return Stream.eventTransformed(
      stream,
      (sink) => _DefaultIfEmptyStreamSink(sink),
    );
  }
}

class _DefaultIfEmptyStreamSink implements EventSink<Uint8List> {
  _DefaultIfEmptyStreamSink(this._outputSink);

  /// Hard-coded constant for replacement value, "null"
  static final Uint8List _nullUtf8Value =
      Uint8List.fromList(const [110, 117, 108, 108]);

  final EventSink<Uint8List> _outputSink;
  bool _hasData = false;

  @override
  void add(Uint8List data) {
    _hasData = _hasData || data.isNotEmpty;
    _outputSink.add(data);
  }

  @override
  void addError(e, [st]) => _outputSink.addError(e, st);

  @override
  void close() {
    if (!_hasData) {
      _outputSink.add(_nullUtf8Value);
    }

    _outputSink.close();
  }
}
