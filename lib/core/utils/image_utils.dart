// F:\latestmvc\latestmvc\mvc-final-1.0-main\lib\core\utils\image_utils.dart

/// Utility functions for image processing.
class ImageUtils {
  /// Processes Google profile photo URLs to get higher resolution images
  /// Google photos often end with =s96-c, this method replaces it with =s256
  /// to get a higher resolution image
  static String? processGooglePhotoUrl(String? url) {
    if (url == null || url.isEmpty) return null;
    
    // Find the last occurrence of '=' in the URL
    final equalIndex = url.lastIndexOf('=');
    
    if (equalIndex == -1) {
      // No '=' found, return the original URL
      return url;
    }
    
    // Remove everything after '=' and add high-resolution parameter
    final baseUrl = url.substring(0, equalIndex);
    return '$baseUrl=s256-c'; // s256 for 256x256 resolution, c for crop
  }

  /// Validates if a URL is a valid image URL
  static bool isValidImageUrl(String? url) {
    if (url == null || url.isEmpty) return false;
    
    try {
      final uri = Uri.parse(url);
      return uri.isAbsolute && 
             (uri.scheme == 'http' || uri.scheme == 'https') &&
             _hasImageExtension(url);
    } catch (e) {
      return false;
    }
  }

  /// Checks if the URL has a valid image extension
  static bool _hasImageExtension(String url) {
    const imageExtensions = ['.jpg', '.jpeg', '.png', '.gif', '.webp', '.bmp'];
    final lowerUrl = url.toLowerCase();
    
    return imageExtensions.any((ext) => lowerUrl.contains(ext)) ||
           lowerUrl.contains('googleusercontent.com') ||
           lowerUrl.contains('googleapis.com') ||
           lowerUrl.contains('facebook.com') ||
           lowerUrl.contains('fbcdn.net');
  }

  /// Gets a placeholder image path for when no profile image is available
  static String getPlaceholderImagePath() {
    return 'assets/images/default_profile.png';
  }

  /// Generates initials from a name for use as a fallback avatar
  static String getInitials(String? name) {
    if (name == null || name.trim().isEmpty) return 'U';
    
    final words = name.trim().split(' ');
    if (words.length == 1) {
      return words[0].substring(0, 1).toUpperCase();
    } else {
      return (words[0].substring(0, 1) + words[1].substring(0, 1)).toUpperCase();
    }
  }
}
