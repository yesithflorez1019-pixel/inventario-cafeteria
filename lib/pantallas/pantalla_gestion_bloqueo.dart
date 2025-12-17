// lib/pantallas/pantalla_gestion_bloqueo.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:cafeteria_inventario/pantallas/pantalla_gestion_principal.dart';
import 'package:cafeteria_inventario/widgets/dialogo_error.dart'; 

class PantallaGestionBloqueo extends StatefulWidget {
  const PantallaGestionBloqueo({super.key});

  @override
  State<PantallaGestionBloqueo> createState() => _PantallaGestionBloqueoState();
}

class _PantallaGestionBloqueoState extends State<PantallaGestionBloqueo> {
  final _passwordController = TextEditingController();
  bool _estaCargando = false;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _verificarPassword() async {
    final passwordIngresada = _passwordController.text.trim();
    if (passwordIngresada.isEmpty) {
      mostrarDialogoError(context, 'Por favor, ingresa la contraseña.');
      return;
    }

    setState(() { _estaCargando = true; });

    try {
      final docConfig = await FirebaseFirestore.instance
          .collection('configuracion')
          .doc('gestion')
          .get();
      
      if (!docConfig.exists) {
        throw Exception('No se encontró el documento de configuración.');
      }

      final passwordCorrecta = docConfig.data()?['password'];
      
      if (passwordCorrecta == null) {
        throw Exception('No hay contraseña configurada en Firebase.');
      }

      if (passwordIngresada == passwordCorrecta) {
        if (mounted) {
          // --- ¡AQUÍ ESTÁ EL ARREGLO! ---
          // Ya no "reemplazamos", sino que "ponemos encima".
          Navigator.of(context).push( 
            MaterialPageRoute(
              builder: (ctx) => const PantallaGestionPrincipal(),
            ),
          );
          // --- FIN DEL ARREGLO ---
        }
      } else {
        mostrarDialogoError(context, 'Contraseña incorrecta.');
      }

    } catch (e) {
      print('Error al verificar: $e');
      mostrarDialogoError(context, 'No se pudo verificar la contraseña. Revisa tu conexión.');
    }

    if (mounted) {
      setState(() { _estaCargando = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: SingleChildScrollView( 
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(
                  Icons.shield_outlined, 
                  size: 80, 
                  color: Theme.of(context).colorScheme.primary
                ),
                const SizedBox(height: 16),
                Text(
                  'Mi Gestión',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Esta sección está protegida. Ingresa la contraseña de gestión.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                    labelText: 'Contraseña Secreta',
                    prefixIcon: Icon(Icons.lock_outline_rounded),
                  ),
                  obscureText: true,
                  onEditingComplete: _verificarPassword, 
                ),
                const SizedBox(height: 24),
                _estaCargando
                  ? Center(child: CircularProgressIndicator(
                      color: Theme.of(context).colorScheme.primary,
                    ))
                  : FilledButton(
                      onPressed: _verificarPassword,
                      child: const Text('Desbloquear'),
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}