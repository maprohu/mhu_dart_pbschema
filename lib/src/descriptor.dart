part of 'proto_schema.dart';

typedef PbTypes = FieldDescriptorProto_Type;
typedef MapKeyTypes = MpbMapTypeMsg_KeyTypeEnm;
typedef ScalarTypes = MpbScalarTypeEnm;

@Has()
typedef ScalarTypeEnm = MpbScalarTypeEnm;

typedef TypePath = IList<String>;
typedef TypeCoordinates = ({String fileName, TypePath typePath});
typedef MessagePath = (FileDescriptorProto, DescriptorProto);
typedef EnumDescriptorCoordinates = (FileDescriptorProto, DescriptorProto);

TypePath typeNamePath({
  @ext required String typeName,
}) {
  final path = typeName.split('.');
  assert(path.first == '');
  return path.skip(1).toIList();
}

typedef ResolvedMessage = ({
  FileDescriptorProto fileDescriptor,
  DescriptorProto messageDescriptor,
});
typedef ResolvedEnum = ({
  FileDescriptorProto fileDescriptor,
  EnumDescriptorProto enumDescriptor,
});

typedef ReferencedMsg<M extends Msg> = ({
  ReferenceMsg reference,
  M msg,
});

@Has()
typedef ReferencedMessages = IList<ReferencedMsg<MessageMsg>>;
@Has()
typedef ReferencedEnums = IList<ReferencedMsg<EnumMsg>>;

@Compose()
abstract class SchemaCollection
    implements ResolveCtx, HasReferencedMessages, HasReferencedEnums {}

typedef CreateTypeReference = ReferenceMsg Function(
  TypeCoordinates typeCoordinates,
);

typedef ReferenceSequence = Call<int>;

ReferenceSequence memoryReferenceSequence({
  final int startAt = 0,
}) {
  var nextSequenceNumber = startAt;
  return () => nextSequenceNumber++;
}

CreateTypeReference memoryCreateTypeReference({
  ReferenceSequence? referenceSequence,
}) {
  final effectiveReferenceSequence =
      referenceSequence ?? memoryReferenceSequence();

  final references = <TypeCoordinates, ReferenceMsg>{};

  return (typeCoordinates) {
    return references.putIfAbsent(
      typeCoordinates,
      () => MpbReferenceMsg()
        ..referencePath.add(
          Int64(
            effectiveReferenceSequence(),
          ),
        )
        ..freeze(),
    );
  };
}

Future<SchemaCtx> schemaCollectionBuildCtx({
  @ext required SchemaCollection schemaCollection,
  required LookupMessageMarkerByName lookupMessageMarkerByName,
}) async {
  final schemaBuilder = schemaCollection.createSchemaBuilder(
    lookupMessageMarkerByName: lookupMessageMarkerByName,
  );

  for (final message in schemaCollection.referencedMessages) {
    await schemaBuilder.registerMessage(message.reference);
  }

  return schemaBuilder.schemaCtx;
}

Iterable<MessageCtx> schemaCollectionMessageCtxIterable({
  @ext required SchemaCollection schemaCollection,
  @ext required SchemaCtx schemaCtx,
}) {
  return schemaCollection.referencedMessages.map(
    (e) => schemaCtx.lookupMessage(e.reference),
  );
}

Future<SchemaLookupByName> descriptorSchemaLookupByName({
  @ext required FileDescriptorSet fileDescriptorSet,
  required LookupMessageMarkerByName lookupMessageMarkerByName,
  required Iterable<Pbschema> dependencies,
}) async {
  final schemaCollection = fileDescriptorSet.descriptorSchemaCollection(
    messageReference: memoryCreateTypeReference(),
    dependencies: dependencies,
  );

  final schemaCtx = await schemaCollection.schemaCollectionBuildCtx(
    lookupMessageMarkerByName: lookupMessageMarkerByName,
  );

  final messageCtxIterable =
      schemaCollection.schemaCollectionMessageCtxIterable(
    schemaCtx: schemaCtx,
  );

  final messageCtxByTypeName = {
    for (final messageCtx in messageCtxIterable)
      messageCtx.messageCtxTypeName(): messageCtx,
  };

  return ComposedSchemaLookupByName(
    lookupMessageCtxByName: messageCtxByTypeName.getOrThrow,
    lookupMessageMarkerByName: lookupMessageMarkerByName,
  );
}

