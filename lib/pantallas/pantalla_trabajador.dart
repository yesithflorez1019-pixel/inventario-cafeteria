// lib/pantallas/pantalla_trabajador.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:cafeteria_inventario/pantallas/tabs_trabajador/tab_uso_trabajador.dart';
import 'package:cafeteria_inventario/pantallas/tabs_admin/tab_bodega.dart';
import 'package:cafeteria_inventario/pantallas/pantalla_login.dart';

class PantallaTrabajador extends StatefulWidget {
  const PantallaTrabajador({super.key});

  @override
  State<PantallaTrabajador> createState() => _PantallaTrabajadorState();
}

class _PantallaTrabajadorState extends State<PantallaTrabajador> {
  int _indiceSeleccionado = 0;

  final List<String> _titulos = [
    'Uso de Insumos',
    'Gestion de Bodega',
  ];

  final List<Widget> _pestanas = const [
    TabUsoTrabajador(),
    TabBodega(),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titulos[_indiceSeleccionado]), 
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
            onPressed: _cerrarSesion,
          ),
        ],
      ),
      // --- ¡ASEGÚRATE DE QUE ESTA PARTE DIGA "IndexedStack"! ---
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
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.point_of_sale_rounded),
            label: 'Insumos',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory_2_outlined),
            label: 'Bodega',
          ),
        ],
      ),
    );
  }
}