import 'package:permission_handler/permission_handler.dart';
import 'dart:io' show Platform;

class AppPermissions {
  /// Request microphone permission with detailed handling
  static Future<bool> requestMicrophoneAccess() async {
    try {
      // Check if we're on iOS
      if (Platform.isIOS) {
        // First check the current status
        final currentStatus = await Permission.microphone.status;
        
        // If permission is already granted, return true
        if (currentStatus.isGranted) {
          return true;
        }
        
        // If permission is denied, we need to request it
        final status = await Permission.microphone.request();
        
        // For iOS, if permission is permanently denied, we need to show settings
        if (status.isPermanentlyDenied) {
          await openAppSettings();
          // Re-check permission after settings
          return await Permission.microphone.isGranted;
        }
        
        return status.isGranted;
      }
      
      // Default Android handling
      final status = await Permission.microphone.request();
      return status.isGranted;
    } catch (e) {
      print('Error requesting microphone permission: $e');
      return false;
    }
  }

  /// Check current permission status
  static Future<bool> get hasMicrophoneAccess async {
    return await Permission.microphone.isGranted;
  }

  /// Get detailed permission status
  static Future<PermissionStatus> checkMicrophoneStatus() async {
    return await Permission.microphone.status;
  }
} 