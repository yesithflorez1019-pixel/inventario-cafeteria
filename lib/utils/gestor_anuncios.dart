// lib/utils/gestor_anuncios.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GestorAnuncios {
  
  static Future<void> revisarAnuncios(BuildContext context, String rolUsuario) async {
    print('--- 🕵️‍♀️ INICIANDO DETECTIVE DE ANUNCIOS ---');
    print('1. Mi Rol es: "$rolUsuario"');

    try {
      final doc = await FirebaseFirestore.instance
          .collection('configuracion')
          .doc('anuncio')
          .get();

      if (!doc.exists) {
        print('❌ ERROR: No encuentro el documento "configuracion/anuncio" en Firebase.');
        return;
      }
      print('2. ¡Documento encontrado!');

      final data = doc.data() as Map<String, dynamic>;
      final bool activo = data['activo'] ?? false;
      print('3. ¿El anuncio está activo?: $activo');
      
      if (!activo) {
        print('⚠️ El anuncio está apagado (activo: false).');
        return;
      }

      final String destinatario = data['destinatario'] ?? 'todos';
      print('4. El mensaje es para: "$destinatario"');

      bool deboMostrarlo = false;
      if (destinatario == 'todos') {
        deboMostrarlo = true;
      } else if (destinatario == 'admin' && rolUsuario == 'admin') deboMostrarlo = true;
      else if (destinatario == 'trabajador' && rolUsuario == 'trabajador') deboMostrarlo = true;

      print('5. ¿Debo mostrarlo yo?: $deboMostrarlo');

      if (!deboMostrarlo) return;

      final String idAnuncio = data['id_anuncio'] ?? 'sin_id';
      final String titulo = data['titulo'] ?? 'Aviso';
      final String mensaje = data['mensaje'] ?? '';

      final prefs = await SharedPreferences.getInstance();
      final String ultimoIdVisto = prefs.getString('ultimo_anuncio_visto') ?? '';

      print('6. ID en Firebase: "$idAnuncio"');
      print('7. ID guardado en mi celular: "$ultimoIdVisto"');

      if (idAnuncio != ultimoIdVisto) {
        print('✅ ¡SÍ! Son diferentes. Intentando mostrar diálogo...');
        if (context.mounted) {
          await _mostrarDialogoAnuncio(context, titulo, mensaje);
          await prefs.setString('ultimo_anuncio_visto', idAnuncio);
          print('🎉 Diálogo mostrado y guardado.');
        } else {
          print('❌ ERROR: El contexto no está montado (la pantalla se cerró antes).');
        }
      } else {
        print('⛔ NO mostrar: Ya vi este anuncio antes.');
      }

    } catch (e) {
      print('❌ ERROR CRÍTICO: $e');
    }
  }

  static Future<void> _mostrarDialogoAnuncio(BuildContext context, String titulo, String mensaje) {
    return showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: const Color(0xFFFFF0F5),
        title: Row(
          children: [
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                titulo,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          mensaje,
          style: const TextStyle(fontSize: 16, height: 1.5),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('¡Entendido!'),
          ),
        ],
      ),
    );
  }
}