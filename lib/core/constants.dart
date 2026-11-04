class ApiConstants {
  // Base URL folder utama ZieSocial
  static const String rootUrl = 'http://localhost/ziesocial';

  // Base URL API
  static String get baseUrl => '$rootUrl/api';

  // Authentication
  static String get login => '$baseUrl/auth/login.php';
  static String get register => '$baseUrl/auth/register.php';

  // Posts
  static String get createPost => '$baseUrl/posts/create.php';
  static String get readPosts => '$baseUrl/posts/read.php';
  static String get updatePost => '$baseUrl/posts/update.php';
  static String get deletePost => '$baseUrl/posts/delete.php';

  // Likes
  static String get toggleLike => '$baseUrl/likes/toggle.php';

  // Comments
  static String get readComments => '$baseUrl/comments/read.php';
  static String get createComment => '$baseUrl/comments/create.php';
  static String get deleteComment => '$baseUrl/comments/delete.php';

  // Follows
  static String get toggleFollow => '$baseUrl/follows/toggle.php';
  static String get followList => '$baseUrl/follows/list.php';

  // Users
  static String get userProfile => '$baseUrl/users/profile.php';
  static String get updateProfile => '$baseUrl/users/update.php';
  static String get searchUsers => '$baseUrl/users/search.php';

  // Notifications / Activity
  static String get readNotifications => '$baseUrl/notifications/read.php';

  // Image URL
  static String getImageUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http://') ||
        path.startsWith('https://')) {
      return path;
    }

    final cleanPath =
        path.startsWith('/') ? path.substring(1) : path;

    return '$rootUrl/$cleanPath';
  }
}
