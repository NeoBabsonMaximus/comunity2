import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/announcement_controller.dart';
import '../controllers/auth_controller.dart';
import '../models/announcement_model.dart';
import 'announcement_detail_view.dart';

class AnnouncementModerationView extends StatefulWidget {
  const AnnouncementModerationView({super.key});

  @override
  State<AnnouncementModerationView> createState() => _AnnouncementModerationViewState();
}

class _AnnouncementModerationViewState extends State<AnnouncementModerationView>
    with TickerProviderStateMixin {
  late TabController _tabController;
  Map<String, int> _stats = {};
  bool _isLoadingStats = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadStats();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AnnouncementController>(context, listen: false).loadAnnouncements();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadStats() async {
    final controller = Provider.of<AnnouncementController>(context, listen: false);
    final stats = await controller.getAnnouncementStats();
    setState(() {
      _stats = stats;
      _isLoadingStats = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthController>(
      builder: (context, auth, child) {
        // Lógica de admin consistente con AnnouncementsView
        final isOfficialAdmin = auth.isAdmin;
        final email = auth.currentUser?.email ?? '';
        final isFallbackAdmin = email == 'admin@comunity.com' || 
                              email.contains('admin@') ||
                              email.contains('@admin.');
        
        final canAccessAdmin = isOfficialAdmin || isFallbackAdmin;
        
        if (!canAccessAdmin) {
          return Scaffold(
            appBar: AppBar(title: const Text('Acceso Denegado')),
            body: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.block, size: 64, color: Colors.red),
                  SizedBox(height: 16),
                  Text(
                    'No tienes permisos para acceder a esta sección',
                    style: TextStyle(fontSize: 18),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 8),
                  Text('Solo los administradores pueden moderar anuncios'),
                ],
              ),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Moderación de Anuncios'),
            bottom: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabs: [
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.pending_actions),
                      const SizedBox(width: 8),
                      Text('Pendientes ${_stats['pending'] ?? 0}'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle),
                      const SizedBox(width: 8),
                      Text('Aprobados ${_stats['approved'] ?? 0}'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.cancel),
                      const SizedBox(width: 8),
                      Text('Rechazados ${_stats['rejected'] ?? 0}'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.bar_chart),
                      const SizedBox(width: 8),
                      const Text('Estadísticas'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          body: _isLoadingStats
              ? const Center(child: CircularProgressIndicator())
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildAnnouncementsList(AnnouncementStatus.pending),
                    _buildAnnouncementsList(AnnouncementStatus.approved),
                    _buildAnnouncementsList(AnnouncementStatus.rejected),
                    _buildStatsView(),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildAnnouncementsList(AnnouncementStatus status) {
    return Consumer<AnnouncementController>(
      builder: (context, controller, child) {
        if (controller.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final filteredAnnouncements = controller.announcements
            .where((announcement) => announcement.status == status)
            .toList();

        if (filteredAnnouncements.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _getStatusIcon(status),
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'No hay anuncios ${_getStatusText(status).toLowerCase()}',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            await controller.loadAnnouncements();
            await _loadStats();
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: filteredAnnouncements.length,
            itemBuilder: (context, index) {
              final announcement = filteredAnnouncements[index];
              return _buildModerationCard(announcement);
            },
          ),
        );
      },
    );
  }

  Widget _buildModerationCard(Announcement announcement) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header con estado
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: _getStatusColor(announcement.status).withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getTypeColor(announcement.type),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getTypeDisplayName(announcement.type),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(announcement.status),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getStatusText(announcement.status),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  _formatDate(announcement.createdAt),
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          // Contenido
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  announcement.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  announcement.description,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.person, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      announcement.authorName,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 16),
                    if (announcement.price != null) ...[
                      Icon(Icons.attach_money, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        '\$${announcement.price!.toStringAsFixed(0)}',
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
          ),
          // Acciones
          _buildActionButtons(announcement),
        ],
      ),
    );
  }

  Widget _buildActionButtons(Announcement announcement) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.grey[200]!),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AnnouncementDetailView(announcement: announcement),
                  ),
                );
              },
              icon: const Icon(Icons.visibility),
              label: const Text('Ver Detalle'),
            ),
          ),
          const SizedBox(width: 8),
          if (announcement.status == AnnouncementStatus.pending) ...[
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _approveAnnouncement(announcement),
                icon: const Icon(Icons.check),
                label: const Text('Aprobar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _showRejectDialog(announcement),
                icon: const Icon(Icons.close),
                label: const Text('Rechazar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ] else if (announcement.status == AnnouncementStatus.approved) ...[
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _showRejectDialog(announcement),
                icon: const Icon(Icons.block),
                label: const Text('Rechazar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ] else if (announcement.status == AnnouncementStatus.rejected) ...[
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _approveAnnouncement(announcement),
                icon: const Icon(Icons.check),
                label: const Text('Aprobar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatsView() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Estadísticas Generales',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total de Anuncios',
                  _stats['total'] ?? 0,
                  Icons.announcement,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Pendientes',
                  _stats['pending'] ?? 0,
                  Icons.pending_actions,
                  Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Aprobados',
                  _stats['approved'] ?? 0,
                  Icons.check_circle,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Rechazados',
                  _stats['rejected'] ?? 0,
                  Icons.cancel,
                  Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Acciones Rápidas',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _tabController.animateTo(0),
                          icon: const Icon(Icons.pending_actions),
                          label: const Text('Ver Pendientes'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _refreshData,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Actualizar'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, int count, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              count.toString(),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _approveAnnouncement(Announcement announcement) async {
    try {
      final controller = Provider.of<AnnouncementController>(context, listen: false);
      final auth = Provider.of<AuthController>(context, listen: false);
      await controller.approveAnnouncement(
        announcement.id,
        auth.currentUser!.uid,
        auth.currentUser!.displayName,
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Anuncio aprobado exitosamente')),
      );
      
      await _refreshData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al aprobar: $e')),
      );
    }
  }

  void _showRejectDialog(Announcement announcement) {
    final TextEditingController reasonController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rechazar Anuncio'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('¿Por qué razón rechazas este anuncio?'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Escribe la razón del rechazo...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _rejectAnnouncement(announcement, reasonController.text.trim());
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Rechazar'),
          ),
        ],
      ),
    );
  }

  Future<void> _rejectAnnouncement(Announcement announcement, String reason) async {
    try {
      final controller = Provider.of<AnnouncementController>(context, listen: false);
      final auth = Provider.of<AuthController>(context, listen: false);
      await controller.rejectAnnouncement(
        announcement.id,
        reason.isEmpty ? 'Rechazado por administrador' : reason,
        auth.currentUser!.uid,
        auth.currentUser!.displayName,
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Anuncio rechazado')),
      );
      
      await _refreshData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al rechazar: $e')),
      );
    }
  }

  Future<void> _refreshData() async {
    final controller = Provider.of<AnnouncementController>(context, listen: false);
    await controller.loadAnnouncements();
    await _loadStats();
  }

  // Métodos auxiliares
  String _getTypeDisplayName(AnnouncementType type) {
    switch (type) {
      case AnnouncementType.sale:
        return 'Se Vende';
      case AnnouncementType.wanted:
        return 'Se Busca';
      case AnnouncementType.service:
        return 'Servicios';
      case AnnouncementType.general:
        return 'General';
      case AnnouncementType.community:
        return 'Comunidad';
    }
  }

  String _getStatusText(AnnouncementStatus status) {
    switch (status) {
      case AnnouncementStatus.pending:
        return 'Pendiente';
      case AnnouncementStatus.approved:
        return 'Aprobado';
      case AnnouncementStatus.rejected:
        return 'Rechazado';
      case AnnouncementStatus.expired:
        return 'Expirado';
    }
  }

  Color _getTypeColor(AnnouncementType type) {
    switch (type) {
      case AnnouncementType.sale:
        return Colors.green;
      case AnnouncementType.wanted:
        return Colors.blue;
      case AnnouncementType.service:
        return Colors.purple;
      case AnnouncementType.general:
        return Colors.orange;
      case AnnouncementType.community:
        return Colors.teal;
    }
  }

  Color _getStatusColor(AnnouncementStatus status) {
    switch (status) {
      case AnnouncementStatus.pending:
        return Colors.orange;
      case AnnouncementStatus.approved:
        return Colors.green;
      case AnnouncementStatus.rejected:
        return Colors.red;
      case AnnouncementStatus.expired:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(AnnouncementStatus status) {
    switch (status) {
      case AnnouncementStatus.pending:
        return Icons.pending_actions;
      case AnnouncementStatus.approved:
        return Icons.check_circle;
      case AnnouncementStatus.rejected:
        return Icons.cancel;
      case AnnouncementStatus.expired:
        return Icons.access_time;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
