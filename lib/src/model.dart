part of 'proto_schema.dart';

Iterable<MpbFieldMsg> messageMsgFieldsIterable({
  @ext required MpbMessageMsg messageMsg,
}) sync* {
  for (final field in messageMsg.fields) {
    switch (field.whichType()) {
      case MpbLogicalFieldMsg_Type.physicalField:
        yield field.physicalField;
      case MpbLogicalFieldMsg_Type.oneof:
        for (final option in field.oneof.fields) {
          yield option;
        }
      case MpbLogicalFieldMsg_Type.notSet:
        throw messageMsg;
    }
  }
}

Iterable<MpbOneofMsg> messageMsgOneofsIterable({
  @ext required MpbMessageMsg messageMsg,
}) sync* {
  for (final field in messageMsg.fields) {
    switch (field.whichType()) {
      case MpbLogicalFieldMsg_Type.oneof:
        yield field.oneof;
      case MpbLogicalFieldMsg_Type.physicalField:
        break;
      case MpbLogicalFieldMsg_Type.notSet:
        throw messageMsg;
    }
  }
}

FieldProtoName logicalFieldMsgProtoName({
  @ext required MpbLogicalFieldMsg logicalFieldMsg,
}) {
  return logicalFieldMsg.logicalFieldMsgDescription().protoName;
}

MpbDescriptionMsg logicalFieldMsgDescription({
  @ext required MpbLogicalFieldMsg logicalFieldMsg,
}) {
  switch (logicalFieldMsg.whichType()) {
    case MpbLogicalFieldMsg_Type.oneof:
      return logicalFieldMsg.oneof.description;
    case MpbLogicalFieldMsg_Type.physicalField:
      return logicalFieldMsg.physicalField.fieldInfo.description;
    case MpbLogicalFieldMsg_Type.notSet:
      throw logicalFieldMsg;
  }
}
