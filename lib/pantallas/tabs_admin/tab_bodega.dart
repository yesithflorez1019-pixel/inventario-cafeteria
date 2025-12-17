// lib/pantallas/tabs_admin/tab_bodega.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class TabBodega extends StatefulWidget {
  const TabBodega({super.key});
  @override
  State<TabBodega> createState() => _TabBodegaState();
}

class _TabBodegaState extends State<TabBodega> {
  // Solo guardamos el estado de los filtros
  String _terminoBusqueda = '';
  String? _categoriaSeleccionada;

  // --- (Funciones de Lógica) ---

  Future<void> _registrarMovimiento(String nombreInsumo, int cantidad) async {
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
      'tipo': 'transferencia_bodega',
      'usuario_email': nombreUsuario,
      'fecha': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _ejecutarTransferencia(String insumoId, String nombreInsumo, int cantidad) async {
    final docInsumo = FirebaseFirestore.instance.collection('insumos').doc(insumoId);
    final batch = FirebaseFirestore.instance.batch();
    batch.update(docInsumo, {'stock_bodega': FieldValue.increment(-cantidad)});
    batch.update(docInsumo, {'stock_cafeteria': FieldValue.increment(cantidad)});

    try {
      await batch.commit();
      await _registrarMovimiento(nombreInsumo, cantidad);
      print('Transferencia exitosa');
    } catch (e) {
      print('Error en la transferencia: $e');
    }
  }

  void _mostrarDialogoTransferir(
    BuildContext context, 
    {required String insumoId, required String nombre, required int stockBodega}
  ) {
    final cantidadController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Transferir $nombre'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('¿Cuántas unidades mover de bodega a cafetería?'),
              Text(
  'Máximo disponible: $stockBodega',
  style: const TextStyle(fontWeight: FontWeight.bold),
),

              const SizedBox(height: 16),
              TextField(
                controller: cantidadController,
                decoration: const InputDecoration(labelText: 'Cantidad a transferir'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                final cantidad = int.tryParse(cantidadController.text) ?? 0;
                if (cantidad > 0 && cantidad <= stockBodega) {
                  Navigator.of(ctx).pop(); 
                  _ejecutarTransferencia(insumoId, nombre, cantidad);
                } else {
                  print('Cantidad no válida');
                }
              },
              child: const Text('Transferir'),
            ),
          ],
        );
      },
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
                hintText: 'Buscar en bodega...',
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
          
          // --- Barra de Filtros (¡Ahora sí, arreglada!) ---
          _buildCategoryFilters(),

          // --- Lista de Insumos (con StreamBuilder) ---
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
                  return const Center(child: Text('No hay insumos.'));
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
                    final stockBodega = data['stock_bodega'] ?? 0;
                    final unidad = data['unidad'] ?? 'uds.';

                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        title: Text(
                          nombre,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          'En bodega: $stockBodega $unidad',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        trailing: FilledButton.icon(
                          icon: const Icon(Icons.swap_horiz_rounded),
                          label: const Text('Transferir'),
                          onPressed: stockBodega > 0 
                              ? () {
                                  // ¡Esta llamada ahora sí es correcta!
                                  _mostrarDialogoTransferir(
                                    context, 
                                    insumoId: insumo.id,
                                    nombre: nombre,
                                    stockBodega: stockBodega,
                                  );
                                }
                              : null,
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
    );
  }

  // --- ¡AQUÍ ESTÁ EL ARREGLO 2! ---
  // Ahora el filtro de categorías usa SU PROPIO StreamBuilder
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
  // --- FIN DEL ARREGLO 2 ---
}