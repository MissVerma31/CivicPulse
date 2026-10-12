class ApiConstants {
  static const String baseUrl = "https://civicpulse-backend-oamw.onrender.com";
  static const String login = "/api/auth/login";
  static const String register = "/api/auth/register";
  static const authorityComplaints = "/api/authority/complaints";
  static const authorityAssignedToMe = "/api/authority/complaints/assigned-to-me";
  static const adminComplaints = "/api/admin/complaints";
  static const String allComplaintsPublic = '/api/complaints/all';

  static const String userMe = "/api/users/me";

  static const String complaints = "/api/complaints";
  static const String myComplaints = "/api/complaints/mine";
  static const String myRewards = "/api/users/me/rewards";
  static const String myBadges = "/api/users/me/badges";
  static const String leaderboard = "/api/leaderboard";



  static String complaintById(int id) => "/api/complaints/$id";
  static String closeComplaint(int id) => "/api/complaints/$id/close";
  static String complaintsByDepartment(String dept) => "/api/complaints/department/$dept";

  static const String categories = "/api/categories";

  static const String adminCategories = "/api/admin/categories";
  static const String adminAuthorities = "/api/admin/authorities";
  
  static String verifyComplaint(int id) => "/api/authority/complaints/$id/verify";
  static String startProgress(int id) => "/api/authority/complaints/$id/start-progress";
  static String resolveComplaint(int id) => "/api/authority/complaints/$id/resolve";

  static String upvoteComplaint(int id) => "/api/complaints/$id/upvote";
  static String rejectComplaint(int id) => "/api/authority/complaints/$id/reject";
  static const String similarComplaints = "/api/complaints/similar";
}