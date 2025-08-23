import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/event_controller.dart';
import '../controllers/auth_controller.dart';
import '../models/event_model.dart';
import 'package:intl/intl.dart';
import 'party_finance_view.dart';

class PartiesView extends StatelessWidget {
  const PartiesView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Fiestas y Celebraciones',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Consumer2<EventController, AuthController>(
        builder: (context, eventController, authController, child) {
          return StreamBuilder<List<Event>>(
            stream: eventController.getEvents(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.celebration,
                        size: 80,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No hay fiestas programadas',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '¡Organiza la próxima celebración!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                );
              }

              // Filtrar eventos que contengan palabras relacionadas con fiestas
              final partyKeywords = ['fiesta', 'celebración', 'cumpleaños', 'aniversario', 
                                  'festival', 'party', 'baile', 'dj', 'música', 'karaoke'];
              
              final partyEvents = snapshot.data!.where((event) {
                final searchText = '${event.title} ${event.description}'.toLowerCase();
                return partyKeywords.any((keyword) => searchText.contains(keyword));
              }).toList();

              if (partyEvents.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.celebration_outlined,
                        size: 80,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No hay fiestas en este momento',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Busca eventos con palabras como "fiesta", "celebración", "cumpleaños"',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(8.0),
                itemCount: partyEvents.length,
                itemBuilder: (context, index) {
                  final event = partyEvents[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                    elevation: 3,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: LinearGradient(
                          colors: [
                            Colors.purple.withOpacity(0.1),
                            Colors.pink.withOpacity(0.1),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: ListTile(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PartyFinanceView(party: event),
                            ),
                          );
                        },
                        leading: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.purple.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.celebration,
                            color: Colors.purple,
                            size: 24,
                          ),
                        ),
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
                            Text(
                              event.description,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(Icons.access_time, size: 16, color: Colors.purple),
                                const SizedBox(width: 4),
                                Text(
                                  DateFormat('d MMM, HH:mm', 'es').format(event.date),
                                  style: const TextStyle(color: Colors.purple, fontSize: 12),
                                ),
                                const SizedBox(width: 16),
                                const Icon(Icons.people, size: 16, color: Colors.pink),
                                const SizedBox(width: 4),
                                Text(
                                  '${event.attendees.length} asistentes',
                                  style: const TextStyle(color: Colors.pink, fontSize: 12),
                                ),
                              ],
                            ),
                          ],
                        ),
                        trailing: Consumer<AuthController>(
                          builder: (context, authController, child) {
                            if (authController.currentUser == null) {
                              return const SizedBox.shrink();
                            }
                            
                            return Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                FutureBuilder<bool>(
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
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
