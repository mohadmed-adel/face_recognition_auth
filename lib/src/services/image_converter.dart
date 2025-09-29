import 'package:camera/camera.dart';
import 'package:image/image.dart' as imglib;

imglib.Image convertToImage(CameraImage image) {
  try {
    // Determine format based on number of planes
    // YUV420 typically has 3 planes, BGRA8888 has 1 plane
    if (image.planes.length == 3) {
      return _convertYUV420(image);
    } else if (image.planes.length == 1) {
      return _convertBGRA8888(image);
    }
    // Default to YUV420 for most camera formats
    return _convertYUV420(image);
  } catch (e) {
    // Log error without print statement
    throw Exception('Image conversion failed: $e');
  }
}

imglib.Image _convertBGRA8888(CameraImage image) {
  return imglib.Image.fromBytes(
    width: image.width,
    height: image.height,
    bytes: image.planes[0].bytes.buffer,
    numChannels: 4,
    order: imglib.ChannelOrder.bgra,
  );
}

imglib.Image _convertYUV420(CameraImage image) {
  int width = image.width;
  int height = image.height;
  var img = imglib.Image(width: width, height: height);
  final int uvyButtonStride = image.planes[1].bytesPerRow;
  final int? uvPixelStride = image.planes[1].bytesPerPixel;
  for (int y = 0; y < height; y++) {
    for (int x = 0; x < width; x++) {
      final int uvIndex =
          uvPixelStride! * (x / 2).floor() + uvyButtonStride * (y / 2).floor();
      final int index = y * width + x;
      final int yp = image.planes[0].bytes[index];
      final up = image.planes[1].bytes[uvIndex];
      final vp = image.planes[2].bytes[uvIndex];
      int r = (yp + vp * 1436 / 1024 - 179).round().clamp(0, 255);
      int g = (yp - up * 46549 / 131072 + 44 - vp * 93604 / 131072 + 91)
          .round()
          .clamp(0, 255);
      int b = (yp + up * 1814 / 1024 - 227).round().clamp(0, 255);
      img.setPixelRgba(x, y, r, g, b, 255);
    }
  }

  return img;
}
