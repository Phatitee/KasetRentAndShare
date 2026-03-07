/// Cloudinary configuration for Kaset RentShare
class CloudinaryConfig {
  // Your Cloudinary cloud name
  static const String cloudName = 'dyzj89r8j';

  // Unsigned upload preset (created in Cloudinary Settings > Upload)
  static const String uploadPreset = 'kaset_unsigned';

  // Base upload URL
  static String get uploadUrl =>
      'https://api.cloudinary.com/v1_1/$cloudName/image/upload';

  // Generate optimized image URL with transformations
  static String getOptimizedUrl(String publicId, {int? width, int? height}) {
    final List<String> transforms = ['f_auto', 'q_auto'];
    if (width != null) transforms.add('w_$width');
    if (height != null) transforms.add('h_$height');
    transforms.add('c_fill');

    final transformStr = transforms.join(',');
    return 'https://res.cloudinary.com/$cloudName/image/upload/$transformStr/$publicId';
  }

  // Generate thumbnail URL (small preview)
  static String getThumbnailUrl(String publicId) {
    return getOptimizedUrl(publicId, width: 300, height: 300);
  }

  // Generate medium-size URL (for detail views)
  static String getMediumUrl(String publicId) {
    return getOptimizedUrl(publicId, width: 800);
  }
}
