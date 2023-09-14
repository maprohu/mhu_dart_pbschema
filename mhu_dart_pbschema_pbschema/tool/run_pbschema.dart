import 'package:mhu_dart_pbgen/mhu_dart_pbgen.dart';
import 'package:mhu_dart_pbschema_pbschema/src/pbschema.dart';
import 'package:mhu_dart_sourcegen/mhu_dart_sourcegen.dart';

Future<void> main() async {
  await runPbSchemaGenerator(
    dependencies: [
      mhuDartPbschemaPbschema,
    ],
    sourcePackageDirectory: await packageRootDir(
      "mhu_dart_pbschema",
    ),
    protoc: false,
    packageName: "mhu_dart_pbschema_pbschema",
  );
}
