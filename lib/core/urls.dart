class Endpoints {
  static const baseUrl = 'https://connect.crisant.com/api/';
  static const mediaBaseUrl = 'https://connect.crisant.com/';

  static const login = 'auth/request-otp';
  static const verifyOtp = 'auth/verify-otp';
  static const refreshToken = 'auth/refresh';
  static const logout = 'auth/logout';
  static const refreshtoken = refreshToken;
  static const me = 'me';
  static const clients = 'clients';
  static const uploads = 'uploads';
  static const posts = 'posts';
  static const notifications = 'notifications';
  static const notificationsUnreadCount = 'notifications/unread-count';

  static String notificationRead(int id) => 'notifications/$id/read';
}
