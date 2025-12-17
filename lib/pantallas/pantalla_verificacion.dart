// lib/pantallas/pantalla_verificacion.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:cafeteria_inventario/pantallas/pantalla_admin.dart';
import 'package:cafeteria_inventario/pantallas/pantalla_carga.dart';
import 'package:cafeteria_inventario/pantallas/pantalla_login.dart';
import 'package:cafeteria_inventario/pantallas/pantalla_trabajador.dart';

import 'package:cafeteria_inventario/widgets/dialogo_error.dart'; 
import 'package:cafeteria_inventario/utils/gestor_anuncios.dart'; 
import 'package:cafeteria_inventario/utils/control_versiones.dart'; 

class PantallaVerificacion extends StatefulWidget {
  const PantallaVerificacion({super.key});

  @override
  State<PantallaVerificacion> createState() => _PantallaVerificacionState();
}

class _PantallaVerificacionState extends State<PantallaVerificacion> {

  Future<String> _obtenerRol(User user) async {
    try {
      final docUsuario = await FirebaseFirestore.instance.collection('usuarios').doc(user.uid).get();  
      if (docUsuario.exists) {
        final data = docUsuario.data();
        final bool estaActivo = data?['activo'] ?? true; 
        if (!estaActivo) {
          await FirebaseAuth.instance.signOut(); 
          return 'desactivado';
        }
        return data?['rol'] ?? 'login';
      } else {
        await FirebaseAuth.instance.signOut();
        return 'login';
      }
    } catch (e) {
      return 'login';
    }
  }

  void _navegarAlDestino(String rol) async {
    
    // 1. --- ¡AQUÍ ESTÁ EL FRENO QUE FALTABA! ---
    // Guardamos la respuesta (true o false) en una variable
    final bool hayBloqueo = await ControlVersiones.verificarActualizacion(context);
    
    // Si hayBloqueo es TRUE, hacemos RETURN.
    // ¡El RETURN mata la función aquí mismo! Ya no ejecuta nada más abajo.
    if (hayBloqueo) return; 
    // ------------------------------------------

    if (!mounted) return;

    // 2. Revisar Anuncios (Solo llega aquí si NO hubo bloqueo)
    await GestorAnuncios.revisarAnuncios(context, rol); 

    if (!mounted) return;

    // 3. Navegar
    if (rol == 'desactivado') {
      mostrarDialogoError(context, 'Tu cuenta ha sido desactivada. Contacta al administrador.');
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (ctx) => const PantallaLogin()));
    } else if (rol == 'admin') {
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (ctx) => const PantallaAdmin()));
    } else if (rol == 'trabajador') {
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (ctx) => const PantallaTrabajador()));
    } else {
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (ctx) => const PantallaLogin()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const PantallaCarga();
        
        if (snapshot.hasData) {
          return FutureBuilder<String>(
            future: _obtenerRol(snapshot.data!),
            builder: (context, snapshotRol) {
              if (snapshotRol.connectionState == ConnectionState.done) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                   _navegarAlDestino(snapshotRol.data ?? 'login');
                });
                return const PantallaCarga(); 
              }
              return const PantallaCarga();
            },
          );
        }
        return const PantallaLogin();
      },
    );
  }
}