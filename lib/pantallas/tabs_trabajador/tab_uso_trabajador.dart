// lib/pantallas/tabs_trabajador/tab_uso_trabajador.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

// ¡Importamos el diálogo de error y la pantalla de login!
import 'package:cafeteria_inventario/widgets/dialogo_error.dart';
import 'package:cafeteria_inventario/pantallas/pantalla_login.dart';

class TabUsoTrabajador extends StatefulWidget {
  const TabUsoTrabajador({super.key});

  @override
  State<TabUsoTrabajador> createState() => _TabUsoTrabajadorState();
}

class _TabUsoTrabajadorState extends State<TabUsoTrabajador> {
  String _terminoBusqueda = '';
  String? _categoriaSeleccionada;

  // --- ¡NUEVA SÚPER FUNCIÓN DE SEGURIDAD! ---
  Future<void> _intentarUsarInsumo(String insumoId, String nombreInsumo) async {
    final usuario = FirebaseAuth.instance.currentUser;
    if (usuario == null) {
      _forzarCierreSesion('Tu sesión ha expirado.');
      return;
    }

    try {
      // 1. Revisamos el "interruptor" en Firestore
      final docUsuario = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(usuario.uid)
          .get();
      
      final bool estaActivo = docUsuario.data()?['activo'] ?? true; // Si no existe, es 'true'

      // 2. ¡EL BLOQUEO!
      if (!estaActivo) {
        _forzarCierreSesion('Tu cuenta ha sido desactivada. Contacta al administrador.');
        return; // ¡No lo dejamos continuar!
      }

      // 3. Si está activo, procede normalmente
      await _actualizarStockCafeteria(insumoId);
      await _registrarMovimiento(nombreInsumo, usuario); // Le pasamos el usuario

    } catch (e) {
      // Si hay un error de red, le avisamos
      print('Error al verificar status: $e');
      if (mounted) {
        mostrarDialogoError(context, 'No se pudo registrar el uso. Revisa tu conexión a internet.');
      }
    }
  }

  // --- ¡NUEVO! Función para sacarlo de la app ---
  Future<void> _forzarCierreSesion(String mensaje) async {
    if (mounted) {
      mostrarDialogoError(context, mensaje);
    }
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const PantallaLogin()),
        (Route<dynamic> route) => false,
      );
    }
  }


  Future<void> _actualizarStockCafeteria(String insumoId) async {
    final docRef = FirebaseFirestore.instance.collection('insumos').doc(insumoId);
    docRef.update({'stock_cafeteria': FieldValue.increment(-1)});
  }

  // (Ahora recibe el "User" para no tener que buscarlo 2 veces)
  Future<void> _registrarMovimiento(String nombreInsumo, User usuario) async {
    String nombreUsuario = usuario.email ?? 'trabajador';
    try {
      final docUsuario = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(usuario.uid)
          .get();
      if (docUsuario.exists) {
        nombreUsuario = docUsuario.data()?['nombre'] ?? nombreUsuario;
      }
    } catch (e) { /* Ya lo manejamos arriba */ }

    FirebaseFirestore.instance.collection('movimientos').add({
      'insumo_nombre': nombreInsumo,
      'cantidad': -1,
      'tipo': 'uso_cafeteria', 
      'usuario_email': nombreUsuario,
      'fecha': FieldValue.serverTimestamp(), 
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // ... (La barra de Búsqueda y Filtros va aquí, sin cambios) ...
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
          _buildCategoryFilters(),

          // ... (El StreamBuilder va aquí, sin cambios) ...
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('insumos') 
                  .where('stock_cafeteria', isGreaterThan: 0) 
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
                  return const Center(
                    child: Text('No hay insumos con stock.',
                      style: TextStyle(fontSize: 18),
                    ),
                  );
                }
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

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  itemCount: insumosFiltrados.length,
                  itemBuilder: (context, index) {
                    final insumo = insumosFiltrados[index];
                    final data = insumo.data() as Map<String, dynamic>;

                    final nombre = data['nombre'] ?? 'Sin nombre';
                    final stockCafeteria = data['stock_cafeteria'] ?? 0;
                    final unidad = data['unidad'] ?? 'uds.';

                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    nombre,
                                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                                    maxLines: 1, 
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '$stockCafeteria $unidad',
                                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                          color: Colors.grey.shade700,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16), 
                            FilledButton.icon(
                              icon: const Icon(Icons.remove, size: 18), 
                              label: const Text('Usar 1', style: TextStyle(fontSize: 14)), 
                              style: FilledButton.styleFrom(
                                backgroundColor: Theme.of(context).colorScheme.primary,
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10), 
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10), 
                                ),
                              ),
                              // --- ¡CAMBIO! Ahora llama a la función de seguridad ---
                              onPressed: () {
                                _intentarUsarInsumo(insumo.id, nombre);
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
    );
  }
  
  // --- (Widget _buildCategoryFilters - sigue igual) ---
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
                  label: const Text('Todas'), // ¡Le quité el emoji!
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