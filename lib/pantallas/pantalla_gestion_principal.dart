// lib/pantallas/pantalla_gestion_principal.dart
import 'package:flutter/material.dart';

// --- ¡NUEVO! Importamos las dos pestañas reales ---
import 'package:cafeteria_inventario/pantallas/tabs_gestion/tab_cierre_caja.dart';
import 'package:cafeteria_inventario/pantallas/tabs_gestion/tab_resumen_gestion.dart';

class PantallaGestionPrincipal extends StatefulWidget {
  const PantallaGestionPrincipal({super.key});

  @override
  State<PantallaGestionPrincipal> createState() => _PantallaGestionPrincipalState();
}

class _PantallaGestionPrincipalState extends State<PantallaGestionPrincipal> {
  int _indiceSeleccionado = 0;

  final List<String> _titulos = [
    'Cierre de Caja Diario',
    'Resumen de Gestión',
  ];
  
  // --- ¡CAMBIO! Reemplazamos el texto por los Widgets reales ---
  final List<Widget> _pestanas = const [
    TabCierreCaja(), 
    TabResumenGestion(), // <-- ¡NUEVO!
  ];
  // ---------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titulos[_indiceSeleccionado]),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop(); 
          },
        ),
      ),
      body: IndexedStack(
        index: _indiceSeleccionado,
        children: _pestanas,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _indiceSeleccionado,
        onTap: (index) {
          setState(() {
            _indiceSeleccionado = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey.shade400,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.point_of_sale_outlined),
            label: 'Cierre de Caja',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart_outlined),
            label: 'Resumen',
          ),
        ],
      ),
    );
  }
}