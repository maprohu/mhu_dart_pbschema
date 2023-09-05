part of 'proto_schema.dart';

// @Has()
// sealed class FieldActions {}

@Compose()
abstract class FieldBits
    implements HasCallFieldCoordinates, HasCallFieldMarker, HasTypeActions {}

@Has()
@Compose()
abstract class FieldCtx
    implements
        MessageCtx,
        LogicalFieldActions,
        FieldBits,
        LogicalFieldCtx,
        HasFieldMsg {}

FieldCtx createFieldCtx({
  required MessageCtx messageCtx,
  required FieldMsg fieldMsg,
  required CallFieldMarker callFieldMarker,
}) {
  return ComposedFieldCtx.merge$(
    messageCtx: messageCtx,
    fieldMsg: fieldMsg,
    logicalFieldActions: ComposedLogicalFieldActions(
      fieldProtoName: fieldMsg.fieldInfo.description.protoName,
    ),
    fieldBits: createFieldBits(
      messageCtx: messageCtx,
      fieldMsg: fieldMsg,
      callFieldMarker: callFieldMarker,
    ),
    callLogicalFieldMarker: callFieldMarker,
  );
}

FieldBits createFieldBits({
  required MessageCtx messageCtx,
  required FieldMsg fieldMsg,
  required CallFieldMarker callFieldMarker,
}) {
  return ComposedFieldBits(
    typeActions: fieldMsg.fieldMsgTypeActions(
      messageCtx: messageCtx,
    ),
    callFieldCoordinates: lazy(
      () => ComposedFieldCoordinates(
        fieldIndex: messageCtx.lookupFieldIndex(fieldMsg),
        tagNumberValue: fieldMsg.fieldInfo.tagNumber,
      ),
    ),
    callFieldMarker: callFieldMarker,
  );
}

TagNumberValue fieldCtxTagNumber({
  @ext required FieldCtx fieldCtx,
}) {
  return fieldCtx.fieldMsg.fieldInfo.tagNumber;
}

String fieldCtxJsonName({
  @ext required FieldCtx fieldCtx,
}) {
  return fieldCtx.fieldMsg.fieldInfo.description.jsonName;
}
