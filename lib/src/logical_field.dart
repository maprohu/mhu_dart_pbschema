part of 'proto_schema.dart';

@Has()
typedef FieldProtoName = String;

@Has()
typedef LogicalFieldIndex = int;

// @Has()
// typedef ReadLogicalField<F> = ReadAttribute<Msg, F>;

@Compose()
abstract class LogicalFieldActions<F> implements HasFieldProtoName {}

@Has()
sealed class LogicalFieldCtx
    implements LogicalFieldActions, MessageCtx, HasCallLogicalFieldMarker {}

// LogicalFieldCtx createLogicalFieldCtx({
//   @ext required MessageCtx messageCtx,
//   @ext required LogicalFieldMsg logicalFieldMsg,
//   required LogicalFieldIndex logicalFieldIndex,
// }) {
//   return switch (logicalFieldMsg.whichType()) {
//     MpbLogicalFieldMsg_Type.oneof => createOneofCtx(
//         messageCtx: messageCtx,
//         oneofMsg: logicalFieldMsg.oneof,
//         logicalFieldIndex: logicalFieldIndex,
//       ),
//     MpbLogicalFieldMsg_Type.physicalField => createFieldCtx(
//         messageCtx: messageCtx,
//         fieldMsg: logicalFieldMsg.physicalField,
//       ),
//     MpbLogicalFieldMsg_Type.notSet => throw logicalFieldMsg,
//   };
// }