Future<SchemaLookupByName> pbschemaLookupByName({
  @ext required Pbschema pbshcema,
  required Iterable<Pbschema> dependencies,
}) async {
  late final lookupMessageMarkerByNameMap = {
    for (final messageMarker in pbshcema.messageMarkers)
      messageMarker.messageTypeGeneric.genericFunctionTypeName(): messageMarker,
  };

  MessageMarker lookupMessageMarkerByName(messageClassName) {
    return lookupMessageMarkerByNameMap.getOrThrow(messageClassName);
  }

  return pbshcema.pbschemaFileDescriptorSet().descriptorSchemaLookupByName(
        lookupMessageMarkerByName: lookupMessageMarkerByName,
        dependencies: dependencies,
      );
}

MessageCtx lookupMessageCtxOfType<M extends Msg>({
  @ext required SchemaLookupByName schemaLookupByName,
}) {
  return schemaLookupByName.lookupMessageCtxByName(
    M.toString(),
  );
}

SchemaCollection descriptorSchemaCollection({
  @ext required FileDescriptorSet fileDescriptorSet,
  required CreateTypeReference messageReference,
  CreateTypeReference? enumReference,
  required Iterable<Pbschema> dependencies,
}) {
  final effectiveEnumReference = enumReference ?? messageReference;

  final flatDependencies = dependencies.pbschemaFlattenHierarchy();

  final dependencyFileDescriptors = [
    for (final dep in flatDependencies) ...dep.pbschemaFileDescriptorSet().file,
  ];
  final allFileDescriptors = [
    ...fileDescriptorSet.file,
    ...dependencyFileDescriptors,
  ];

  ResolvedEnum resolveEnum(String typeName) {
    final path = typeName.typeNamePath();

    EnumDescriptorProto? resolve({
      required List<DescriptorProto> messageDescriptors,
      required List<EnumDescriptorProto> enumDescriptors,
      required TypePath typePath,
    }) {
      final singleName = typePath.singleOrNull;

      if (singleName != null) {
        final result =
            enumDescriptors.where((e) => e.name == singleName).toList();
        switch (result) {
          case [final single]:
            return single;
          default:
            return null;
        }
      }

      final name = typePath.first;
      final messageDescriptor = messageDescriptors
          .where(
            (e) => e.name == name,
          )
          .firstOrNull;

      if (messageDescriptor == null) {
        return null;
      }

      final rest = typePath.sublist(1);

      assert(rest.isNotEmpty);

      return resolve(
        messageDescriptors: messageDescriptor.nestedType,
        enumDescriptors: messageDescriptor.enumType,
        typePath: rest,
      );
    }

    for (final fileDescriptor in allFileDescriptors) {
      final enumDescriptor = resolve(
        messageDescriptors: fileDescriptor.messageType,
        enumDescriptors: fileDescriptor.enumType,
        typePath: path,
      );

      if (enumDescriptor != null) {
        return (
          fileDescriptor: fileDescriptor,
          enumDescriptor: enumDescriptor,
        );
      }
    }

    throw typeName;
  }

  ResolvedMessage resolveMessage(String typeName) {
    final path = typeName.typeNamePath();

    DescriptorProto? resolve({
      required List<DescriptorProto> messageDescriptors,
      required TypePath typePath,
    }) {
      final name = typePath.first;
      final messageDescriptor = messageDescriptors
          .where(
            (e) => e.name == name,
          )
          .firstOrNull;

      if (messageDescriptor == null) {
        return null;
      }

      final rest = typePath.sublist(1);

      if (rest.isEmpty) {
        return messageDescriptor;
      } else {
        return resolve(
          messageDescriptors: messageDescriptor.nestedType,
          typePath: rest,
        );
      }
    }

    for (final fileDescriptor in allFileDescriptors) {
      final messageDescriptor = resolve(
        messageDescriptors: fileDescriptor.messageType,
        typePath: path,
      );

      if (messageDescriptor != null) {
        return (
          fileDescriptor: fileDescriptor,
          messageDescriptor: messageDescriptor,
        );
      }
    }

    throw typeName;
  }

  ReferenceMsg enumReferenceFor(String typeName) {
    final resolved = resolveEnum(typeName);

    return messageReference(
      (
        fileName: resolved.fileDescriptor.name,
        typePath: typeName.typeNamePath(),
      ),
    );
  }

  ReferenceMsg messageReferenceFor(String typeName) {
    final resolved = resolveMessage(typeName);

    return messageReference(
      (
        fileName: resolved.fileDescriptor.name,
        typePath: typeName.typeNamePath(),
      ),
    );
  }

  final resolveLookup = <ReferenceMsg, Bytes>{};

  final enums = <ReferencedMsg<EnumMsg>>[];
  final messages = <ReferencedMsg<MessageMsg>>[];

  void processFileDescriptor({
    required FileDescriptorProto fileDescriptor,
    required bool collect,
  }) {
    MessageMsg createMessageMsg({
      required DescriptorProto messageDescriptor,
      required MpbReferenceMsg? enclosingMessage,
    }) {
      Iterable<MpbLogicalFieldMsg> logicalFields() sync* {
        final oneofIndicesEmitted = <int>{};

        MpbFieldMsg descriptorToFieldMsg(FieldDescriptorProto fieldDescriptor) {
          final fieldMsg = MpbFieldMsg()
            ..fieldInfo = (MpbFieldInfoMsg()
              ..description = (MpbDescriptionMsg()
                ..protoName = fieldDescriptor.name
                ..jsonName = fieldDescriptor.jsonName)
              ..tagNumber = fieldDescriptor.number);

          MpbSingleTypeMsg singleTypeMsg(
            FieldDescriptorProto fieldDescriptor,
          ) {
            final msg = MpbSingleTypeMsg();
            final scalarType = switch (fieldDescriptor.type) {
              PbTypes.TYPE_DOUBLE => ScalarTypes.TYPE_DOUBLE,
              PbTypes.TYPE_FLOAT => ScalarTypes.TYPE_FLOAT,
              PbTypes.TYPE_INT32 => ScalarTypes.TYPE_INT32,
              PbTypes.TYPE_INT64 => ScalarTypes.TYPE_INT64,
              PbTypes.TYPE_UINT32 => ScalarTypes.TYPE_UINT32,
              PbTypes.TYPE_UINT64 => ScalarTypes.TYPE_UINT64,
              PbTypes.TYPE_SINT32 => ScalarTypes.TYPE_SINT32,
              PbTypes.TYPE_SINT64 => ScalarTypes.TYPE_SINT64,
              PbTypes.TYPE_FIXED32 => ScalarTypes.TYPE_FIXED32,
              PbTypes.TYPE_FIXED64 => ScalarTypes.TYPE_FIXED64,
              PbTypes.TYPE_SFIXED32 => ScalarTypes.TYPE_SFIXED32,
              PbTypes.TYPE_SFIXED64 => ScalarTypes.TYPE_SFIXED64,
              PbTypes.TYPE_BOOL => ScalarTypes.TYPE_BOOL,
              PbTypes.TYPE_STRING => ScalarTypes.TYPE_STRING,
              PbTypes.TYPE_BYTES => ScalarTypes.TYPE_BYTES,
              _ => null,
            };

            if (scalarType != null) {
              msg.scalarType = scalarType;
            } else {
              switch (fieldDescriptor.type) {
                case PbTypes.TYPE_ENUM:
                  msg.enumType = enumReferenceFor(
                    fieldDescriptor.typeName,
                  );
                case PbTypes.TYPE_MESSAGE:
                  msg.messageType = messageReferenceFor(
                    fieldDescriptor.typeName,
                  );
                default:
                  throw fieldDescriptor;
              }
            }

            return msg..freeze();
          }

          void mapField(DescriptorProto mapEntryDescriptor) {
            final [
              keyFieldDescriptor,
              valueFieldDescriptor,
            ] = mapEntryDescriptor.field;

            fieldMsg.mapType = MpbMapTypeMsg()
              ..keyType = switch (keyFieldDescriptor.type) {
                PbTypes.TYPE_INT32 => MapKeyTypes.TYPE_INT32,
                PbTypes.TYPE_INT64 => MapKeyTypes.TYPE_INT64,
                PbTypes.TYPE_UINT32 => MapKeyTypes.TYPE_UINT32,
                PbTypes.TYPE_UINT64 => MapKeyTypes.TYPE_UINT64,
                PbTypes.TYPE_SINT32 => MapKeyTypes.TYPE_SINT32,
                PbTypes.TYPE_SINT64 => MapKeyTypes.TYPE_SINT64,
                PbTypes.TYPE_FIXED32 => MapKeyTypes.TYPE_FIXED32,
                PbTypes.TYPE_FIXED64 => MapKeyTypes.TYPE_FIXED64,
                PbTypes.TYPE_SFIXED32 => MapKeyTypes.TYPE_SFIXED32,
                PbTypes.TYPE_SFIXED64 => MapKeyTypes.TYPE_SFIXED64,
                PbTypes.TYPE_BOOL => MapKeyTypes.TYPE_BOOL,
                PbTypes.TYPE_STRING => MapKeyTypes.TYPE_STRING,
                _ => throw mapEntryDescriptor,
              }
              ..valueType = singleTypeMsg(valueFieldDescriptor);
          }

          void repeatedField() {
            fieldMsg.repeatedType = MpbRepeatedTypeMsg()
              ..singleType = singleTypeMsg(fieldDescriptor);
          }

          switch (fieldDescriptor.label) {
            case FieldDescriptorProto_Label.LABEL_REPEATED:
              if (fieldDescriptor.type ==
                  FieldDescriptorProto_Type.TYPE_MESSAGE) {
                final resolvedMessageDescriptor = resolveMessage(
                  fieldDescriptor.typeName,
                ).messageDescriptor;
                if (resolvedMessageDescriptor.options.mapEntry) {
                  mapField(resolvedMessageDescriptor);
                } else {
                  repeatedField();
                }
              } else {
                repeatedField();
              }
            case FieldDescriptorProto_Label.LABEL_OPTIONAL:
              fieldMsg.singleType = singleTypeMsg(fieldDescriptor);
            case FieldDescriptorProto_Label.LABEL_REQUIRED:
              throw [messageDescriptor.name, fieldDescriptor];
          }

          return fieldMsg..freeze();
        }

        for (final fieldDescriptor in messageDescriptor.field) {
          if (fieldDescriptor.hasOneofIndex()) {
            final oneofIndex = fieldDescriptor.oneofIndex;
            if (!oneofIndicesEmitted.contains(oneofIndex)) {
              oneofIndicesEmitted.add(oneofIndex);

              final oneofDescriptor = messageDescriptor.oneofDecl[oneofIndex];

              yield MpbLogicalFieldMsg()
                ..oneof = (MpbOneofMsg()
                  ..description = (MpbDescriptionMsg()
                    ..protoName = oneofDescriptor.name
                    ..jsonName = oneofDescriptor.name.camelCase)
                  ..oneofIndex = oneofIndex
                  ..fields.addAll(messageDescriptor.field
                      .where(
                        (e) => e.hasOneofIndex() && e.oneofIndex == oneofIndex,
                      )
                      .map(descriptorToFieldMsg)))
                ..freeze();
            }
          } else {
            yield MpbLogicalFieldMsg()
              ..physicalField = descriptorToFieldMsg(fieldDescriptor);
          }
        }
      }

      final messageMsg = MpbMessageMsg()
        ..description =
            (MpbDescriptionMsg()..protoName = messageDescriptor.name)
        ..fields.addAll(logicalFields());

      if (enclosingMessage != null) {
        messageMsg.enclosingMessage = enclosingMessage;
      }

      return messageMsg..freeze();
    }

    EnumMsg createEnumMsg({
      required EnumDescriptorProto enumDescriptor,
      required ReferenceMsg? enclosingMessage,
    }) {
      final enumMsg = MpbEnumMsg()
        ..description = (MpbDescriptionMsg()..protoName = enumDescriptor.name)
        ..enumValues.addAll(enumDescriptor.value.map(
          (value) {
            return (MpbEnumValueMsg()
                  ..description = (MpbDescriptionMsg()..protoName = value.name))
                .valueToMapEntry(key: value.number);
          },
        ).entriesToMap());

      if (enclosingMessage != null) {
        enumMsg.enclosingMessage = enclosingMessage;
      }

      return enumMsg;
    }

    ReferenceMsg? enclosingMessage({
      required TypePath parentPath,
    }) {
      return parentPath.isEmpty
          ? null
          : messageReference(
              (
                fileName: fileDescriptor.name,
                typePath: parentPath,
              ),
            );
    }

    void processEnum({
      required TypePath parentPath,
      required EnumDescriptorProto enumDescriptor,
    }) {
      final typePath = parentPath.add(enumDescriptor.name);

      final referenceMsg = effectiveEnumReference(
        (
          fileName: fileDescriptor.name,
          typePath: typePath,
        ),
      );

      final enumMsg = createEnumMsg(
        enumDescriptor: enumDescriptor,
        enclosingMessage: enclosingMessage(
          parentPath: parentPath,
        ),
      );

      resolveLookup[referenceMsg] = enumMsg.writeToBuffer();

      if (collect) {
        enums.add(
          (
            reference: referenceMsg,
            msg: enumMsg,
          ),
        );
      }
    }

    void processMessage({
      required TypePath parentPath,
      required DescriptorProto messageDescriptor,
    }) {
      final typePath = parentPath.add(messageDescriptor.name);

      final referenceMsg = messageReference(
        (
          fileName: fileDescriptor.name,
          typePath: typePath,
        ),
      );

      final messageMsg = createMessageMsg(
        messageDescriptor: messageDescriptor,
        enclosingMessage: enclosingMessage(
          parentPath: parentPath,
        ),
      );

      resolveLookup[referenceMsg] = messageMsg.writeToBuffer();

      if (collect) {
        messages.add(
          (
            reference: referenceMsg,
            msg: messageMsg,
          ),
        );
      }

      for (final messageDescriptor in messageDescriptor.nestedType) {
        if (!messageDescriptor.options.mapEntry) {
          processMessage(
            parentPath: typePath,
            messageDescriptor: messageDescriptor,
          );
        }
      }

      for (final enumDescriptor in messageDescriptor.enumType) {
        processEnum(
          parentPath: typePath,
          enumDescriptor: enumDescriptor,
        );
      }
    }

    for (final messageDescriptor in fileDescriptor.messageType) {
      processMessage(
        parentPath: IList(),
        messageDescriptor: messageDescriptor,
      );
    }

    for (final enumDescriptor in fileDescriptor.enumType) {
      processEnum(
        parentPath: IList(),
        enumDescriptor: enumDescriptor,
      );
    }
  }

  for (final fileDescriptor in dependencyFileDescriptors) {
    processFileDescriptor(
      fileDescriptor: fileDescriptor,
      collect: false,
    );
  }
  for (final fileDescriptor in fileDescriptorSet.file) {
    processFileDescriptor(
      fileDescriptor: fileDescriptor,
      collect: true,
    );
  }

  return ComposedSchemaCollection(
    referencedEnums: enums.toIList(),
    referencedMessages: messages.toIList(),
    resolveReference: resolveLookup.getOrThrow,
  );
}
