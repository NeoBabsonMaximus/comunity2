import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/announcement_model.dart';

class AnnouncementController extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'announcements';

  bool _isLoading = false;
  String? _error;
  List<Announcement> _announcements = [];

  bool get isLoading => _isLoading;
  String? get error => _error;
  List<Announcement> get announcements => _announcements;

  // Crear nuevo anuncio (usuarios regulares)
  Future<String> createAnnouncement({
    required String title,
    required String description,
    required AnnouncementType type,
    required String authorId,
    String? authorName,
    String? authorPhone,
    String? authorEmail,
    String? authorApartment,
    double? price,
    bool isUrgent = false,
    int daysValid = 30,
    List<String> tags = const [],
  }) async {
    try {
      _setLoading(true);
      
      final now = DateTime.now();
      final announcement = Announcement(
        id: '',
        title: title,
        description: description,
        type: type,
        status: AnnouncementStatus.pending, // Todos los anuncios empiezan pendientes
        authorId: authorId,
        authorName: authorName ?? 'Usuario',
        authorPhone: authorPhone,
        authorEmail: authorEmail,
        authorApartment: authorApartment,
        price: price,
        images: [],
        createdAt: now,
        expiresAt: now.add(Duration(days: daysValid)),
        tags: tags,
        isUrgent: isUrgent,
        viewCount: 0,
        interestedUsers: [],
      );
      
      final docRef = await _firestore.collection(_collection).add(announcement.toMap());
      
      _setError(null);
      print('🔥 DEBUG: Anuncio creado con ID: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      print('🔥 ERROR: Error al crear anuncio: $e');
      _setError('Error al crear anuncio: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // Obtener anuncios aprobados para usuarios regulares
  Stream<List<Announcement>> getApprovedAnnouncements({
    AnnouncementType? filterType,
    String? searchQuery,
    bool onlyActive = true,
  }) {
    print('🔥 DEBUG: Iniciando consulta de anuncios aprobados');
    print('🔥 DEBUG: filterType: $filterType, searchQuery: $searchQuery, onlyActive: $onlyActive');
    
    try {
      // Consulta MUY simple - solo estado aprobado, sin orderBy para evitar índices
      Query query = _firestore
          .collection(_collection)
          .where('status', isEqualTo: AnnouncementStatus.approved.value);

      // NO aplicamos filtros adicionales en Firestore para evitar índices compuestos
      
      return query.snapshots().map((snapshot) {
        print('🔥 DEBUG: Snapshot recibido con ${snapshot.docs.length} documentos');
        
        try {
          var announcements = snapshot.docs
              .map((doc) {
                try {
                  print('🔥 DEBUG: Procesando documento ${doc.id}');
                  return Announcement.fromMap(doc.data() as Map<String, dynamic>, doc.id);
                } catch (e) {
                  print('🔥 ERROR: Error procesando documento ${doc.id}: $e');
                  return null;
                }
              })
              .where((announcement) => announcement != null)
              .cast<Announcement>()
              .toList();

          print('🔥 DEBUG: ${announcements.length} anuncios procesados exitosamente');

          // TODO EL FILTRADO LO HACEMOS DEL LADO DEL CLIENTE
          
          // Filtrar por tipo del lado cliente
          if (filterType != null) {
            final beforeCount = announcements.length;
            announcements = announcements.where((announcement) =>
              announcement.type == filterType
            ).toList();
            print('🔥 DEBUG: Después del filtro de tipo: ${announcements.length} (antes: $beforeCount)');
          }

          // Filtrar por expiración del lado cliente
          if (onlyActive) {
            final now = DateTime.now();
            final beforeCount = announcements.length;
            announcements = announcements.where((announcement) =>
              announcement.expiresAt.isAfter(now)
            ).toList();
            print('🔥 DEBUG: Después del filtro de expiración: ${announcements.length} (antes: $beforeCount)');
          }

          // Filtro de búsqueda del lado cliente
          if (searchQuery != null && searchQuery.trim().isNotEmpty) {
            final beforeCount = announcements.length;
            final search = searchQuery.toLowerCase();
            announcements = announcements.where((announcement) =>
              announcement.title.toLowerCase().contains(search) ||
              announcement.description.toLowerCase().contains(search) ||
              announcement.tags.any((tag) => tag.toLowerCase().contains(search))
            ).toList();
            print('🔥 DEBUG: Después del filtro de búsqueda: ${announcements.length} (antes: $beforeCount)');
          }

          // Ordenar del lado cliente: urgentes primero, luego por fecha
          announcements.sort((a, b) {
            if (a.isUrgent && !b.isUrgent) return -1;
            if (!a.isUrgent && b.isUrgent) return 1;
            return b.createdAt.compareTo(a.createdAt);
          });

          print('🔥 DEBUG: Retornando ${announcements.length} anuncios finales');
          return announcements;
        } catch (e) {
          print('🔥 ERROR: Error procesando snapshot: $e');
          return <Announcement>[];
        }
      }).handleError((error) {
        print('🔥 ERROR: Error en stream de anuncios: $error');
        throw error;
      });
    } catch (e) {
      print('🔥 ERROR: Error creando query: $e');
      throw e;
    }
  }

  // Obtener anuncios pendientes (solo para administradores)
  Stream<List<Announcement>> getPendingAnnouncements() {
    print('🔥 DEBUG: Consultando anuncios pendientes');
    
    return _firestore
        .collection(_collection)
        .where('status', isEqualTo: AnnouncementStatus.pending.value)
        // Removido orderBy para evitar índices compuestos
        .snapshots()
        .map((snapshot) {
          print('🔥 DEBUG: ${snapshot.docs.length} anuncios pendientes encontrados');
          var announcements = snapshot.docs
              .map((doc) => Announcement.fromMap(doc.data(), doc.id))
              .toList();
          
          // Ordenar del lado cliente
          announcements.sort((a, b) {
            // Urgentes primero, luego más antiguos primero para revisión
            if (a.isUrgent && !b.isUrgent) return -1;
            if (!a.isUrgent && b.isUrgent) return 1;
            return a.createdAt.compareTo(b.createdAt);
          });
          
          return announcements;
        });
  }

  // Aprobar anuncio (solo administradores)
  Future<void> approveAnnouncement(String announcementId, String adminId, String adminName) async {
    try {
      await _firestore.collection(_collection).doc(announcementId).update({
        'status': AnnouncementStatus.approved.value,
        'approvedAt': Timestamp.now(),
        'approvedBy': adminName,
        'rejectionReason': null,
      });
      
      notifyListeners();
    } catch (e) {
      _setError('Error al aprobar anuncio: $e');
      rethrow;
    }
  }

  // Rechazar anuncio (solo administradores)
  Future<void> rejectAnnouncement(String announcementId, String reason, String adminId, String adminName) async {
    try {
      await _firestore.collection(_collection).doc(announcementId).update({
        'status': AnnouncementStatus.rejected.value,
        'rejectedAt': Timestamp.now(),
        'rejectedBy': adminName,
        'rejectionReason': reason,
      });
      
      notifyListeners();
    } catch (e) {
      _setError('Error al rechazar anuncio: $e');
      rethrow;
    }
  }

  // Obtener anuncio por ID
  Future<Announcement?> getAnnouncementById(String id) async {
    try {
      final doc = await _firestore.collection(_collection).doc(id).get();
      
      if (doc.exists) {
        return Announcement.fromMap(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      _setError('Error al obtener anuncio: $e');
      return null;
    }
  }

  // Eliminar anuncio
  Future<void> deleteAnnouncement(String announcementId) async {
    try {
      _setLoading(true);
      
      await _firestore.collection(_collection).doc(announcementId).delete();
      
      _setError(null);
      notifyListeners();
    } catch (e) {
      _setError('Error al eliminar anuncio: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // Agregar interés en un anuncio
  Future<void> addInterest(String announcementId, String userId) async {
    try {
      await _firestore.collection(_collection).doc(announcementId).update({
        'interestedUsers': FieldValue.arrayUnion([userId])
      });
      notifyListeners();
    } catch (e) {
      _setError('Error al mostrar interés: $e');
      rethrow;
    }
  }

  // Remover interés de un anuncio
  Future<void> removeInterest(String announcementId, String userId) async {
    try {
      await _firestore.collection(_collection).doc(announcementId).update({
        'interestedUsers': FieldValue.arrayRemove([userId])
      });
      notifyListeners();
    } catch (e) {
      _setError('Error al remover interés: $e');
      rethrow;
    }
  }

  // Funciones auxiliares privadas
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  // Limpiar errores
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Obtener estadísticas para admin
  Future<Map<String, int>> getAnnouncementStats() async {
    try {
      final totalQuery = await _firestore.collection(_collection).count().get();
      final approvedQuery = await _firestore
          .collection(_collection)
          .where('status', isEqualTo: AnnouncementStatus.approved.value)
          .count()
          .get();
      final pendingQuery = await _firestore
          .collection(_collection)
          .where('status', isEqualTo: AnnouncementStatus.pending.value)
          .count()
          .get();
      final rejectedQuery = await _firestore
          .collection(_collection)
          .where('status', isEqualTo: AnnouncementStatus.rejected.value)
          .count()
          .get();

      return {
        'total': totalQuery.count ?? 0,
        'approved': approvedQuery.count ?? 0,
        'pending': pendingQuery.count ?? 0,
        'rejected': rejectedQuery.count ?? 0,
      };
    } catch (e) {
      print('🔥 ERROR: Error al obtener estadísticas: $e');
      _setError('Error al obtener estadísticas: $e');
      return {'total': 0, 'approved': 0, 'pending': 0, 'rejected': 0};
    }
  }

  // Cargar anuncios (método para compatibilidad)
  Future<void> loadAnnouncements() async {
    try {
      _setLoading(true);
      
      final snapshot = await _firestore
          .collection(_collection)
          // Removido orderBy para evitar necesidad de índices
          .get();
      
      _announcements = snapshot.docs
          .map((doc) => Announcement.fromMap(doc.data(), doc.id))
          .toList();
      
      // Ordenar del lado cliente
      _announcements.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      _setError(null);
      notifyListeners();
    } catch (e) {
      print('🔥 ERROR: Error cargando anuncios: $e');
      _setError('Error cargando anuncios: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Método para crear anuncios de prueba (solo para desarrollo)
  Future<void> createTestAnnouncements() async {
    print('🔥 DEBUG: Creando anuncios de prueba...');
    
    try {
      final now = DateTime.now();
      
      final testAnnouncements = [
        // ANUNCIOS APROBADOS
        Announcement(
          id: '',
          title: 'Vendo Laptop HP Pavilion',
          description: 'Laptop en excelente estado, ideal para trabajo y estudios. Incluye cargador y mouse.',
          type: AnnouncementType.sale,
          status: AnnouncementStatus.approved,
          authorId: 'test_user_1',
          authorName: 'María García',
          createdAt: now,
          expiresAt: now.add(const Duration(days: 30)),
          isUrgent: false,
          price: 1500000,
          viewCount: 5,
          tags: ['laptop', 'hp', 'tecnología'],
          images: [],
          interestedUsers: [],
        ),
        Announcement(
          id: '',
          title: 'Se busca profesor de matemáticas',
          description: 'Necesito clases particulares de matemáticas para bachillerato. Horarios flexibles.',
          type: AnnouncementType.wanted,
          status: AnnouncementStatus.approved,
          authorId: 'test_user_2',
          authorName: 'Carlos Rodríguez',
          createdAt: now.subtract(const Duration(hours: 2)),
          expiresAt: now.add(const Duration(days: 15)),
          isUrgent: true,
          price: null,
          viewCount: 12,
          tags: ['matemáticas', 'clases', 'educación'],
          images: [],
          interestedUsers: [],
        ),
        Announcement(
          id: '',
          title: 'Servicio de plomería',
          description: 'Plomero certificado con 10 años de experiencia. Atención 24/7 para emergencias.',
          type: AnnouncementType.service,
          status: AnnouncementStatus.approved,
          authorId: 'test_user_3',
          authorName: 'Roberto Sánchez',
          createdAt: now.subtract(const Duration(days: 1)),
          expiresAt: now.add(const Duration(days: 60)),
          isUrgent: false,
          price: 50000,
          viewCount: 8,
          tags: ['plomería', 'emergencias', 'hogar'],
          images: [],
          interestedUsers: [],
        ),
        Announcement(
          id: '',
          title: 'Reunión de vecinos - Junta de copropietarios',
          description: 'Se convoca a todos los vecinos para la reunión mensual. Temas importantes a tratar.',
          type: AnnouncementType.community,
          status: AnnouncementStatus.approved,
          authorId: 'test_user_4',
          authorName: 'Ana Martínez',
          createdAt: now.subtract(const Duration(hours: 4)),
          expiresAt: now.add(const Duration(days: 7)),
          isUrgent: true,
          price: null,
          viewCount: 25,
          tags: ['reunión', 'vecinos', 'comunidad'],
          images: [],
          interestedUsers: [],
        ),
        Announcement(
          id: '',
          title: 'Vendo bicicleta montañera',
          description: 'Bicicleta Trek en perfecto estado, poco uso. Incluye casco y accesorios.',
          type: AnnouncementType.sale,
          status: AnnouncementStatus.approved,
          authorId: 'test_user_5',
          authorName: 'Luis Pérez',
          createdAt: now.subtract(const Duration(hours: 6)),
          expiresAt: now.add(const Duration(days: 20)),
          isUrgent: false,
          price: 800000,
          viewCount: 3,
          tags: ['bicicleta', 'deporte', 'montaña'],
          images: [],
          interestedUsers: [],
        ),
        
        // ANUNCIOS PENDIENTES PARA MODERAR
        Announcement(
          id: '',
          title: 'Vendo iPhone 14 Pro Max - URGENTE',
          description: 'Vendo por viaje. iPhone en perfectas condiciones, sin rayones, con todos los accesorios originales. Precio negociable.',
          type: AnnouncementType.sale,
          status: AnnouncementStatus.pending, // ⚠️ PENDIENTE
          authorId: 'pending_user_1',
          authorName: 'Andrea López',
          createdAt: now.subtract(const Duration(minutes: 30)),
          expiresAt: now.add(const Duration(days: 10)),
          isUrgent: true,
          price: 4500000,
          viewCount: 0,
          tags: ['iphone', 'celular', 'urgente'],
          images: [],
          interestedUsers: [],
        ),
        Announcement(
          id: '',
          title: 'Busco compañero de apartamento',
          description: 'Busco persona responsable para compartir apartamento cerca al centro. Dos habitaciones, servicios incluidos.',
          type: AnnouncementType.wanted,
          status: AnnouncementStatus.pending, // ⚠️ PENDIENTE
          authorId: 'pending_user_2',
          authorName: 'Miguel Torres',
          createdAt: now.subtract(const Duration(hours: 1)),
          expiresAt: now.add(const Duration(days: 30)),
          isUrgent: false,
          price: 600000,
          viewCount: 0,
          tags: ['apartamento', 'compañero', 'arriendo'],
          images: [],
          interestedUsers: [],
        ),
        Announcement(
          id: '',
          title: 'Ofrezco clases de guitarra a domicilio',
          description: 'Guitarrista profesional con 15 años de experiencia ofrece clases personalizadas. Todos los niveles y géneros musicales.',
          type: AnnouncementType.service,
          status: AnnouncementStatus.pending, // ⚠️ PENDIENTE
          authorId: 'pending_user_3',
          authorName: 'David Músico',
          createdAt: now.subtract(const Duration(hours: 2)),
          expiresAt: now.add(const Duration(days: 45)),
          isUrgent: false,
          price: 80000,
          viewCount: 0,
          tags: ['guitarra', 'música', 'clases'],
          images: [],
          interestedUsers: [],
        ),
        Announcement(
          id: '',
          title: '🚨 PROBLEMA CON CONTENIDO INAPROPIADO 🚨',
          description: 'Este es un anuncio que podría contener contenido inapropiado y debe ser revisado cuidadosamente por el administrador antes de aprobar.',
          type: AnnouncementType.community,
          status: AnnouncementStatus.pending, // ⚠️ PENDIENTE - DEBE SER RECHAZADO
          authorId: 'problematic_user',
          authorName: 'Usuario Problemático',
          createdAt: now.subtract(const Duration(hours: 3)),
          expiresAt: now.add(const Duration(days: 7)),
          isUrgent: true,
          price: null,
          viewCount: 0,
          tags: ['problema', 'revisar'],
          images: [],
          interestedUsers: [],
        ),
      ];

      for (final announcement in testAnnouncements) {
        await _firestore.collection(_collection).add(announcement.toMap());
        print('🔥 DEBUG: Creado anuncio: ${announcement.title} - Estado: ${announcement.status.value}');
      }

      print('🔥 DEBUG: ${testAnnouncements.length} anuncios de prueba creados exitosamente');
      print('🔥 DEBUG: ✅ ${testAnnouncements.where((a) => a.status == AnnouncementStatus.approved).length} aprobados');
      print('🔥 DEBUG: ⚠️ ${testAnnouncements.where((a) => a.status == AnnouncementStatus.pending).length} pendientes para moderar');
    } catch (e) {
      print('🔥 ERROR: Error creando anuncios de prueba: $e');
      _setError('Error creando anuncios de prueba: $e');
    }
  }
}
