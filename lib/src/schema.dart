part of 'proto_schema.dart';

@Has()
typedef LookupMessage = Lookup<MpbReferenceMsg, MessageCtx>;

@Has()
typedef LookupEnum = Lookup<MpbReferenceMsg, EnumCtx>;

@Compose()
@Has()
abstract class SchemaCtx implements HasLookupEnum, HasLookupMessage {}

@Has()
typedef RegisterMessage = Future<MessageCtx> Function(
  ReferenceMsg referenceMsg,
);

@Compose()
abstract class SchemaBuilder implements HasSchemaCtx, HasRegisterMessage {}

@Has()
typedef LookupMessageMarkerByName = MessageMarker Function(
  String messageClassName,
);

@Has()
typedef LookupMessageCtxByName = MessageCtx Function(
  String messageClassName,
);

@Has()
typedef LookupEnumCtxByName = EnumCtx Function(
  String enumClassName,
);

@Compose()
@Has()
abstract class SchemaLookupByName
    implements HasLookupMessageCtxByName, HasLookupMessageMarkerByName {}

SchemaBuilder createSchemaBuilder({
  @ext required ResolveCtx resolveCtx,
  required LookupMessageMarkerByName lookupMessageMarkerByName,
}) {
  final enumLookup = <ReferenceMsg, EnumCtx>{};
  final messageLookup = <ReferenceMsg, MessageCtx>{};

  final schemaCtx = ComposedSchemaCtx(
    lookupEnum: enumLookup.getOrThrow,
    lookupMessage: messageLookup.getOrThrow,
  );

  Future<MessageCtx> processMessage({
    required ReferenceMsg referenceMsg,
  }) async {
    Future<EnumCtx> processEnum({
      required ReferenceMsg referenceMsg,
    }) async {
      final existing = enumLookup[referenceMsg];

      if (existing != null) {
        return existing;
      }

      final enumMsg = await resolveCtx.resolveEnumMsg(
        referenceMsg: referenceMsg,
      );

      late final MessageCtx? enclosingMessage;

      final enumCtx = enumMsg.createEnumCtx(
        callEnclosingMessage: () => enclosingMessage,
      );

      enumLookup[referenceMsg] = enumCtx;

      if (enumMsg.hasEnclosingMessage()) {
        enclosingMessage = await processMessage(
          referenceMsg: enumMsg.enclosingMessage,
        );
      } else {
        enclosingMessage = null;
      }

      return enumCtx;
    }

    final existing = messageLookup[referenceMsg];

    if (existing != null) {
      return existing;
    }

    final messageMsg = await resolveCtx.resolveMessageMsg(
      referenceMsg: referenceMsg,
    );

    final messageCtx = createMessageCtx(
      schemaCtx: schemaCtx,
      messageMsg: messageMsg,
      referenceMsg: referenceMsg,
      lookupMessageMarkerByName: lookupMessageMarkerByName,
    );

    messageLookup[referenceMsg] = messageCtx;

    Iterable<Future> processSingleType({
      required MpbSingleTypeMsg singleTypeMsg,
    }) sync* {
      switch (singleTypeMsg.whichType()) {
        case MpbSingleTypeMsg_Type.messageType:
          yield processMessage(referenceMsg: singleTypeMsg.messageType);
        case MpbSingleTypeMsg_Type.enumType:
          yield processEnum(referenceMsg: singleTypeMsg.enumType);
        default:
      }
    }

    Iterable<Future> processPhysicalField(
      FieldMsg fieldMsg,
    ) sync* {
      switch (fieldMsg.whichType()) {
        case MpbFieldMsg_Type.singleType:
          yield* processSingleType(singleTypeMsg: fieldMsg.singleType);
        case MpbFieldMsg_Type.repeatedType:
          yield* processSingleType(
              singleTypeMsg: fieldMsg.repeatedType.singleType);
        case MpbFieldMsg_Type.mapType:
          yield* processSingleType(singleTypeMsg: fieldMsg.mapType.valueType);
        default:
          throw fieldMsg;
      }
    }

    await Future.wait([
      ...messageMsg.messageMsgPhysicalFields().expand(processPhysicalField),
      if (messageMsg.hasEnclosingMessage())
        processMessage(referenceMsg: messageMsg.enclosingMessage),
    ]);

    return messageCtx;
  }

  return ComposedSchemaBuilder(
    schemaCtx: schemaCtx,
    registerMessage: (referenceMsg) async {
      return await processMessage(
        referenceMsg: referenceMsg,
      );
    },
  );
}

MessageCtx schemaLookupMessage({
  @ext required SchemaCtx schemaCtx,
  @ext required ReferenceMsg referenceMsg,
}) {
  return schemaCtx.lookupMessage(referenceMsg);
}

EnumCtx schemaLookupEnum({
  @ext required SchemaCtx schemaCtx,
  @ext required ReferenceMsg referenceMsg,
}) {
  return schemaCtx.lookupEnum(referenceMsg);
}
