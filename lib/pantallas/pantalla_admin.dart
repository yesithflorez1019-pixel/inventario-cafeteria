// lib/pantallas/pantalla_admin.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; 
import 'package:cafeteria_inventario/pantallas/pantalla_login.dart';

// Importamos las 4 pestañas de siempre
import 'package:cafeteria_inventario/pantallas/tabs_admin/tab_alertas.dart';
import 'package:cafeteria_inventario/pantallas/tabs_admin/tab_bodega.dart';
import 'package:cafeteria_inventario/pantallas/tabs_admin/tab_inventario.dart';
import 'package:cafeteria_inventario/pantallas/tabs_admin/tab_registros.dart';
// --- ¡NUEVO! Importamos la pantalla de bloqueo ---
import 'package:cafeteria_inventario/pantallas/pantalla_gestion_bloqueo.dart';


class PantallaAdmin extends StatefulWidget {
  const PantallaAdmin({super.key});

  @override
  State<PantallaAdmin> createState() => _PantallaAdminState();
}

class _PantallaAdminState extends State<PantallaAdmin> {

  int _indiceSeleccionado = 0;

  // --- ¡CAMBIO! Añadimos el 5to título ---
  final List<String> _titulos = [
    'Inventario',
    'Bodega',
    'Registros',
    'Alertas',
    'Mi Gestión' // <-- NUEVO
  ];

  // --- ¡CAMBIO! Añadimos la 5ta pestaña ---
  final List<Widget> _pestanas = const [
    TabInventario(),
    TabBodega(),
    TabRegistros(),
    TabAlertas(),
    PantallaGestionBloqueo() // <-- NUEVA
  ];

  @override
  void dispose() {
    super.dispose();
  }

  void _onTabTapped(int index) {
    setState(() { 
      _indiceSeleccionado = index; 
    });
  }

  void _cerrarSesion() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const PantallaLogin()),
      (Route<dynamic> route) => false,
    );
  }

  Future<void> _eliminarTodosLosRegistros() async {
    // ... (Esta función sigue igual) ...
    try {
      final querySnapshot = await FirebaseFirestore.instance.collection('movimientos').get();
      final batch = FirebaseFirestore.instance.batch();
      for (final doc in querySnapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } catch (e) {
      print('Error al borrar todo: $e');
    }
  }

  void _mostrarDialogoEliminarTodo(BuildContext context) {
    // ... (Esta función sigue igual) ...
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Row(
          children: [
            Icon(Icons.delete_forever, color: Colors.red),
            SizedBox(width: 10),
            Text('¿ESTÁS MUY SEGURO?'),
          ],
        ),
        content: const Text(
          'Estás a punto de borrar TODO el historial de movimientos de TODOS los usuarios. \n\nESTA ACCIÓN ES PERMANENTE',
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              _eliminarTodosLosRegistros();
              Navigator.of(ctx).pop();
            },
            child: const Text('Sí, borrar todo'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titulos[_indiceSeleccionado]),
        actions: [
          // Esta lógica sigue funcionando (solo aparece en la pestaña 2)
          if (_indiceSeleccionado == 2) 
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined),
              tooltip: 'Borrar todo el historial',
              onPressed: () {
                _mostrarDialogoEliminarTodo(context);
              },
            ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
            onPressed: _cerrarSesion,
          ),
        ],
      ),
      body: IndexedStack(
        index: _indiceSeleccionado, 
        children: _pestanas, 
      ),


      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _indiceSeleccionado,
        onTap: _onTabTapped,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey.shade400,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
        
        // --- ¡CAMBIO! Añadimos el 5to ícono ---
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.storefront),
            label: 'Insumos',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory_2_outlined),
            label: 'Bodega',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history_edu_outlined),
            label: 'Registros',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications_active_outlined),
            label: 'Alertas',
          ),
          // --- ¡NUEVO! ---
          BottomNavigationBarItem(
            icon: Icon(Icons.shield_outlined), // Icono de escudo
            label: 'Gestión',
          ),
        ],
      ),
    );
  }
}