import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../controllers/announcement_controller.dart';
import '../controllers/auth_controller.dart';
import '../models/announcement_model.dart';
import '../models/user_model.dart';

class AnnouncementDetailView extends StatefulWidget {
  final Announcement announcement;

  const AnnouncementDetailView({
    super.key,
    required this.announcement,
  });

  @override
  State<AnnouncementDetailView> createState() => _AnnouncementDetailViewState();
}

class _AnnouncementDetailViewState extends State<AnnouncementDetailView> {
  bool _showContactInfo = false;
  bool _isInterested = false;

  @override
  void initState() {
    super.initState();
    _checkIfUserIsInterested();
  }

  void _checkIfUserIsInterested() {
    final auth = Provider.of<AuthController>(context, listen: false);
    if (auth.currentUser != null) {
      _isInterested = widget.announcement.interestedUsers.contains(auth.currentUser!.uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle del Anuncio'),
        actions: [
          Consumer<AuthController>(
            builder: (context, auth, child) {
              if (auth.currentUser?.uid == widget.announcement.authorId ||
                  auth.currentUser?.role == UserRole.admin) {
                return PopupMenuButton<String>(
                  onSelected: (value) {
                    switch (value) {
                      case 'delete':
                        _showDeleteConfirmation(context);
                        break;
                    }
                  },
                  itemBuilder: (BuildContext context) => [
                    const PopupMenuItem<String>(
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildContent(),
            const SizedBox(height: 24),
            _buildContactSection(),
            const SizedBox(height: 24),
            _buildInteractionSection(),
            const SizedBox(height: 24),
            _buildMetadata(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _getTypeColor(widget.announcement.type).withOpacity(0.1),
            _getTypeColor(widget.announcement.type).withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _getTypeColor(widget.announcement.type).withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getTypeColor(widget.announcement.type),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _getTypeDisplayName(widget.announcement.type),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Spacer(),
              if (widget.announcement.price != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '\$${widget.announcement.price!.toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            widget.announcement.title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.person,
                size: 16,
                color: Colors.grey[600],
              ),
              const SizedBox(width: 4),
              Text(
                'Por ${widget.announcement.authorName}',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
              const SizedBox(width: 16),
              Icon(
                Icons.access_time,
                size: 16,
                color: Colors.grey[600],
              ),
              const SizedBox(width: 4),
              Text(
                _formatDate(widget.announcement.createdAt),
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Descripción',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.grey[200]!,
              width: 1,
            ),
          ),
          child: Text(
            widget.announcement.description,
            style: const TextStyle(
              fontSize: 16,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContactSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Información de Contacto',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _showContactInfo = !_showContactInfo;
                });
              },
              icon: Icon(_showContactInfo ? Icons.visibility_off : Icons.visibility),
              label: Text(_showContactInfo ? 'Ocultar' : 'Mostrar'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          height: _showContactInfo ? null : 60,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: _showContactInfo ? Colors.blue[50] : Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _showContactInfo ? Colors.blue[200]! : Colors.grey[200]!,
                width: 1,
              ),
            ),
            child: _showContactInfo
                ? _buildContactDetails()
                : const Row(
                    children: [
                      Icon(Icons.lock_outline, color: Colors.grey),
                      SizedBox(width: 8),
                      Text(
                        'Haz clic en "Mostrar" para ver la información de contacto',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildContactDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.announcement.authorPhone != null) ...[
          Row(
            children: [
              const Icon(Icons.phone, color: Colors.blue),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.announcement.authorPhone!,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.copy),
                tooltip: 'Copiar teléfono',
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: widget.announcement.authorPhone!));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Teléfono copiado')),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
        if (widget.announcement.authorEmail != null) ...[
          Row(
            children: [
              const Icon(Icons.email, color: Colors.blue),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.announcement.authorEmail!,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.copy),
                tooltip: 'Copiar email',
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: widget.announcement.authorEmail!));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Email copiado')),
                  );
                },
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildInteractionSection() {
    return Consumer<AuthController>(
      builder: (context, auth, child) {
        if (auth.currentUser?.uid == widget.announcement.authorId) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Interacción',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _toggleInterest,
                    icon: Icon(
                      _isInterested ? Icons.favorite : Icons.favorite_border,
                      color: _isInterested ? Colors.red : null,
                    ),
                    label: Text(_isInterested ? 'Ya no me interesa' : 'Me interesa'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isInterested ? Colors.grey[200] : null,
                      foregroundColor: _isInterested ? Colors.grey[700] : null,
                    ),
                  ),
                ),
              ],
            ),
            if (widget.announcement.interestedUsers.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                '${widget.announcement.interestedUsers.length} persona${widget.announcement.interestedUsers.length == 1 ? '' : 's'} interesada${widget.announcement.interestedUsers.length == 1 ? '' : 's'}',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildMetadata() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey[200]!,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Información del Anuncio',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _buildMetadataRow('Publicado', _formatFullDate(widget.announcement.createdAt)),
          const SizedBox(height: 8),
          _buildMetadataRow(
            'Expira',
            _formatFullDate(widget.announcement.expiresAt),
            color: _isExpiringSoon() ? Colors.orange : null,
          ),
          const SizedBox(height: 8),
          _buildMetadataRow('Estado', _getStatusDisplayName(widget.announcement.status)),
          const SizedBox(height: 8),
          _buildMetadataRow('ID', widget.announcement.id),
        ],
      ),
    );
  }

  Widget _buildMetadataRow(String label, String value, {Color? color}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            '$label:',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: color ?? Colors.grey[800],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _toggleInterest() async {
    final auth = Provider.of<AuthController>(context, listen: false);
    final controller = Provider.of<AnnouncementController>(context, listen: false);

    if (auth.currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debes iniciar sesión para mostrar interés')),
      );
      return;
    }

    try {
      if (_isInterested) {
        await controller.removeInterest(widget.announcement.id, auth.currentUser!.uid);
      } else {
        await controller.addInterest(widget.announcement.id, auth.currentUser!.uid);
      }

      setState(() {
        _isInterested = !_isInterested;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isInterested ? 'Interés añadido' : 'Interés eliminado'),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Eliminación'),
        content: const Text('¿Estás seguro de que quieres eliminar este anuncio? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteAnnouncement();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAnnouncement() async {
    final controller = Provider.of<AnnouncementController>(context, listen: false);
    try {
      await controller.deleteAnnouncement(widget.announcement.id);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Anuncio eliminado exitosamente')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al eliminar: $e')),
      );
    }
  }

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

  String _getStatusDisplayName(AnnouncementStatus status) {
    switch (status) {
      case AnnouncementStatus.pending:
        return 'Pendiente de aprobación';
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

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 7) {
      return '${date.day}/${date.month}/${date.year}';
    } else if (difference.inDays > 0) {
      return 'Hace ${difference.inDays} día${difference.inDays == 1 ? '' : 's'}';
    } else if (difference.inHours > 0) {
      return 'Hace ${difference.inHours} hora${difference.inHours == 1 ? '' : 's'}';
    } else if (difference.inMinutes > 0) {
      return 'Hace ${difference.inMinutes} minuto${difference.inMinutes == 1 ? '' : 's'}';
    } else {
      return 'Hace un momento';
    }
  }

  String _formatFullDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} a las ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  bool _isExpiringSoon() {
    final now = DateTime.now();
    final daysUntilExpiration = widget.announcement.expiresAt.difference(now).inDays;
    return daysUntilExpiration <= 3;
  }
}
