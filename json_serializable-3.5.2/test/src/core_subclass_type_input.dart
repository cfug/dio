part of '_json_serializable_test_input.dart';

@ShouldThrow(
  '''
Could not generate `fromJson` code for `mapView`.
To support the type `MapView` you can:
$converterOrKeyInstructions''',
  element: 'mapView',
)
@JsonSerializable(createToJson: false)
class UnsupportedMapField {
  MapView mapView;
}

@ShouldThrow(
  '''
Could not generate `fromJson` code for `listView`.
To support the type `UnmodifiableListView` you can:
$converterOrKeyInstructions''',
  element: 'listView',
)
@JsonSerializable(createToJson: false)
class UnsupportedListField {
  UnmodifiableListView listView;
}

@ShouldThrow(
  '''
Could not generate `fromJson` code for `customSet`.
To support the type `_CustomSet` you can:
$converterOrKeyInstructions''',
  element: 'customSet',
)
@JsonSerializable(createToJson: false)
class UnsupportedSetField {
  _CustomSet customSet;
}

abstract class _CustomSet implements Set {}

@ShouldThrow(
  '''
Could not generate `fromJson` code for `customDuration`.
To support the type `_CustomDuration` you can:
$converterOrKeyInstructions''',
  element: 'customDuration',
)
@JsonSerializable(createToJson: false)
class UnsupportedDurationField {
  _CustomDuration customDuration;
}

abstract class _CustomDuration implements Duration {}

@ShouldThrow(
  '''
Could not generate `fromJson` code for `customUri`.
To support the type `_CustomUri` you can:
$converterOrKeyInstructions''',
  element: 'customUri',
)
@JsonSerializable(createToJson: false)
class UnsupportedUriField {
  _CustomUri customUri;
}

abstract class _CustomUri implements Uri {}

@ShouldThrow(
  '''
Could not generate `fromJson` code for `customDateTime`.
To support the type `_CustomDateTime` you can:
$converterOrKeyInstructions''',
  element: 'customDateTime',
)
@JsonSerializable(createToJson: false)
class UnsupportedDateTimeField {
  _CustomDateTime customDateTime;
}

abstract class _CustomDateTime implements DateTime {}
