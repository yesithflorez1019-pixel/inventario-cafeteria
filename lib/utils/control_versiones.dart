// lib/utils/control_versiones.dart

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';

class ControlVersiones {
  
  static Future<bool> verificarActualizacion(BuildContext context) async {
    try {
      final PackageInfo info = await PackageInfo.fromPlatform();
      final String versionInstalada = info.version; 
      print("🔎 Versión instalada: $versionInstalada");

      final doc = await FirebaseFirestore.instance.collection('configuracion').doc('version_app').get();

      if (!doc.exists) return false;

      final data = doc.data() as Map<String, dynamic>;
      final String versionNueva = data['version_actual'] ?? '1.0.0';
      final String linkDescarga = data['link_descarga'] ?? '';
      final bool esObligatorio = data['es_obligatorio'] ?? false;

      print("✨ Versión en Nube: $versionNueva");

      // Comparación simple de strings (funciona si usas formato 1.0.1)
      if (versionInstalada != versionNueva && esObligatorio) {
        if (context.mounted) {
          // Llamamos al nuevo Widget Dialogo
          showDialog(
            context: context,
            barrierDismissible: false, // No se puede cerrar tocando afuera
            builder: (context) => DialogoActualizacion(url: linkDescarga, version: versionNueva),
          );
          return true; // Bloquea el resto de la app
        }
      }
      return false;

    } catch (e) {
      print('Error verificando versión: $e');
      return false;
    }
  }
}

// ---------------------------------------------------------------------------
//  WIDGET INDEPENDIENTE PARA LA DESCARGA (Más estable que StatefulBuilder)
// ---------------------------------------------------------------------------

class DialogoActualizacion extends StatefulWidget {
  final String url;
  final String version;

  const DialogoActualizacion({super.key, required this.url, required this.version});

  @override
  State<DialogoActualizacion> createState() => _DialogoActualizacionState();
}

class _DialogoActualizacionState extends State<DialogoActualizacion> {
  
  double _progreso = 0.0;
  bool _descargando = false;
  String _mensaje = "Se requiere actualización obligatoria";
  String _textoBoton = "DESCARGAR AHORA";
  Color _colorMensaje = Colors.black;

  Future<void> _iniciarDescarga() async {
    // 1. CAMBIO VISUAL INMEDIATO
    print("👉 Botón presionado. Iniciando...");
    setState(() {
      _descargando = true;
      _mensaje = "Conectando con el servidor...";
      _textoBoton = "Espere...";
      _colorMensaje = Colors.black;
    });

    try {
      // 2. Definir ruta (Carpeta Temporal es la más segura)
      final Directory tempDir = await getTemporaryDirectory();
      final String rutaGuardado = '${tempDir.path}/update_cafeteria.apk';
      
      print("📂 Guardando en: $rutaGuardado");

      // Limpiar archivo previo
      final file = File(rutaGuardado);
      if (await file.exists()) {
        await file.delete();
      }

      // 3. Descargar
      await Dio().download(
        widget.url, 
        rutaGuardado,
        onReceiveProgress: (recibido, total) {
          if (total != -1) {
            // Actualizamos la UI solo si el widget sigue vivo
            if (mounted) {
              setState(() {
                _progreso = recibido / total;
                if (_progreso > 0) {
                   _mensaje = "Descargando: ${(_progreso * 100).toStringAsFixed(0)}%";
                }
              });
            }
          }
        },
      );

      print("✅ Descarga finalizada al 100%");

      // 4. Validar que no sea basura (HTML de error)
      final int peso = await file.length();
      print("📦 Peso del archivo: $peso bytes");

      if (peso < 1000000) { // Menos de 1MB es sospechoso
        if (mounted) {
          setState(() {
            _mensaje = "Error: El enlace de descarga está roto o denegado.";
            _colorMensaje = Colors.red;
            _descargando = false;
            _textoBoton = "REINTENTAR";
          });
        }
        return;
      }

      // 5. Instalar
      if (mounted) {
        setState(() { _mensaje = "Abriendo instalador..."; });
      }

      print("💿 Ejecutando OpenFilex...");
      final result = await OpenFilex.open(rutaGuardado, type: "application/vnd.android.package-archive");
      print("Resultado OpenFile: ${result.message}");

    } catch (e) {
      print("❌ Error Fatal: $e");
      if (mounted) {
        setState(() {
          _mensaje = "Ocurrió un error: $e";
          _colorMensaje = Colors.red;
          _descargando = false;
          _textoBoton = "REINTENTAR";
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
  return PopScope(
    canPop: false,
    child: AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          const Icon(
            Icons.system_update_alt,
            color: Color(0xFFFBC02D),
            size: 30,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              "Actualización v${widget.version}",
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFFF9A825),
              ),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _mensaje,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: _colorMensaje,
            ),
          ),
          const SizedBox(height: 20),

          if (_descargando)
            
            Column(
              children: [
                _progreso == 0
                    ? const LinearProgressIndicator(
                        color: Color(0xFFFBC02D),
                        backgroundColor: Color(0xFFFFF9C4),
                      )
                    : LinearProgressIndicator(
                        value: _progreso,
                        color: Color(0xFFFBC02D),
                        backgroundColor: Color(0xFFFFF176),
                        minHeight: 10,
                        borderRadius: BorderRadius.circular(6),
                      ),
                const SizedBox(height: 6),
                if (_progreso > 0)
                  Text(
                    "${(_progreso * 100).toStringAsFixed(0)}%",
                    style: const TextStyle(
                      color: Color(0xFFF9A825),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            )
          else
            const Icon(
              Icons.cloud_download_outlined,
              size: 60,
              color: Color(0xFFFFF176),
            ),
        ],
      ),
      actions: [
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFFBC02D),
              disabledBackgroundColor: const Color(0xFFFFF176),
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: _descargando ? null : _iniciarDescarga,
            child: Text(
              _textoBoton,
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

}