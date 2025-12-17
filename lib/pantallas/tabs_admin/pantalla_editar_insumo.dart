// lib/pantallas/tabs_admin/pantalla_editar_insumo.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class PantallaEditarInsumo extends StatefulWidget {
  final DocumentSnapshot insumo;
  
  const PantallaEditarInsumo({super.key, required this.insumo});

  @override
  State<PantallaEditarInsumo> createState() => _PantallaEditarInsumoState();
}

class _PantallaEditarInsumoState extends State<PantallaEditarInsumo> {
  // Controladores para la INFO
  late TextEditingController _nombreController;
  late TextEditingController _categoriaController;
  late TextEditingController _unidadController;
  late TextEditingController _minimoController;

  // Controladores para AGREGAR STOCK (Compra)
  final _agregarCafeteriaController = TextEditingController();
  final _agregarBodegaController = TextEditingController();

  bool _estaGuardando = false;

  @override
  void initState() {
    super.initState();
    final data = widget.insumo.data() as Map<String, dynamic>;
    
    _nombreController = TextEditingController(text: data['nombre'] ?? '');
    _categoriaController = TextEditingController(text: data['categoria'] ?? '');
    _unidadController = TextEditingController(text: data['unidad'] ?? '');
    _minimoController = TextEditingController(text: (data['stock_minimo'] ?? 0).toString());
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _categoriaController.dispose();
    _unidadController.dispose();
    _minimoController.dispose();
    _agregarCafeteriaController.dispose();
    _agregarBodegaController.dispose();
    super.dispose();
  }

  Future<void> _guardarCambios() async {
    setState(() { _estaGuardando = true; });

    // 1. Leemos los campos de texto
    final nombre = _nombreController.text.trim();
    final categoria = _categoriaController.text.trim();
    final unidad = _unidadController.text.trim();
    final stockMinimo = int.tryParse(_minimoController.text) ?? 5;
    
    // 2. Leemos la cantidad a AGREGAR (Compra)
    final agregarCafeteria = int.tryParse(_agregarCafeteriaController.text) ?? 0;
    final agregarBodega = int.tryParse(_agregarBodegaController.text) ?? 0;

    // 3. Obtenemos la referencia al documento
    final docRef = FirebaseFirestore.instance.collection('insumos').doc(widget.insumo.id);
    final emailUsuario = FirebaseAuth.instance.currentUser?.email ?? 'admin';

    // Usamos un Lote (Batch) para hacer todas las operaciones juntas
    final batch = FirebaseFirestore.instance.batch();

    try {
      // 4. Operación 1: Actualizar la info del insumo
      batch.update(docRef, {
        'nombre': nombre,
        'categoria': categoria,
        'unidad': unidad,
        'stock_minimo': stockMinimo,
        // Incrementamos los stocks con los valores de la compra
        'stock_cafeteria': FieldValue.increment(agregarCafeteria),
        'stock_bodega': FieldValue.increment(agregarBodega),
      });

      // 5. Operación 2: Registrar el movimiento si se agregó a cafetería
      if (agregarCafeteria > 0) {
        final movRef = FirebaseFirestore.instance.collection('movimientos').doc();
        batch.set(movRef, {
          'insumo_nombre': nombre,
          'cantidad': agregarCafeteria,
          'tipo': 'compra_cafeteria', // Nuevo tipo
          'usuario_email': emailUsuario,
          'fecha': FieldValue.serverTimestamp(),
        });
      }
      
      // 6. Operación 3: Registrar el movimiento si se agregó a bodega
      if (agregarBodega > 0) {
        final movRef = FirebaseFirestore.instance.collection('movimientos').doc();
        batch.set(movRef, {
          'insumo_nombre': nombre,
          'cantidad': agregarBodega,
          'tipo': 'compra_bodega', // Nuevo tipo
          'usuario_email': emailUsuario,
          'fecha': FieldValue.serverTimestamp(),
        });
      }

      // 7. Ejecutamos todas las operaciones
      await batch.commit();

      if (mounted) {
        Navigator.of(context).pop(); // Cerramos la pantalla de editar
      }

    } catch (e) {
      print('Error al guardar: $e');
      setState(() { _estaGuardando = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Obtenemos los stocks actuales y la unidad
    final data = widget.insumo.data() as Map<String, dynamic>;
    final stockCafeteria = data['stock_cafeteria'] ?? 0;
    final stockBodega = data['stock_bodega'] ?? 0;
    final unidad = data['unidad'] ?? 'uds.'; // Tomamos la unidad

    return Scaffold(
      appBar: AppBar(
        title: Text('Editar ${_nombreController.text}'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: _estaGuardando 
              ? const Center(child: CircularProgressIndicator())
              : FilledButton(
                  onPressed: _guardarCambios,
                  child: const Text('Guardar'),
                ),
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, // Alineamos títulos
            children: [
              _buildSectionTitle('Información del Insumo'),
              TextField(
                controller: _nombreController,
                decoration: const InputDecoration(labelText: 'Nombre del insumo'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _categoriaController,
                decoration: const InputDecoration(labelText: 'Categoría'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _unidadController,
                decoration: const InputDecoration(labelText: 'Unidad'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _minimoController,
                decoration: const InputDecoration(labelText: 'Stock Mínimo (Alertas)'),
                keyboardType: TextInputType.number,
              ),

              const SizedBox(height: 32),
              
              // --- ¡AQUÍ ESTÁ EL ARREGLO! ---
              _buildSectionTitle('Registrar Compra (Opcional)'),
              TextField(
                controller: _agregarCafeteriaController,
                decoration: InputDecoration(
                  labelText: 'Agregar a Cafetería (Compra)',
                  // ¡Cambiado a helperText para que sea SIEMPRE visible!
                  helperText: 'Stock actual: $stockCafeteria $unidad', 
                  helperStyle: const TextStyle(fontSize: 14),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 24), // Más espacio
              TextField(
                controller: _agregarBodegaController,
                decoration: InputDecoration(
                  labelText: 'Agregar a Bodega (Compra)',
                  // ¡Cambiado a helperText para que sea SIEMPRE visible!
                  helperText: 'Stock actual: $stockBodega $unidad',
                  helperStyle: const TextStyle(fontSize: 14),
                ),
                keyboardType: TextInputType.number,
              ),
              // --- FIN DEL ARREGLO ---
            ],
          ),
        ),
      ),
    );
  }

  // Widget para los títulos bonitos
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}