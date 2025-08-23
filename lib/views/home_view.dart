import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/event_controller.dart';
import '../controllers/auth_controller.dart';
import '../models/event_model.dart';
import 'package:intl/intl.dart';
import 'create_edit_event_view.dart';
import 'event_detail_view.dart';
import '../widgets/calendar_header_widget.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  DateTime _selectedDate = DateTime.now();

  List<Event> _filterEventsByDate(List<Event> events) {
    return events.where((event) {
      return event.date.year == _selectedDate.year &&
          event.date.month == _selectedDate.month &&
          event.date.day == _selectedDate.day;
    }).toList();
  }

  void _addSampleEvents(EventController eventController) {
    final sampleEvents = [
      Event(
        id: '',
        title: '🎉 Festival de Primavera',
        description: 'Celebración anual con música, comida y actividades familiares.',
        date: DateTime.now().add(const Duration(days: 2)),
        location: 'Parque Central',
        organizer: 'Comité Cultural',
      ),
      Event(
        id: '',
        title: '📚 Taller de Reciclaje',
        description: 'Aprende técnicas de reciclaje para cuidar el medio ambiente.',
        date: DateTime.now().add(const Duration(days: 1)),
        location: 'Centro Comunitario',
        organizer: 'Grupo Ecológico',
      ),
      Event(
        id: '',
        title: '🧘 Yoga Comunitario',
        description: 'Sesión de yoga gratuita para todos los niveles.',
        date: DateTime.now(),
        location: 'Jardín Comunal',
        organizer: 'Elena Martínez',
      ),
    ];
    
    for (final event in sampleEvents) {
      eventController.createEvent(event);
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('¡Eventos de ejemplo agregados!'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final eventController = Provider.of<EventController>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Eventos Comunitarios'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: StreamBuilder<List<Event>>(
        stream: eventController.getEvents(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('¡Ocurrió un error!'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final allEvents = snapshot.data ?? [];
          final eventsForSelectedDate = _filterEventsByDate(allEvents);

          return Column(
            children: [
              // Widget del calendario
              CalendarHeaderWidget(
                events: allEvents,
                selectedDate: _selectedDate,
                onDateSelected: (date) {
                  setState(() {
                    _selectedDate = date;
                  });
                },
              ),
              const Divider(height: 1),
              // Lista de eventos
              Expanded(
                child: eventsForSelectedDate.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.event_busy,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No hay eventos para esta fecha',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              DateFormat('EEEE, d MMMM yyyy', 'es').format(_selectedDate),
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(8.0),
                        itemCount: eventsForSelectedDate.length,
                        itemBuilder: (context, index) {
                          final event = eventsForSelectedDate[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                            elevation: 2,
                            child: ListTile(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => EventDetailView(event: event),
                                  ),
                                );
                              },
                              title: Text(
                                event.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text(event.description, maxLines: 2, overflow: TextOverflow.ellipsis),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(Icons.access_time, size: 16, color: Colors.blue),
                                      const SizedBox(width: 4),
                                      Text(
                                        DateFormat('HH:mm').format(event.date),
                                        style: const TextStyle(color: Colors.blue),
                                      ),
                                      const SizedBox(width: 16),
                                      const Icon(Icons.location_on, size: 16, color: Colors.green),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          event.location,
                                          style: const TextStyle(color: Colors.green),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Consumer<AuthController>(
                                    builder: (context, authController, child) {
                                      if (authController.currentUser == null) {
                                        return const SizedBox.shrink();
                                      }
                                      
                                      return FutureBuilder<bool>(
                                        future: eventController.isFavoriteForUser(event.id, authController.currentUser!.uid),
                                        builder: (context, snapshot) {
                                          bool isFavorite = snapshot.data ?? false;
                                          return IconButton(
                                            icon: Icon(
                                              isFavorite ? Icons.favorite : Icons.favorite_border,
                                              color: isFavorite ? Colors.red : Colors.grey,
                                            ),
                                            onPressed: () {
                                              eventController.toggleFavorite(event.id, authController.currentUser!.uid);
                                            },
                                          );
                                        },
                                      );
                                    },
                                  ),
                                  Consumer<AuthController>(
                                    builder: (context, authController, child) {
                                      if (authController.currentUser?.canCreateEvents == true) {
                                        return PopupMenuButton<String>(
                                          onSelected: (value) async {
                                            switch (value) {
                                              case 'edit':
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) => CreateEditEventView(event: event),
                                                  ),
                                                );
                                                break;
                                              case 'delete':
                                                final confirm = await showDialog<bool>(
                                                  context: context,
                                                  builder: (context) => AlertDialog(
                                                    title: const Text('Eliminar evento'),
                                                    content: const Text('¿Estás seguro?'),
                                                    actions: [
                                                      TextButton(
                                                        onPressed: () => Navigator.pop(context, false),
                                                        child: const Text('Cancelar'),
                                                      ),
                                                      TextButton(
                                                        onPressed: () => Navigator.pop(context, true),
                                                        style: TextButton.styleFrom(foregroundColor: Colors.red),
                                                        child: const Text('Eliminar'),
                                                      ),
                                                    ],
                                                  ),
                                                );
                                                if (confirm == true && mounted) {
                                                  await eventController.deleteEvent(event.id);
                                                }
                                                break;
                                            }
                                          },
                                          itemBuilder: (context) => [
                                            const PopupMenuItem(
                                              value: 'edit',
                                              child: Row(
                                                children: [
                                                  Icon(Icons.edit, color: Colors.blue),
                                                  SizedBox(width: 8),
                                                  Text('Editar'),
                                                ],
                                              ),
                                            ),
                                            const PopupMenuItem(
                                              value: 'delete',
                                              child: Row(
                                                children: [
                                                  Icon(Icons.delete, color: Colors.red),
                                                  SizedBox(width: 8),
                                                  Text('Eliminar'),
                                                ],
                                              ),
                                            ),
                                          ],
                                        );
                                      }
                                      return const SizedBox.shrink();
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: Consumer<AuthController>(
        builder: (context, authController, child) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FloatingActionButton(
                heroTag: "sample_data",
                onPressed: () => _addSampleEvents(eventController),
                backgroundColor: Colors.orange,
                child: const Icon(Icons.add_box),
              ),
              const SizedBox(height: 8),
              if (authController.currentUser?.canCreateEvents == true)
                FloatingActionButton(
                  heroTag: "add_event",
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CreateEditEventView(),
                      ),
                    );
                  },
                  child: const Icon(Icons.add),
                ),
            ],
          );
        },
      ),
    );
  }
}
