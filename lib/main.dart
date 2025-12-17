// lib/main.dart
import 'package:flutter/material.dart';
import 'package:cafeteria_inventario/tema/tema_app.dart';   
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'services/notification_service.dart';
// --- NUEVO: Importamos la pantalla de verificación ---
import 'package:cafeteria_inventario/pantallas/pantalla_verificacion.dart';

Future<void> main() async { 
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await initializeDateFormatting('es', null);

  await NotificationService().initNotifications();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Inventario Coquette',
      debugShowCheckedModeBanner: false, 
      theme: TemaApp().theme, 
      // --- CAMBIO: Ya no es PantallaLogin ---
      home: const PantallaVerificacion(), 
    );
  }
}