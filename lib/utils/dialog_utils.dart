import 'package:flutter/material.dart';
import '../models/task.dart';
import '../providers/app_state.dart';

Future<void> confirmAndCompleteTask(
  BuildContext context,
  Task task,
  AppState appState,
) async {
  if (task.completed) {
    // If already completed, toggle back to pending immediately without confirmation
    await appState.toggleTaskCompleted(task);
    return;
  }

  final theme = Theme.of(context);
  final confirm = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      icon: Icon(
        Icons.check_circle_outline_rounded,
        size: 48,
        color: theme.colorScheme.primary,
      ),
      title: const Text(
        'Confirmar tarea completada',
        textAlign: TextAlign.center,
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      content: const Text(
        '¿Ya terminaste esta tarea?',
        textAlign: TextAlign.center,
      ),
      actionsAlignment: MainAxisAlignment.spaceEvenly,
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('No, cancelar'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: theme.colorScheme.onPrimary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text('Sí, completar'),
        ),
      ],
    ),
  );

  if (confirm == true) {
    await appState.toggleTaskCompleted(task);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Tarea completada correctamente.'),
          backgroundColor: theme.colorScheme.primary,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
}
