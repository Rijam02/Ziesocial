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
  static String get deleteAccount => '$baseUrl/users/delete.php';

  // Notifications / Activity
  static String get readNotifications => '$baseUrl/notifications/read.php';

  // Stories (24 Jam)
  static String get createStory => '$baseUrl/stories/create.php';
  static String get readStories => '$baseUrl/stories/read.php';
  static String get viewStory => '$baseUrl/stories/view.php';
  static String get deleteStory => '$baseUrl/stories/delete.php';

  // Highlights (Sorotan Profil)
  static String get updateHighlight => '$baseUrl/highlights/update.php';
  static String get deleteHighlight => '$baseUrl/highlights/delete.php';

  // Notes & Pesan (Catatan 24 Jam & Daftar Akun Chat)
  static String get readNotes => '$baseUrl/notes/read.php';
  static String get saveNote => '$baseUrl/notes/save.php';

  // Chat Messages (Pesan Teks, Kirim Foto, Balas & Hapus Chat)
  static String get readMessages => '$baseUrl/messages/read.php';
  static String get sendMessage => '$baseUrl/messages/send.php';
  static String get deleteMessage => '$baseUrl/messages/delete.php';

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
