// lib/pantallas/pantalla_verificador_rol.dart
import 'package:cafeteria_inventario/pantallas/pantalla_admin.dart';
import 'package:cafeteria_inventario/pantallas/pantalla_carga.dart';
import 'package:cafeteria_inventario/pantallas/pantalla_login.dart';
import 'package:cafeteria_inventario/pantallas/pantalla_trabajador.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class PantallaVerificadorRol extends StatelessWidget {
  // Recibe el usuario que ya está logueado
  final User user;
  const PantallaVerificadorRol({super.key, required this.user});

  // Esta función obtiene el ROL y decide a dónde ir
  Future<String> _obtenerRol(User user) async {
    try {
      final docUsuario = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(user.uid)
          .get();
          
      if (docUsuario.exists) {
        return docUsuario.data()?['rol'] ?? 'login';
      } else {
        // Si el usuario existe en Auth pero no en Firestore (raro), lo deslogueamos
        await FirebaseAuth.instance.signOut();
        return 'login';
      }
    } catch (e) {
      // Si hay error de red, lo mandamos al login
      return 'login';
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _obtenerRol(user), // Llama a la función que obtiene el rol
      builder: (context, snapshot) {
        // Mientras espera, muestra la pantalla de carga
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const PantallaCarga();
        }

        // Si hay un error, al login
        if (snapshot.hasError) {
          return const PantallaLogin();
        }

        // Cuando tiene el rol, decidimos
        final rol = snapshot.data;
        if (rol == 'admin') {
          return const PantallaAdmin();
        } else if (rol == 'trabajador') {
          return const PantallaTrabajador();
        } else {
          // Si el rol es nulo o 'login', va al login
          return const PantallaLogin();
        }
      },
    );
  }
}