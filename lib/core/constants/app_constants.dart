abstract final class AppConstants {
  // Supabase Storage buckets
  static const String invoicesBucket = 'invoices';
  static const String vehiclePhotosBucket = 'vehicle-photos';

  // Signed URL expiry
  static const int storageSignedUrlExpirySeconds = 3600; // 1 hour

  // Pagination
  static const int defaultPageSize = 20;

  // Maintenance
  static const int healthScoreGoodThreshold = 80;
  static const int healthScoreWarningThreshold = 50;

  // Mileage reminder
  static const int mileageReminderDayOfMonth = 1;

  // Notification types
  static const String notificationTypeMileage = 'mileage_reminder';
  static const String notificationTypeMaintenance = 'maintenance_reminder';
}
