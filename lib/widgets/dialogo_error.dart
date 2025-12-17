// lib/widgets/dialogo_error.dart
import 'package:flutter/material.dart';

void mostrarDialogoError(BuildContext context, String mensaje) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Row(
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 10),
          const Text('Importante'),
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