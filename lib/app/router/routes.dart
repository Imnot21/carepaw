/// Route path constants for the CarePaw application.
///
/// Centralized route definitions to ensure consistency
/// and easy navigation throughout the app.
abstract class Routes {
  Routes._();

  // ============ Initial Routes ============
  static const String splash = '/';
  static const String onboarding = '/onboarding';

  // ============ Authentication Routes ============
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String resetPassword = '/reset-password';

  // ============ Main Routes (Role-based) ============
  static const String home = '/home';
  static const String dashboard = '/dashboard';

  // ============ Pet Owner Routes ============
  static const String pets = '/pets';
  static const String petDetail = '/pets/:id';
  static const String petAdd = '/pets/add';
  static const String petEdit = '/pets/:id/edit';

  static const String appointments = '/appointments';
  static const String appointmentDetail = '/appointments/:id';
  static const String appointmentEdit = '/appointments/:id/edit';
  static const String appointmentRequest = '/appointments/request';

  static const String queue = '/queue';

  static const String medicalRecords = '/medical-records';
  static const String medicalRecordDetail = '/medical-records/:id';
  static const String medicalRecordsRoute = 'medical-records';

  // ============ Staff Routes ============
  static const String staffDashboard = '/staff';
  static const String staffAppointments = '/staff/appointments';
  static const String staffQueue = '/staff/queue';
  static const String staffInventory = '/staff/inventory';
  static const String staffScanning = '/staff/scanning';

  // ============ Veterinarian Routes ============
  static const String vetDashboard = '/vet';
  static const String vetPatients = '/vet/patients';
  static const String vetPatientDetail = '/vet/patients/:id';
  static const String vetRecords = '/vet/records';
  static const String vetRecordCreate = '/vet/records/create';

  // ============ Admin Routes ============
  static const String adminDashboard = '/admin';
  static const String adminUsers = '/admin/users';
  static const String adminSettings = '/admin/settings';
  static const String adminAudit = '/admin/audit';

  // ============ Common Routes ============
  static const String notifications = '/notifications';
  static const String profile = '/profile';
  static const String settings = '/settings';
  static const String about = '/about';

  // ============ Error Routes ============
  static const String notFound = '/404';
  static const String error = '/error';
}

/// Route names for navigator operations
abstract class RouteNames {
  RouteNames._();

  static const String splash = 'splash';
  static const String onboarding = 'onboarding';

  static const String login = 'login';
  static const String register = 'register';
  static const String forgotPassword = 'forgot-password';
  static const String resetPassword = 'reset-password';

  static const String home = 'home';
  static const String dashboard = 'dashboard';

  static const String pets = 'pets';
  static const String petDetail = 'pet-detail';
  static const String petAdd = 'pet-add';
  static const String petEdit = 'pet-edit';

  static const String appointments = 'appointments';
  static const String appointmentDetail = 'appointment-detail';
  static const String appointmentEdit = 'appointment-edit';
  static const String appointmentRequest = 'appointment-request';

  static const String queue = 'queue';

  static const String medicalRecordsRoute = 'medical-records';

  static const String staffDashboard = 'staff-dashboard';
  static const String staffAppointments = 'staff-appointments';
  static const String staffQueue = 'staff-queue';
  static const String staffInventory = 'staff-inventory';
  static const String staffScanning = 'staff-scanning';

  static const String vetDashboard = 'vet-dashboard';
  static const String vetPatients = 'vet-patients';
  static const String vetPatientDetail = 'vet-patient-detail';

  static const String adminDashboard = 'admin-dashboard';
  static const String adminUsers = 'admin-users';
  static const String adminSettings = 'admin-settings';
  static const String adminAudit = 'admin-audit';

  static const String notifications = 'notifications';
  static const String profile = 'profile';
  static const String settings = 'settings';
}
