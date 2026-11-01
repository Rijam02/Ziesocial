class ApiConstants {
  // Base URL server lokal XAMPP
  // Ubah ke http://10.0.2.2/ziesocial jika menguji di Android Emulator fisik/AVD
  static const String rootUrl = 'http://localhost/ziesocial';
  static String get baseUrl => '$rootUrl/api';

  static String get login => '$baseUrl/auth/login.php';
  static String get register => '$baseUrl/auth/register.php';
  static String get createPost => '$baseUrl/posts/create.php';
  static String get readPosts => '$baseUrl/posts/read.php';
  static String get updatePost => '$baseUrl/posts/update.php';
  static String get deletePost => '$baseUrl/posts/delete.php';
  static String get toggleLike => '$baseUrl/likes/toggle.php';
  static String get readComments => '$baseUrl/comments/read.php';
  static String get createComment => '$baseUrl/comments/create.php';
  static String get deleteComment => '$baseUrl/comments/delete.php';
  static String get toggleFollow => '$baseUrl/follows/toggle.php';
  static String get userProfile => '$baseUrl/users/profile.php';
  static String get updateProfile => '$baseUrl/users/update.php';

  static String getImageUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return path;
    }
    final cleanPath = path.startsWith('/') ? path.substring(1) : path;
    return '$rootUrl/$cleanPath';
  }
}



