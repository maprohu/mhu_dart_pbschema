import 'dart:async';
import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:fixnum/fixnum.dart';
import 'package:mhu_dart_annotation/mhu_dart_annotation.dart';
import 'package:mhu_dart_commons/commons.dart';
import 'package:protobuf/protobuf.dart';
import 'package:recase/recase.dart';

import 'generated/descriptor.pb.dart';
import 'generated/mhu_dart_pbschema.pb.dart';
import 'proto_schema.dart' as $lib;

part 'proto_schema.g.has.dart';

part 'proto_schema.g.dart';

part 'message.dart';

part 'enum.dart';

part 'logical_field.dart';

part 'field.dart';

part 'type.dart';

part 'type/map.dart';

part 'oneof.dart';

part 'descriptor.dart';

part 'generated_message.dart';

part 'resolve.dart';

part 'schema.dart';

part 'marker.dart';

part 'model.dart';

@Has()
typedef TagNumberValue = int;
@Has()
typedef FieldIndex = int;

@Has()
typedef OneofIndex = int;

@Has()
typedef ReadFieldValue<F> = F Function(
  GeneratedMessage message,
  int fieldIndex,
);

@Has()
typedef WriteFieldValue<F> = void Function(
  GeneratedMessage message,
  FieldCoordinates fieldCoordinates,
  F value,
);

@Compose()
@Has()
abstract class FieldCoordinates implements HasFieldIndex, HasTagNumberValue {}

@Has()
typedef MessageMsg = MpbMessageMsg;

@Has()
typedef EnumMsg = MpbEnumMsg;

@Has()
typedef FieldMsg = MpbFieldMsg;

@Has()
typedef LogicalFieldMsg = MpbLogicalFieldMsg;

@Has()
typedef ReferenceMsg = MpbReferenceMsg;

@Has()
typedef OneofMsg = MpbOneofMsg;

// @Compose()
// abstract class SchemaCollection implements HasMessageLookup {}
