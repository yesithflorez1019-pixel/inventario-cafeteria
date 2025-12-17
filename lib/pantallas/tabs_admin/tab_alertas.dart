// lib/pantallas/tabs_admin/tab_alertas.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


import 'pantalla_editar_insumo.dart';
class TabAlertas extends StatefulWidget {
  const TabAlertas({super.key});
  @override
  State<TabAlertas> createState() => _TabAlertasState();
}

class _TabAlertasState extends State<TabAlertas> {
  String? _categoriaSeleccionada; 

  @override
  Widget build(BuildContext context) {
    return Column( 
      children: [
        // --- BARRA DE FILTROS POR CATEGORÍA ---
        _buildCategoryFilters(),

        // --- LISTA DE ALERTAS ---
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
              .collection('insumos') 
              .where('stock_minimo', isGreaterThan: 0) 
              .snapshots(),
            builder: (context, snapshot) {
              // ... (El código de loading, error y filtrado va aquí, sin cambios) ...
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: CircularProgressIndicator(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                );
              }
              if (snapshot.hasError) {
                return const Center(child: Text('Error al cargar datos'));
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text('No hay insumos.'));
              }

              final insumosEnAlerta = snapshot.data!.docs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final stock = data['stock_cafeteria'] ?? 0;
                final minimo = data['stock_minimo'] ?? 0;
                final categoria = data['categoria']?.toLowerCase() ?? '';
                
                bool stockBajo = stock <= minimo;
                final coincideCategoria = _categoriaSeleccionada == null || 
                                          categoria == _categoriaSeleccionada!.toLowerCase();
                return stockBajo && coincideCategoria;
              }).toList();

              if (insumosEnAlerta.isEmpty) {
                return const Center(
                  child: Text(
                    '\nNo hay insumos con stock bajo.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18),
                  ),
                );
              }

              // --- ListView.builder ---
              return ListView.builder(
                padding: const EdgeInsets.all(16.0),
                itemCount: insumosEnAlerta.length,
                itemBuilder: (context, index) {
                  final insumo = insumosEnAlerta[index]; // Este es el DocumentSnapshot
                  final data = insumo.data() as Map<String, dynamic>;

                  final nombre = data['nombre'] ?? 'Sin nombre';
                  final stock = data['stock_cafeteria'] ?? 0;
                  final minimo = data['stock_minimo'] ?? 0;
                  final unidad = data['unidad'] ?? 'uds.';

                  return Card(
                    // ... (El Card sigue igual) ...
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: Theme.of(context).colorScheme.primary,
                        width: 1.5,
                      ),
                    ),
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      // --- ¡AQUÍ AÑADIMOS EL ONTAP! ---
                      onTap: () {
                        // Abre la pantalla de Editar y le pasa el insumo
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (ctx) => PantallaEditarInsumo(insumo: insumo),
                            fullscreenDialog: true,
                          ),
                        );
                      },
                      // ----------------------------------
                      leading: Icon(
                        Icons.warning_amber_rounded,
                        color: Theme.of(context).colorScheme.primary,
                        size: 30,
                      ),
                      title: Text(nombre, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      subtitle: Text('Stock mínimo: $minimo $unidad', style: const TextStyle(fontSize: 14)),
                      trailing: Text(
                        '¡Solo $stock!',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  // --- (El widget _buildCategoryFilters sigue igual que antes) ---
  Widget _buildCategoryFilters() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('insumos').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        final categorias = snapshot.data!.docs
            .map((doc) => (doc.data() as Map<String, dynamic>)['categoria'] as String? ?? '')
            .where((c) => c.isNotEmpty)
            .toSet().toList();
        categorias.sort();
        return Container(
          height: 50,
          padding: const EdgeInsets.only(left: 16.0, top: 8.0),
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: ChoiceChip(
                  label: const Text(' Todas'),
                  selected: _categoriaSeleccionada == null,
                  onSelected: (selected) {
                    setState(() { _categoriaSeleccionada = null; });
                  },
                  selectedColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                  labelStyle: TextStyle(
                    color: _categoriaSeleccionada == null 
                           ? Theme.of(context).colorScheme.primary 
                           : Colors.black,
                  ),
                ),
              ),
              ...categorias.map((categoria) {
                final isSelected = _categoriaSeleccionada == categoria;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ChoiceChip(
                    label: Text(categoria),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() { _categoriaSeleccionada = categoria; });
                    },
                    selectedColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                    labelStyle: TextStyle(
                      color: isSelected 
                             ? Theme.of(context).colorScheme.primary 
                             : Colors.black,
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }
}