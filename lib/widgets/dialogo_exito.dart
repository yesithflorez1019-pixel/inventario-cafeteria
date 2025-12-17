// lib/widgets/dialogo_exito.dart
import 'package:flutter/material.dart';

void mostrarDialogoExito(BuildContext context, String mensaje) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Row(
        children: [
          // Icono verde y feliz
          const SizedBox(width: 10),
          // Título de éxito
          const Text('¡Éxito!'), 
        ],
      ),
      content: Text(
        mensaje,
        style: const TextStyle(fontSize: 16),
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('Entendido'),
        ),
      ],
    ),
  );
}