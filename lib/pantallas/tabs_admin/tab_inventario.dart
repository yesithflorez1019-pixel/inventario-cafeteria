// lib/pantallas/tabs_admin/tab_inventario.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:cafeteria_inventario/pantallas/tabs_admin/pantalla_agregar_insumo.dart';
import 'package:cafeteria_inventario/pantallas/tabs_admin/pantalla_editar_insumo.dart';

class TabInventario extends StatefulWidget {
  const TabInventario({super.key});
  @override
  State<TabInventario> createState() => _TabInventarioState();
}

class _TabInventarioState extends State<TabInventario> {
  // Solo necesitamos guardar el estado de los filtros
  String _terminoBusqueda = '';
  String? _categoriaSeleccionada; 

  // --- ¡HEMOS QUITADO TODA LA LÓGICA DE _refrescarInsumos, _insumos, _estaCargando! ---
  // --- Las funciones de acción ya no necesitan refrescar el estado local ---

  Future<void> _actualizarStockCafeteria(String insumoId, int cambio) async {
    // Simplemente actualiza Firebase. StreamBuilder hará el resto.
    final docRef = FirebaseFirestore.instance.collection('insumos').doc(insumoId);
    await docRef.update({'stock_cafeteria': FieldValue.increment(cambio)});
  }

  Future<void> _registrarMovimiento(String nombreInsumo, int cantidad, String tipo) async {
    // ... (Esta función sigue exactamente igual que antes, buscando el nombre) ...
    final usuario = FirebaseAuth.instance.currentUser;
    if (usuario == null) return; 
    String nombreUsuario = usuario.email ?? 'desconocido'; 
    try {
      final docUsuario = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(usuario.uid)
          .get();
      if (docUsuario.exists) {
        nombreUsuario = docUsuario.data()?['nombre'] ?? nombreUsuario;
      }
    } catch (e) {
      print('Error al obtener nombre de usuario: $e');
    }
    FirebaseFirestore.instance.collection('movimientos').add({
      'insumo_nombre': nombreInsumo, 
      'cantidad': cantidad,
      'tipo': tipo,
      'usuario_email': nombreUsuario,
      'fecha': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _eliminarInsumo(String insumoId) async {
    try {
      await FirebaseFirestore.instance.collection('insumos').doc(insumoId).delete();
      await _registrarMovimiento('Insumo Eliminado (ID: ...${insumoId.substring(insumoId.length - 5)})', 0, 'eliminar_insumo');
      // ¡Ya no necesitamos refrescar!
    } catch (e) {
      print('Error al eliminar: $e');
    }
  }

  void _mostrarDialogoEliminar(BuildContext context, String insumoId, String nombre) {
    // ... (Esta función sigue exactamente igual que antes) ...
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Row(
          children: [
            Icon(Icons.delete_sweep_rounded, color: Colors.red),
            SizedBox(width: 10),
            Text('¿Estás seguro?'),
          ],
        ),
        content: Text(
          'Estás a punto de eliminar permanentemente el insumo "$nombre".\n\nNo se puede deshacer.',
          style: const TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.of(ctx).pop(); 
              _eliminarInsumo(insumoId); 
            },
            child: const Text('Sí, eliminar'),
          ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // --- Barra de Búsqueda (sin cambios) ---
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Buscar insumo...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              onChanged: (valor) {
                setState(() {
                  _terminoBusqueda = valor;
                });
              },
            ),
          ),
          
          // --- Barra de Filtros (sin cambios en la lógica, solo en cómo obtiene los datos) ---
          _buildCategoryFilters(),

          // --- ¡DE VUELTA AL STREAMBUILDER! ---
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('insumos').snapshots(),
              builder: (context, snapshot) {
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
                  return const Center(child: Text('no hay insumos'));
                }

                // --- LÓGICA DE FILTRADO (igual que antes) ---
                final insumosFiltrados = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final nombre = data['nombre']?.toLowerCase() ?? '';
                  final categoria = data['categoria']?.toLowerCase() ?? '';
                  
                  final coincideBusqueda = nombre.contains(_terminoBusqueda.toLowerCase());
                  final coincideCategoria = _categoriaSeleccionada == null || 
                                        categoria == _categoriaSeleccionada!.toLowerCase();

                  return coincideBusqueda && coincideCategoria;
                }).toList();
                
                if (insumosFiltrados.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('No se encontraron insumos',
                          style: TextStyle(fontSize: 18),
                        ),
                        const SizedBox(height: 10),
                        Text(_categoriaSeleccionada != null 
                          ? 'En la categoría "$_categoriaSeleccionada"' 
                          : 'Con el nombre "$_terminoBusqueda"'
                        ),
                      ],
                    ),
                  );
                }

                // --- ListView.builder (igual que antes) ---
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  itemCount: insumosFiltrados.length,
                  itemBuilder: (context, index) {
                    final insumo = insumosFiltrados[index];
                    final data = insumo.data() as Map<String, dynamic>;

                    final nombre = data['nombre'] ?? 'Sin nombre';
                    final stockCafeteria = data['stock_cafeteria'] ?? 0;
                    final stockBodega = data['stock_bodega'] ?? 0;
                    final unidad = data['unidad'] ?? 'uds.'; 

                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        visualDensity: VisualDensity.compact,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                        onTap: () {
                          // ¡Ya no necesitamos "await" ni refrescar!
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (ctx) => PantallaEditarInsumo(insumo: insumo),
                              fullscreenDialog: true,
                            ),
                          );
                        },
                        onLongPress: () {
                          _mostrarDialogoEliminar(context, insumo.id, nombre);
                        },
                        title: Text(nombre, style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
                        subtitle: Text('Bodega: $stockBodega $unidad', style: Theme.of(context).textTheme.bodyMedium),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.remove_circle, color: Theme.of(context).colorScheme.primary),
                              onPressed: () {
                                if (stockCafeteria > 0) {
                                  // ¡Llamamos a las funciones async sin "await"!
                                  // La UI se actualizará sola gracias a StreamBuilder
                                  _actualizarStockCafeteria(insumo.id, -1);
                                  _registrarMovimiento(nombre, -1, 'uso_cafeteria');
                                }
                              },
                            ),
                            Text(
                              '$stockCafeteria',
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                    color: Theme.of(context).colorScheme.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            IconButton(
                              icon: Icon(Icons.add_circle, color: Theme.of(context).colorScheme.primary),
                              onPressed: () {
                                _actualizarStockCafeteria(insumo.id, 1);
                                _registrarMovimiento(nombre, 1, 'suma_admin');
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // ¡Ya no necesitamos "await" ni refrescar!
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (ctx) => const PantallaAgregarInsumo(),
              fullscreenDialog: true, 
            ),
          );
        },
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  // --- Widget _buildCategoryFilters (ahora usa StreamBuilder) ---
  Widget _buildCategoryFilters() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('insumos').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox(height: 50); 

        final categorias = snapshot.data!.docs
            .map<String>((doc) => (doc.data() as Map<String, dynamic>)['categoria'] ?? '')
            .where((c) => c.isNotEmpty)
            .toSet().toList();
        categorias.sort(); 

        return Container(
          height: 50, 
          padding: const EdgeInsets.only(left: 16.0),
          child: ListView(
            scrollDirection: Axis.horizontal, 
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: ChoiceChip(
                  label: const Text('Todas'),
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