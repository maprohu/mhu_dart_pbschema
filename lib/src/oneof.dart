part of 'proto_schema.dart';

@Has()
typedef OneofOptionsList = IList<OneofOptionCtx>;

@Compose()
abstract class OneofCtx
    implements
        MessageCtx,
        LogicalFieldActions,
        HasCallOneofMarker,
        LogicalFieldCtx,
        HasCallOneofOptionsList,
        HasOneofMsg {}

@Compose()
abstract class OneofOptionCtx implements OneofCtx, FieldBits, FieldCtx {}

OneofCtx createOneofCtx({
  @ext required MessageCtx messageCtx,
  required OneofMsg oneofMsg,
  required CallOneofMarker callOneofMarker,
  required LookupFieldMarkerByProtoName lookupFieldMarkerByProtoName,
}) {
  late final OneofCtx oneofCtx;
  late final oneofOptionsList = oneofMsg.fields
      .map(
        (fieldMsg) => createOneofOptionCtx(
          oneofCtx: oneofCtx,
          fieldMsg: fieldMsg,
          fieldBits: createFieldBits(
            messageCtx: messageCtx,
            fieldMsg: fieldMsg,
            callFieldMarker: lazy(
              () => lookupFieldMarkerByProtoName(
                fieldMsg.fieldInfo.description.protoName,
              ),
            ),
          ),
        ),
      )
      .toIList();
  return oneofCtx = ComposedOneofCtx.merge$(
    messageCtx: messageCtx,
    logicalFieldActions: ComposedLogicalFieldActions(
      fieldProtoName: oneofMsg.description.protoName,
    ),
    callOneofOptionsList: () => oneofOptionsList,
    oneofMsg: oneofMsg,
    callOneofMarker: callOneofMarker,
    callLogicalFieldMarker: callOneofMarker,
  );
}

OneofOptionCtx createOneofOptionCtx({
  @ext required OneofCtx oneofCtx,
  @ext required FieldMsg fieldMsg,
  required FieldBits fieldBits,
}) {
  return ComposedOneofOptionCtx.merge$(
    oneofCtx: oneofCtx,
    fieldMsg: fieldMsg,
    fieldBits: fieldBits,
  );
}

void oneofAddToBuilderInfo({
  @extHas required OneofMsg oneofMsg,
  required int oneofIndex,
  @ext required BuilderInfo builderInfo,
}) {
  builderInfo.oo(
    oneofIndex,
    oneofMsg.fields.map((e) => e.fieldInfo.tagNumber).toList()..sort(),
  );
}
