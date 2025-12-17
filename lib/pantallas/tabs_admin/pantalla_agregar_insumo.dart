// lib/pantallas/tabs_admin/pantalla_agregar_insumo.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class PantallaAgregarInsumo extends StatefulWidget {
  const PantallaAgregarInsumo({super.key});

  @override
  State<PantallaAgregarInsumo> createState() => _PantallaAgregarInsumoState();
}

class _PantallaAgregarInsumoState extends State<PantallaAgregarInsumo> {
  // Controladores para todos los campos
  final _nombreController = TextEditingController();
  final _categoriaController = TextEditingController();
  final _unidadController = TextEditingController();
  final _cafeteriaController = TextEditingController();
  final _bodegaController = TextEditingController();
  final _minimoController = TextEditingController();

  bool _estaGuardando = false;

  @override
  void dispose() {
    // Limpiamos los controladores
    _nombreController.dispose();
    _categoriaController.dispose();
    _unidadController.dispose();
    _cafeteriaController.dispose();
    _bodegaController.dispose();
    _minimoController.dispose();
    super.dispose();
  }

  // --- FUNCIÓN PARA GUARDAR EL INSUMO ---
  Future<void> _guardarInsumo() async {
    // 1. Validamos que los campos principales no estén vacíos
    final nombre = _nombreController.text.trim();
    final categoria = _categoriaController.text.trim();
    final unidad = _unidadController.text.trim();

    if (nombre.isEmpty || categoria.isEmpty || unidad.isEmpty) {
      // TODO: Mostrar error bonito
      print('Por favor llena los campos obligatorios: Nombre, Categoría, Unidad');
      return;
    }

    setState(() {
      _estaGuardando = true; // Mostramos indicador de carga
    });

    // 2. Leemos los números (con 0 por defecto)
    final stockCafeteria = int.tryParse(_cafeteriaController.text) ?? 0;
    final stockBodega = int.tryParse(_bodegaController.text) ?? 0;
    final stockMinimo = int.tryParse(_minimoController.text) ?? 5;

    try {
      // 3. Guardamos en Firebase
      await FirebaseFirestore.instance.collection('insumos').add({
        'nombre': nombre,
        'categoria': categoria,
        'unidad': unidad,
        'stock_cafeteria': stockCafeteria,
        'stock_bodega': stockBodega,
        'stock_minimo': stockMinimo,
      });
      
      // 4. Cerramos la pantalla si todo salió bien
      if (mounted) {
        Navigator.of(context).pop(); // Cierra la pantalla de agregar
      }

    } catch (e) {
      // TODO: Mostrar error bonito
      print('Error al guardar: $e');
      setState(() {
        _estaGuardando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nuevo Insumo'),
        // Botón para cerrar (X)
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        // Botón de Guardar en la barra
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: _estaGuardando 
              ? const Center(child: CircularProgressIndicator())
              : FilledButton(
                  onPressed: _guardarInsumo,
                  child: const Text('Guardar'),
                ),
          )
        ],
      ),
      // Usamos SingleChildScrollView para que no se rompa con el teclado
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              // Los TextFields ya toman el estilo "coquette"
              // que definimos en nuestro tema global
              _buildSectionTitle('Información Principal (Obligatorio)'),
              TextField(
                controller: _nombreController,
                decoration: const InputDecoration(labelText: 'Nombre del insumo'),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _categoriaController,
                decoration: const InputDecoration(labelText: 'Categoría (ej. Desechables)'),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _unidadController,
                decoration: const InputDecoration(labelText: 'Unidad (ej. Paquete, Caja, Lt)'),
                textInputAction: TextInputAction.next,
              ),

              const SizedBox(height: 32),
              _buildSectionTitle('Control de Stock (Opcional)'),
              TextField(
                controller: _cafeteriaController,
                decoration: const InputDecoration(labelText: 'Stock en Cafetería (Inicial)'),
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _bodegaController,
                decoration: const InputDecoration(labelText: 'Stock en Bodega (Inicial)'),
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _minimoController,
                decoration: const InputDecoration(labelText: 'Stock Mínimo (para alertas)'),
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                onEditingComplete: _guardarInsumo, // Llama a guardar al presionar "Done"
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Un widget bonito para separar las secciones
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