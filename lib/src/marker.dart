part of 'proto_schema.dart';

@Has()
typedef MessageTypeGeneric = GenericFunction1<Msg>;

@Has()
typedef ValueMessageMarker<F extends Msg> = MessageMarker<F>;

@Has()
typedef FieldMarkers<M extends Msg> = List<FieldMarker<M, dynamic>>;

@Has()
typedef OneofMarkers<M extends Msg> = List<OneofMarker<M>>;


typedef LookupFieldMarkerByProtoName<M extends Msg> = FieldMarker<M, dynamic>
    Function(
  FieldProtoName fieldProtoName,
);

typedef LookupOneofMarkerByIndex<M extends Msg> = OneofMarker<M> Function(
  OneofIndex oneofIndex,
);

@Compose()
@Has()
abstract class MessageMarker<M extends Msg>
    implements
        HasMsgClassActions<M>,
        HasMessageTypeGeneric,
        HasCallFieldMarkers<M>,
        HasCallOneofMarkers<M> {}

@Has()
sealed class LogicalFieldMarker<M extends Msg> implements HasFieldProtoName {}

@Has()
sealed class FieldMarker<M extends Msg, F>
    implements LogicalFieldMarker<M>, HasTagNumberValue {}

sealed class SingleFieldMarker<M extends Msg, F>
    implements FieldMarker<M, F?>, ReadWriteAttribute<M, F?> {}

@Compose()
abstract class ScalarFieldMarker<M extends Msg, F>
    implements SingleFieldMarker<M, F> {}

@Compose()
abstract class MessageFieldMarker<M extends Msg, F extends Msg>
    implements SingleFieldMarker<M, F>, HasValueMessageMarker<F> {}

@Compose()
abstract class EnumFieldMarker<M extends Msg, F extends ProtobufEnum>
    implements SingleFieldMarker<M, F> {}

@Compose()
abstract class RepeatedFieldMarker<M extends Msg, F>
    implements FieldMarker<M, List<F>> {}

@Compose()
abstract class MapFieldMarker<M extends Msg, K, V>
    implements FieldMarker<M, Map<K, V>> {}

@Compose()
@Has()
abstract class OneofMarker<M extends Msg>
    implements LogicalFieldMarker<M>, HasOneofIndex {}

@Has()
typedef PackageName = String;

@Has()
typedef PbschemaDependencies = List<Pbschema>;

@Has()
typedef FileDescriptorSetBase64 = String;

@Has()
typedef MessageMarkers = List<MessageMarker>;

@Compose()
abstract class Pbschema
    implements
        HasPackageName,
        HasPbschemaDependencies,
        HasFileDescriptorSetBase64,
        HasMessageMarkers {}

IList<Pbschema> pbschemaFlattenHierarchy({
  @ext required Iterable<Pbschema> pbschemas,
}) {
  final seen = <String>{};
  final list = <Pbschema>[];

  void process(Iterable<Pbschema> pbschemas) {
    for (final pbschema in pbschemas) {
      if (!seen.contains(pbschema.packageName)) {
        seen.add(pbschema.packageName);

        process(pbschema.pbschemaDependencies);
        list.add(pbschema);
      }
    }
  }

  process(pbschemas);

  return list.toIList();
}

FileDescriptorSet pbschemaFileDescriptorSet({
  @ext required Pbschema pbschema,
}) {
  return FileDescriptorSet.fromBuffer(
    base64Decode(pbschema.fileDescriptorSetBase64),
  )..freeze();
}

MessageMarker<M> messageMarker<M extends Msg>({
  required MsgClassActions<M> msgClassActions,
  required CallFieldMarkers<M> callFieldMarkers,
  required CallOneofMarkers<M> callOneofMarkers,
}) {
  return ComposedMessageMarker(
    msgClassActions: msgClassActions,
    messageTypeGeneric: genericFunction1<Msg, M>(),
    callFieldMarkers: callFieldMarkers,
    callOneofMarkers: callOneofMarkers,
  );
}

LogicalFieldMarker<M> castLogicalFieldMarker<M extends Msg>({
  @ext required LogicalFieldMarker logicalFieldMarker,
}) {
  return logicalFieldMarker as LogicalFieldMarker<M>;
}
