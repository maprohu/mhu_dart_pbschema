part of 'proto_schema.dart';

@Has()
typedef CreateBuilderInfo = BuilderInfo Function(MessageCtx messageCtx);

@Has()
typedef CreateDefaultMessage<M extends Msg> = M Function(
    BuilderInfo builderInfo);

class GenericMsg extends Msg {
  GenericMsg({
    required BuilderInfo info,
  }) : info_ = info;

  @override
  GenericMsg clone() => GenericMsg(info: info_)..mergeFromMessage(this);

  @override
  GenericMsg createEmptyInstance() => GenericMsg(info: info_);

  @override
  final BuilderInfo info_;
}

GenericMsg createGenericMsg({
  @ext required MessageCtx messageCtx,
}) {
  return GenericMsg(
    info: messageCtx.callGenericBuilderInfo(),
  );
}

@Compose()
@Has()
abstract class MsgClassActions<M extends Msg>
    implements HasCreateBuilderInfo, HasCreateDefaultMessage<M> {}

MsgClassActions<M> staticMsgClassActions<M extends Msg>({
  @ext required M defaultMessage,
}) {
  return ComposedMsgClassActions(
    createBuilderInfo: (messageCtx) => defaultMessage.info_,
    createDefaultMessage: (_) => defaultMessage,
  );
}

final dynamicMsgClassActions = ComposedMsgClassActions<GenericMsg>(
  createBuilderInfo: (messageCtx) => messageCtx.createDynamicBuilderInfo(),
  createDefaultMessage: (builderInfo) =>
      GenericMsg(info: builderInfo)..freeze(),
);

BuilderInfo createDynamicBuilderInfo({
  @ext required MessageCtx messageCtx,
}) {
  final builderInfo = BuilderInfo(
    messageCtx
        .messageCtxPath()
        .map((e) => e.messageMsg.description.protoName)
        .join("."),
    createEmptyInstance: messageCtx.createGenericMsg,
  )..hasRequiredFields = false;

  messageCtx.callLogicalFieldsList().whereType<OneofCtx>().forEachIndexed(
    (index, oneofCtx) {
      oneofCtx.oneofAddToBuilderInfo(
        builderInfo: builderInfo,
        oneofIndex: index,
      );
    },
  );

  final fields = messageCtx
      .messageFieldCtxIterable()
      .sortedBy<num>((e) => e.fieldCtxTagNumber());

  for (final fieldCtx in fields) {
    fieldCtx.fieldCtxAddBuilderInfoField(
      builderInfo: builderInfo,
    );
  }

  return builderInfo;
}
