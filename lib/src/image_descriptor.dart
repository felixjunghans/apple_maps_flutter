part of apple_maps_flutter;

/// Defines a bitmap image. For a annotation, this class can be used to set the
/// image of the annotation icon. For a ground overlay, it can be used to set the
/// image to place on the surface of the earth.
class ImageDescriptor {
  const ImageDescriptor._(this._json);

  /// Creates a [ImageDescriptor] from an asset image.
  ///
  /// Asset images in flutter are stored per:
  /// https://flutter.dev/docs/development/ui/assets-and-images#declaring-resolution-aware-image-assets
  /// This method takes into consideration various asset resolutions
  /// and scales the images to the right resolution depending on the dpi.
  factory ImageDescriptor.fromAssetImage(String assetName) {
    return ImageDescriptor._(<dynamic>[
      'fromAssetImage',
      assetName,
    ]);
  }

  /// Creates a ImageDescriptor using an array of bytes that must be encoded
  /// as PNG.
  factory ImageDescriptor.fromBytes(Uint8List byteData) {
    return ImageDescriptor._(<dynamic>['fromBytes', byteData]);
  }

  final dynamic _json;

  dynamic _toJson() => _json;
}
