import 'package:flutter/material.dart';
import 'data/services/firebase_service.dart';
import 'core/services/notification_service.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FirebaseService.initialize();
  await NotificationService.initialize();
  runApp(const PayRappelApp());
}

