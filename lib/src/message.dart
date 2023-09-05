part of 'proto_schema.dart';

@Has()
typedef LogicalFieldsList = IList<LogicalFieldCtx>;

@Has()
typedef LookupFieldIndex = FieldIndex Function(FieldMsg fieldMsg);

@Has()
typedef LookupFieldByTagNumber = FieldCtx Function(
  TagNumberValue tagNumberValue,
);

@Has()
typedef GenericBuilderInfo = BuilderInfo;

@Has()
typedef EnclosingMessage = MessageCtx?;

@Has()
typedef DefaultGenericMsg = GenericMsg;

@Has()
typedef CreateGenericMsg = CreateValue<GenericMsg>;

@Compose()
@Has()
abstract class MessageCtx
    implements
        SchemaCtx,
        HasCallLogicalFieldsList,
        HasLookupFieldIndex,
        HasLookupFieldByTagNumber,
        HasCallGenericBuilderInfo,
        HasCallEnclosingMessage,
        HasCallDefaultMessage,
        // HasCreateGenericMsg,
        HasReferenceMsg,
        HasMessageMsg,
        HasCallMessageMarker {}

MessageCtx createMessageCtx({
  @ext required SchemaCtx schemaCtx,
  required MessageMsg messageMsg,
  required ReferenceMsg referenceMsg,
  required LookupMessageMarkerByName lookupMessageMarkerByName,
}) {
  late final MessageCtx messageCtx;

  late final messageMarker = lookupMessageMarkerByName(
    messageCtx.messageCtxTypeName(),
  );

  late final fieldMarkersByProtoName = {
    for (final marker in messageMarker.callFieldMarkers())
      marker.fieldProtoName: marker,
  };

  late final oneofMarkersByProtoName = {
    for (final marker in messageMarker.callOneofMarkers())
      marker.fieldProtoName: marker,
  };

  late final fieldCtxByProtoName = {
    for (final fieldMsg in messageMsg.messageMsgFieldsIterable())
      fieldMsg.fieldInfo.description.protoName: createFieldCtx(
        messageCtx: messageCtx,
        fieldMsg: fieldMsg,
        callFieldMarker: lazy(
          () => fieldMarkersByProtoName
              .getOrThrow(fieldMsg.fieldInfo.description.protoName),
        ),
      ),
  };

  late final oneofCtxByProtoName = {
    for (final oneofMsg in messageMsg.messageMsgOneofsIterable())
      oneofMsg.description.protoName: createOneofCtx(
        messageCtx: messageCtx,
        oneofMsg: oneofMsg,
        callOneofMarker: lazy(
          () => oneofMarkersByProtoName
              .getOrThrow(oneofMsg.description.protoName),
        ),
        lookupFieldMarkerByProtoName: (fieldProtoName) =>
            fieldMarkersByProtoName.getOrThrow(fieldProtoName),
      ),
  };

  late final logicalFieldCtxByProtoName = {
    ...fieldCtxByProtoName,
    ...oneofCtxByProtoName,
  };

  late final logicalFieldsList = [
    for (final field in messageMsg.fields)
      logicalFieldCtxByProtoName.getOrThrow(
        field.logicalFieldMsgProtoName(),
      ),
  ].toIList();

  late final tagNumberToIndex = run(() {
    final tagNumbersSorted = messageMsg
        .messageMsgPhysicalFields()
        .map((e) => e.fieldInfo.tagNumber)
        .toList()
      ..sort();

    return {
      for (final (index, tag) in tagNumbersSorted.indexed) tag: index,
    };
  });

  late final builderInfo =
      messageMarker.msgClassActions.createBuilderInfo(messageCtx);

  late final defaultMessage =
      messageMarker.msgClassActions.createDefaultMessage(builderInfo);

  late final fieldCtxByTagNumber = {
    for (final fieldCtx in messageCtx.messageFieldCtxIterable())
      fieldCtx.fieldCtxTagNumber(): fieldCtx,
  };

  return messageCtx = ComposedMessageCtx.schemaCtx(
    schemaCtx: schemaCtx,
    callMessageMarker: () => messageMarker,
    callLogicalFieldsList: () => logicalFieldsList,
    referenceMsg: referenceMsg,
    lookupFieldIndex: (fieldMsg) =>
        tagNumberToIndex[fieldMsg.fieldInfo.tagNumber] ?? (throw fieldMsg),
    callGenericBuilderInfo: () => builderInfo,
    callDefaultMessage: () => defaultMessage,
    callEnclosingMessage: lazy(() {
      if (!messageMsg.hasEnclosingMessage()) {
        return null;
      }
      return messageMsg.enclosingMessage.schemaLookupMessage(
        schemaCtx: schemaCtx,
      );
    }),
    messageMsg: messageMsg,
    lookupFieldByTagNumber: (tagNumberValue) =>
        fieldCtxByTagNumber.getOrThrow(tagNumberValue),
  );
}

Iterable<MessageCtx> messageCtxPath({
  @ext required MessageCtx messageCtx,
}) {
  return messageCtx
      .finiteIterable((item) => item.callEnclosingMessage())
      .toList()
      .reversed;
}

Iterable<MessageCtx> enumCtxMessagePath({
  @ext required EnumCtx enumCtx,
}) sync* {
  final enclosingMessage = enumCtx.callEnclosingMessage();

  if (enclosingMessage != null) {
    yield* enclosingMessage.messageCtxPath();
  }
}

String messageCtxTypeName({
  @ext required MessageCtx messageCtx,
}) {
  return messageCtx
      .messageCtxPath()
      .map((e) => e.messageMsg.description.protoName)
      .join('_');
}

String enumCtxTypeName({
  @ext required EnumCtx enumCtx,
}) {
  return enumCtx
      .enumCtxMessagePath()
      .map((e) => e.messageMsg.description.protoName)
      .followedBy([enumCtx.enumMsg.description.protoName]).join('_');
}

Iterable<FieldMsg> messageMsgPhysicalFields({
  @ext required MessageMsg messageMsg,
}) sync* {
  for (final field in messageMsg.fields) {
    switch (field.whichType()) {
      case MpbLogicalFieldMsg_Type.physicalField:
        yield field.physicalField;
      case MpbLogicalFieldMsg_Type.oneof:
        yield* field.oneof.fields;
      default:
        throw field;
    }
  }
}

Iterable<FieldCtx> messageFieldCtxIterable({
  @ext required MessageCtx messageCtx,
}) sync* {
  for (final logicalFieldCtx in messageCtx.callLogicalFieldsList()) {
    switch (logicalFieldCtx) {
      case FieldCtx():
        yield logicalFieldCtx;
      case OneofCtx():
        yield* logicalFieldCtx.callOneofOptionsList();
    }
  }
}

Iterable<OneofCtx> messageOneofCtxIterable({
  @ext required MessageCtx messageCtx,
}) sync* {
  for (final logicalFieldCtx in messageCtx.callLogicalFieldsList()) {
    switch (logicalFieldCtx) {
      case FieldCtx():
        break;
      case OneofCtx():
        yield logicalFieldCtx;
    }
  }
}
