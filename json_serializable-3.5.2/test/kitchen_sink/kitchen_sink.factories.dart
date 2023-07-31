import 'kitchen_sink.dart' as normal;
import 'kitchen_sink.g_any_map.dart' as any_map;
import 'kitchen_sink.g_any_map__checked__non_nullable.dart'
    as any_map__checked__non_nullable;
import 'kitchen_sink.g_any_map__non_nullable.dart' as any_map__non_nullable;
import 'kitchen_sink.g_exclude_null.dart' as exclude_null;
import 'kitchen_sink.g_exclude_null__non_nullable.dart'
    as exclude_null__non_nullable;
import 'kitchen_sink.g_explicit_to_json.dart' as explicit_to_json;
import 'kitchen_sink.g_non_nullable.dart' as non_nullable;

const factories = [
  normal.factory,
  any_map.factory,
  any_map__checked__non_nullable.factory,
  any_map__non_nullable.factory,
  exclude_null.factory,
  exclude_null__non_nullable.factory,
  explicit_to_json.factory,
  non_nullable.factory,
];
