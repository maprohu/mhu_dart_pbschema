part of '../proto_schema.dart';

@Compose()
@Has()
abstract class MapTypeActions<K extends Object, V extends Object>
    implements CollectionTypeActions<Map<K, V>, V>, HasMapKeyTypeActions<K> {}

MapTypeActions<K, V> castMapTypeActions<K extends Object, V extends Object>({
  @ext required MapTypeActions mapTypeActions,
}) {
  return mapTypeActions as MapTypeActions<K, V>;
}

R mapTypeActionsKeyValueGeneric<K extends Object, V extends Object, R>({
  @ext required MapTypeActions<K, V> mapTypeActions,
  required R Function<KK extends Object, VV extends Object>(
    MapTypeActions<KK, VV> mapTypeActions,
  ) fn,
}) {
  return mapTypeActions.mapKeyTypeActions.singleTypeGeneric(
    <KK extends Object>() {
      return mapTypeActions.collectionElementTypeActions.singleTypeGeneric(
        <VV extends Object>() {
          return fn(
            mapTypeActions.castMapTypeActions<KK, VV>(),
          );
        },
      );
    },
  );
}

List<MapEntry<K, V>>
    mapTypeActionsSortedEntries<K extends Object, V extends Object>({
  @ext required MapTypeActions<K, V> mapTypeActions,
  required Map<K, V> mapValue,
}) {
  return mapValue.entries.sortedByCompare(
    (entry) => entry.key,
    mapTypeActions.mapKeyTypeActions.valueComparator,
  );
}
