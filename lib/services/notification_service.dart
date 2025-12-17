// lib/services/notification_service.dart

import 'package:flutter/material.dart'; // <--- ¡ESTE FALTABA! (Trae los colores)
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;

class NotificationService {
  // Instancia única (Singleton)
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  // 1. Inicializar
  Future<void> initNotifications() async {
    tz.initializeTimeZones();

    // Icono por defecto (asegúrate de tener un icono en android/app/src/main/res/drawable/ic_launcher.png)
    // Si falla, usa '@mipmap/ic_launcher'
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        print('🔔 Tocar notificación: ${response.payload}');
      },
    );
    
    // Permisos para Android 13+
    final androidImplementation = flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (androidImplementation != null) {
      androidImplementation.requestNotificationsPermission();
    }
  }

  // 2. Mostrar Notificación
  Future<void> mostrarAlertaStock(String producto, int stockActual) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'stock_alert_channel', // ID único
      'Alertas de Inventario', // Nombre visible
      channelDescription: 'Avisos de stock bajo',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
      color: Color(0xFFFF5252), // <--- Ahora sí reconocerá esto gracias al import de arriba
    );

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await flutterLocalNotificationsPlugin.show(
      0, 
      '¡Alerta de Stock Bajo! ⚠️', 
      'Quedan pocas unidades de $producto ($stockActual disponibles).', 
      platformChannelSpecifics,
      payload: 'stock_bajo',
    );
  }
}