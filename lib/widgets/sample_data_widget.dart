import 'package:flutter/material.dart';
import '../models/event_model.dart';
import '../controllers/event_controller.dart';

class SampleDataWidget extends StatelessWidget {
  final EventController eventController;

  const SampleDataWidget({super.key, required this.eventController});

  void _addSampleEvents() {
    final sampleEvents = [
      Event(
        id: '',
        title: 'Reunión Vecinal Mensual',
        description: 'Reunión mensual para discutir temas importantes de la comunidad, mejoras en las áreas comunes y próximos eventos.',
        date: DateTime.now().add(const Duration(days: 3)),
        location: 'Salón Comunal - Edificio Principal',
        organizer: 'Junta de Vecinos',
      ),
      Event(
        id: '',
        title: 'Festival de Primavera',
        description: 'Celebración anual con actividades para toda la familia, música en vivo, comida típica y juegos para niños.',
        date: DateTime.now().add(const Duration(days: 10)),
        location: 'Parque Central de la Comunidad',
        organizer: 'Comité Cultural',
      ),
      Event(
        id: '',
        title: 'Taller de Reciclaje',
        description: 'Aprende técnicas de reciclaje y reutilización para cuidar el medio ambiente. Trae materiales reciclables.',
        date: DateTime.now().add(const Duration(days: 7)),
        location: 'Centro Comunitario - Sala B',
        organizer: 'Grupo Ecológico',
      ),
      Event(
        id: '',
        title: 'Mercado de Pulgas',
        description: 'Venta de artículos usados, antigüedades y productos caseros. Perfecto para encontrar tesoros únicos.',
        date: DateTime.now().add(const Duration(days: 15)),
        location: 'Plaza Principal',
        organizer: 'Asociación de Comerciantes',
      ),
      Event(
        id: '',
        title: 'Clase de Yoga Comunitaria',
        description: 'Sesión de yoga gratuita para todos los niveles. Trae tu propia esterilla y ropa cómoda.',
        date: DateTime.now().add(const Duration(days: 2)),
        location: 'Jardín Comunal',
        organizer: 'Instructora Elena Martínez',
      ),
    ];

    for (final event in sampleEvents) {
      eventController.createEvent(event);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: _addSampleEvents,
      backgroundColor: Colors.orange,
      child: const Icon(Icons.data_usage),
    );
  }
}
