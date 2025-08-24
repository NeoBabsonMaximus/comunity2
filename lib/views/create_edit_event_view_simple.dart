import 'package:flutter/material.dart';
import '../models/event_model.dart';

// Versión simplificada temporal para debugging
class CreateEditEventView extends StatelessWidget {
  final Event? event;

  const CreateEditEventView({super.key, this.event});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(event == null ? 'Crear Evento' : 'Editar Evento'),
      ),
      body: const Center(
        child: Text('Formulario Temporal - En Desarrollo'),
      ),
    );
  }
}
