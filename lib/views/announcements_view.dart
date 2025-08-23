import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../controllers/announcement_controller.dart';
import '../controllers/auth_controller.dart';
import '../models/announcement_model.dart';
import 'announcement_detail_view.dart';
import 'create_announcement_view.dart';
import 'announcement_moderation_view.dart';

class AnnouncementsView extends StatefulWidget {
  const AnnouncementsView({super.key});

  @override
  State<AnnouncementsView> createState() => _AnnouncementsViewState();
}

class _AnnouncementsViewState extends State<AnnouncementsView>
    with TickerProviderStateMixin {
  late TabController _tabController;
  AnnouncementType? _selectedType;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    print('🔥 VIEW DEBUG: AnnouncementsView inicializada');
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final announcementController = Provider.of<AnnouncementController>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Muro de Anuncios'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          // Botón Admin solo para administradores
          Consumer<AuthController>(
            builder: (context, authController, child) {
              // Debug info
              if (kDebugMode) {
                print('🔐 AUTH DEBUG: Usuario actual: ${authController.currentUser?.email}');
                print('🔐 AUTH DEBUG: Rol: ${authController.currentUser?.role}');
                print('🔐 AUTH DEBUG: Es admin: ${authController.isAdmin}');
              }
              
              // Lógica de admin: usar rol oficial O fallback por email
              final isOfficialAdmin = authController.isAdmin;
              final email = authController.currentUser?.email ?? '';
              final isFallbackAdmin = email == 'admin@comunity.com' || 
                                    email.contains('admin@') ||
                                    email.contains('@admin.');
              
              final canAccessAdmin = isOfficialAdmin || isFallbackAdmin;
              
              if (!canAccessAdmin) return const SizedBox.shrink();
              
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AnnouncementModerationView(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.pending_actions, size: 18),
                  label: const Text('REVISAR'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  ),
                ),
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          onTap: (index) {
            setState(() {
              switch (index) {
                case 0:
                  _selectedType = null;
                  break;
                case 1:
                  _selectedType = AnnouncementType.sale;
                  break;
                case 2:
                  _selectedType = AnnouncementType.wanted;
                  break;
                case 3:
                  _selectedType = AnnouncementType.service;
                  break;
                case 4:
                  _selectedType = AnnouncementType.general;
                  break;
                case 5:
                  _selectedType = AnnouncementType.community;
                  break;
              }
            });
          },
          tabs: const [
            Tab(text: 'Todos', icon: Icon(Icons.all_inclusive)),
            Tab(text: 'Se Vende', icon: Icon(Icons.sell)),
            Tab(text: 'Se Busca', icon: Icon(Icons.search)),
            Tab(text: 'Servicios', icon: Icon(Icons.build)),
            Tab(text: 'General', icon: Icon(Icons.announcement)),
            Tab(text: 'Comunidad', icon: Icon(Icons.people)),
          ],
        ),
      ),
      body: StreamBuilder<List<Announcement>>(
        stream: announcementController.getApprovedAnnouncements(
          filterType: _selectedType,
        ),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('¡Ocurrió un error al cargar los anuncios!'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final announcements = snapshot.data ?? [];

          if (announcements.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.announcement_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No hay anuncios disponibles',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _selectedType == null 
                        ? 'Sé el primero en publicar un anuncio'
                        : 'No hay anuncios de este tipo',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {}); // Forzar rebuild del stream
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: announcements.length,
              itemBuilder: (context, index) {
                final announcement = announcements[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                  elevation: 2,
                  child: ListTile(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AnnouncementDetailView(announcement: announcement),
                        ),
                      );
                    },
                    title: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getTypeColor(announcement.type),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _getTypeLabel(announcement.type),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (announcement.isUrgent)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'URGENTE',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        const Spacer(),
                        Text(
                          DateFormat('dd/MM/yy').format(announcement.createdAt),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          announcement.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          announcement.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.person, size: 16, color: Colors.blue),
                            const SizedBox(width: 4),
                            Text(
                              announcement.authorName,
                              style: const TextStyle(color: Colors.blue),
                            ),
                            if (announcement.price != null) ...[
                              const SizedBox(width: 16),
                              const Icon(Icons.attach_money, size: 16, color: Colors.green),
                              const SizedBox(width: 4),
                              Text(
                                NumberFormat.currency(
                                  locale: 'es_CO',
                                  symbol: '\$',
                                  decimalDigits: 0,
                                ).format(announcement.price),
                                style: const TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                    isThreeLine: true,
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: "add_announcement",
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CreateAnnouncementView(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Color _getTypeColor(AnnouncementType type) {
    switch (type) {
      case AnnouncementType.sale:
        return Colors.green;
      case AnnouncementType.wanted:
        return Colors.blue;
      case AnnouncementType.service:
        return Colors.orange;
      case AnnouncementType.general:
        return Colors.grey;
      case AnnouncementType.community:
        return Colors.purple;
    }
  }

  String _getTypeLabel(AnnouncementType type) {
    switch (type) {
      case AnnouncementType.sale:
        return 'SE VENDE';
      case AnnouncementType.wanted:
        return 'SE BUSCA';
      case AnnouncementType.service:
        return 'SERVICIO';
      case AnnouncementType.general:
        return 'GENERAL';
      case AnnouncementType.community:
        return 'COMUNIDAD';
    }
  }
}

class AnnouncementSearchDelegate extends SearchDelegate {
  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        onPressed: () {
          query = '';
        },
        icon: const Icon(Icons.clear),
      ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      onPressed: () {
        close(context, null);
      },
      icon: const Icon(Icons.arrow_back),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return Consumer<AnnouncementController>(
      builder: (context, controller, child) {
        return StreamBuilder<List<Announcement>>(
          stream: controller.getApprovedAnnouncements(searchQuery: query),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Text('Error: ${snapshot.error}'),
              );
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(
                child: Text('No se encontraron anuncios'),
              );
            }

            return ListView.builder(
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                final announcement = snapshot.data![index];
                return ListTile(
                  title: Text(announcement.title),
                  subtitle: Text(announcement.description),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AnnouncementDetailView(announcement: announcement),
                      ),
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return const Center(
      child: Text('Escribe para buscar anuncios...'),
    );
  }
}
