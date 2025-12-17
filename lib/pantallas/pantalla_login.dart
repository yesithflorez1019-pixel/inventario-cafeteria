// lib/pantallas/pantalla_login.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cafeteria_inventario/pantallas/pantalla_admin.dart';
import 'package:cafeteria_inventario/pantallas/pantalla_trabajador.dart';
import 'package:cafeteria_inventario/widgets/dialogo_error.dart'; 
import 'package:cafeteria_inventario/utils/gestor_anuncios.dart'; 
import 'package:cafeteria_inventario/utils/control_versiones.dart';

class PantallaLogin extends StatefulWidget {
  const PantallaLogin({super.key});

  @override
  State<PantallaLogin> createState() => _PantallaLoginState();
}

class _PantallaLoginState extends State<PantallaLogin> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _estaCargando = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _navegarAlDestino(String rol) async {
    
    // 1. --- ¡EL FRENO AQUÍ TAMBIÉN! ---
    final bool hayBloqueo = await ControlVersiones.verificarActualizacion(context);
    if (hayBloqueo) return; // ¡Se detiene si hay actualización!
    // ---------------------------------

    if (!mounted) return;

    await GestorAnuncios.revisarAnuncios(context, rol);

    if (!mounted) return;

    if (rol == 'admin') {
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (ctx) => const PantallaAdmin()));
    } else if (rol == 'trabajador') {
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (ctx) => const PantallaTrabajador()));
    } else {
      mostrarDialogoError(context, 'Tu rol es desconocido. Contacta al administrador.');
      await FirebaseAuth.instance.signOut();
    }
  }

  Future<void> _intentarLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      mostrarDialogoError(context, 'Por favor, ingresa tu correo y contraseña.');
      return;
    }

    setState(() { _estaCargando = true; });

    try {
      UserCredential credenciales = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (credenciales.user == null) {
        setState(() { _estaCargando = false; });
        return;
      }
      
      final uid = credenciales.user!.uid;
      final docUsuario = await FirebaseFirestore.instance.collection('usuarios').doc(uid).get();
          
      if (!docUsuario.exists) {
        mostrarDialogoError(context, 'Usuario sin datos en Firestore. Contacta al administrador.');
        await FirebaseAuth.instance.signOut();
        setState(() { _estaCargando = false; });
        return;
      }

      final data = docUsuario.data();
      final bool estaActivo = data?['activo'] ?? true; 

      if (!estaActivo) {
        mostrarDialogoError(context, 'Tu cuenta ha sido desactivada. Contacta al administrador.');
        await FirebaseAuth.instance.signOut();
        setState(() { _estaCargando = false; });
        return; 
      }
      
      final rol = data?['rol'] ?? 'desconocido';

      if (!mounted) return;
      _navegarAlDestino(rol);

    } on FirebaseAuthException catch (e) {
      // ... (Manejo de errores igual) ...
      print('ERROR FIREBASE: ${e.code}'); 
      String mensaje = 'Ocurrió un error. Intenta de nuevo.';
      if (e.code == 'user-not-found' || e.code == 'invalid-credential') mensaje = 'Correo o contraseña incorrectos.';
      else if (e.code == 'network-request-failed') mensaje = 'Sin conexión a internet.';
      mostrarDialogoError(context, mensaje);
      setState(() { _estaCargando = false; }); 
    } catch (e) {
      mostrarDialogoError(context, 'Error desconocido: $e');
      setState(() { _estaCargando = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
      // ... (Tu diseño del login sigue IGUALITO, no lo cambies) ...
      // Solo copia el build que ya tenías o mantenlo
      final textTheme = Theme.of(context).textTheme;
      final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40), 
                Center(
                  child: Container(
                    height: 120, 
                    width: 220,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle, 
                      
                      image: const DecorationImage(
                        image: AssetImage('assets/images/logo_cafeteria.png'),
                        fit: BoxFit.cover, 
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text('COFFE BREAK', textAlign: TextAlign.center, style: textTheme.headlineMedium?.copyWith(color: colorScheme.primary, fontWeight: FontWeight.bold)),
                Text('Inventario', textAlign: TextAlign.center, style: textTheme.titleMedium),
                const SizedBox(height: 40),
                TextField(controller: _emailController, decoration: const InputDecoration(hintText: 'correo@ejemplo.com', prefixIcon: Icon(Icons.email_outlined)), keyboardType: TextInputType.emailAddress, textInputAction: TextInputAction.next, enabled: !_estaCargando),
                const SizedBox(height: 16),
                TextField(controller: _passwordController, decoration: const InputDecoration(hintText: 'Contraseña', prefixIcon: Icon(Icons.lock_outline)), obscureText: true, onEditingComplete: _intentarLogin, enabled: !_estaCargando),
                const SizedBox(height: 32),
                _estaCargando ? Center(child: CircularProgressIndicator(color: colorScheme.primary)) : FilledButton(onPressed: _intentarLogin, child: const Text('Ingresar')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}