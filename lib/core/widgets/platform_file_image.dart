import 'package:flutter/widgets.dart';

import 'platform_file_image_stub.dart'
    if (dart.library.io) 'platform_file_image_io.dart';

Widget platformFileImage(
  String path, {
  double? width,
  double? height,
  BoxFit? fit,
  Widget Function(BuildContext, Object, StackTrace?)? errorBuilder,
}) {
  return platformFileImageImpl(
    path,
    width: width,
    height: height,
    fit: fit,
    errorBuilder: errorBuilder,
  );
}

