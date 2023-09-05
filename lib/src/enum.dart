part of 'proto_schema.dart';

typedef EnumValueEntry = MapEntry<int, MpbEnumValueMsg>;

@Has()
typedef LookupEnumValue = Lookup<EnumValueEntry, ProtobufEnum>;

@Compose()
@Has()
abstract class EnumCtx
    implements HasEnumMsg, HasLookupEnumValue, HasCallEnclosingMessage {}

EnumCtx createEnumCtx({
  @ext required EnumMsg enumMsg,
  required CallEnclosingMessage callEnclosingMessage,
}) {
  final enumValueCache = Cache<EnumValueEntry, ProtobufEnum>(
    (key) => ProtobufEnum(
      key.key,
      key.value.description.protoName,
    ),
  );
  return ComposedEnumCtx(
    enumMsg: enumMsg,
    lookupEnumValue: enumValueCache.get,
    callEnclosingMessage: callEnclosingMessage,
  );
}
