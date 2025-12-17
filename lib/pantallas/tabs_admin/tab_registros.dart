// lib/pantallas/tabs_admin/tab_registros.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; 

class TabRegistros extends StatelessWidget {
  const TabRegistros({super.key});

  String _formatearFecha(Timestamp timestamp) {
    final fecha = timestamp.toDate();
    final formato = DateFormat('d MMM, h:mm a', 'es'); 
    return formato.format(fecha);
  }

  Future<void> _eliminarRegistro(String registroId) async {
    try {
      await FirebaseFirestore.instance.collection('movimientos').doc(registroId).delete();
    } catch (e) {
      print('Error al eliminar registro: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('movimientos')
          .orderBy('fecha', descending: true) 
          .snapshots(),
      
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(
              color: Theme.of(context).colorScheme.primary,
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text(
              'No se han registrado movimientos',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18),
            ),
          );
        }

        final registros = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.all(8.0),
          itemCount: registros.length,
          itemBuilder: (context, index) {
            final registro = registros[index];
            final data = registro.data() as Map<String, dynamic>;

            final nombreProducto = data['insumo_nombre'] ?? 'Insumo borrado';
            final cantidad = data['cantidad'] ?? 0;
            // ¡AHORA SÍ LA VAMOS A USAR!
            final tipo = data['tipo'] ?? 'desconocido'; 
            final emailUsuario = data['usuario_email'] ?? '...';
            final fecha = data['fecha'] as Timestamp? ?? Timestamp.now(); 
            
            final esSuma = cantidad > 0;
            final icono = esSuma 
                ? Icons.arrow_upward_rounded 
                : Icons.arrow_downward_rounded;
            final color = esSuma ? Colors.green : Theme.of(context).colorScheme.primary;
            final textoCantidad = esSuma ? '+$cantidad' : '$cantidad';

            return Card(
              elevation: 1,
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              child: ListTile(
                leading: Icon(icono, color: color, size: 30),
                title: Text(
                  '$nombreProducto ($textoCantidad)',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                
                // --- ¡AQUÍ ESTÁ EL CAMBIO! ---
                // Ahora el subtítulo muestra el tipo de movimiento
                subtitle: Text(
                  'Por: $emailUsuario - Tipo: $tipo\n${_formatearFecha(fecha)}',
                ),
                // --- FIN DEL CAMBIO ---

                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.grey),
                  tooltip: 'Eliminar registro',
                  onPressed: () {
                    _eliminarRegistro(registro.id);
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }
}