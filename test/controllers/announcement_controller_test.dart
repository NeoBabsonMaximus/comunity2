import 'package:flutter_test/flutter_test.dart';
import 'package:comunity2/models/announcement_model.dart';

void main() {
  group('AnnouncementController Tests', () {
    // Test helper methods and data validation
    testWidgets('should create announcement with valid data', (tester) async {
      const title = 'Test Announcement';
      const description = 'This is a test announcement';
      const type = AnnouncementType.sale;
      const authorId = 'user-123';
      const authorName = 'Test User';
      const price = 100.0;
      
      // Validate input data
      expect(title.isNotEmpty, isTrue);
      expect(description.isNotEmpty, isTrue);
      expect(authorId.isNotEmpty, isTrue);
      expect(authorName.isNotEmpty, isTrue);
      expect(price > 0, isTrue);
      
      // Create announcement with this data
      final announcement = Announcement(
        id: '1',
        title: title,
        description: description,
        type: type,
        status: AnnouncementStatus.pending,
        authorId: authorId,
        authorName: authorName,
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(days: 30)),
        price: price,
      );
      
      expect(announcement.title, equals(title));
      expect(announcement.description, equals(description));
      expect(announcement.type, equals(type));
      expect(announcement.authorId, equals(authorId));
      expect(announcement.price, equals(price));
      expect(announcement.status, equals(AnnouncementStatus.pending));
    });

    testWidgets('should validate announcement types for filtering', (tester) async {
      final saleAnnouncement = Announcement(
        id: '1',
        title: 'Sale Item',
        description: 'For sale',
        type: AnnouncementType.sale,
        status: AnnouncementStatus.approved,
        authorId: 'user-123',
        authorName: 'Seller',
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(days: 30)),
        price: 200.0,
      );

      final wantedAnnouncement = Announcement(
        id: '2',
        title: 'Wanted Item',
        description: 'Looking for',
        type: AnnouncementType.wanted,
        status: AnnouncementStatus.approved,
        authorId: 'user-456',
        authorName: 'Buyer',
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(days: 30)),
      );

      final serviceAnnouncement = Announcement(
        id: '3',
        title: 'Service Offer',
        description: 'Offering service',
        type: AnnouncementType.service,
        status: AnnouncementStatus.approved,
        authorId: 'user-789',
        authorName: 'Service Provider',
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(days: 30)),
        price: 50.0,
      );

      final generalAnnouncement = Announcement(
        id: '4',
        title: 'General Info',
        description: 'General information',
        type: AnnouncementType.general,
        status: AnnouncementStatus.approved,
        authorId: 'user-101',
        authorName: 'User',
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(days: 30)),
      );

      final communityAnnouncement = Announcement(
        id: '5',
        title: 'Community Event',
        description: 'Community announcement',
        type: AnnouncementType.community,
        status: AnnouncementStatus.approved,
        authorId: 'admin-123',
        authorName: 'Admin',
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(days: 30)),
      );

      // Test filtering logic
      final announcements = [
        saleAnnouncement,
        wantedAnnouncement,
        serviceAnnouncement,
        generalAnnouncement,
        communityAnnouncement,
      ];

      // Filter by type
      final saleOnly = announcements.where((a) => a.type == AnnouncementType.sale).toList();
      final wantedOnly = announcements.where((a) => a.type == AnnouncementType.wanted).toList();
      final serviceOnly = announcements.where((a) => a.type == AnnouncementType.service).toList();
      final generalOnly = announcements.where((a) => a.type == AnnouncementType.general).toList();
      final communityOnly = announcements.where((a) => a.type == AnnouncementType.community).toList();

      expect(saleOnly.length, equals(1));
      expect(wantedOnly.length, equals(1));
      expect(serviceOnly.length, equals(1));
      expect(generalOnly.length, equals(1));
      expect(communityOnly.length, equals(1));

      expect(saleOnly.first.id, equals('1'));
      expect(wantedOnly.first.id, equals('2'));
      expect(serviceOnly.first.id, equals('3'));
      expect(generalOnly.first.id, equals('4'));
      expect(communityOnly.first.id, equals('5'));
    });

    testWidgets('should filter active announcements correctly', (tester) async {
      final activeAnnouncement = Announcement(
        id: '1',
        title: 'Active Announcement',
        description: 'This is active',
        type: AnnouncementType.sale,
        status: AnnouncementStatus.approved,
        authorId: 'user-123',
        authorName: 'User',
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(days: 15)),
      );

      final expiredAnnouncement = Announcement(
        id: '2',
        title: 'Expired Announcement',
        description: 'This is expired',
        type: AnnouncementType.sale,
        status: AnnouncementStatus.approved,
        authorId: 'user-456',
        authorName: 'User',
        createdAt: DateTime.now().subtract(const Duration(days: 60)),
        expiresAt: DateTime.now().subtract(const Duration(days: 1)),
      );

      final pendingAnnouncement = Announcement(
        id: '3',
        title: 'Pending Announcement',
        description: 'This is pending',
        type: AnnouncementType.sale,
        status: AnnouncementStatus.pending,
        authorId: 'user-789',
        authorName: 'User',
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(days: 30)),
      );

      final rejectedAnnouncement = Announcement(
        id: '4',
        title: 'Rejected Announcement',
        description: 'This is rejected',
        type: AnnouncementType.sale,
        status: AnnouncementStatus.rejected,
        authorId: 'user-101',
        authorName: 'User',
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(days: 30)),
      );

      final announcements = [
        activeAnnouncement,
        expiredAnnouncement,
        pendingAnnouncement,
        rejectedAnnouncement,
      ];

      // Filter only active (approved and not expired)
      final activeOnly = announcements.where((a) => a.isActive).toList();
      
      expect(activeOnly.length, equals(1));
      expect(activeOnly.first.id, equals('1'));
      expect(activeOnly.first.isActive, isTrue);
      
      // Test individual status checks
      expect(activeAnnouncement.isActive, isTrue);
      expect(expiredAnnouncement.isActive, isFalse); // Expired
      expect(pendingAnnouncement.isActive, isFalse); // Pending
      expect(rejectedAnnouncement.isActive, isFalse); // Rejected
    });

    testWidgets('should handle search query filtering', (tester) async {
      final announcement1 = Announcement(
        id: '1',
        title: 'Vendo bicicleta montaña',
        description: 'Bicicleta Trek en excelente estado',
        type: AnnouncementType.sale,
        status: AnnouncementStatus.approved,
        authorId: 'user-123',
        authorName: 'Juan Pérez',
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(days: 30)),
        price: 500.0,
      );

      final announcement2 = Announcement(
        id: '2',
        title: 'Busco mecánico',
        description: 'Necesito mecánico para reparación de auto',
        type: AnnouncementType.wanted,
        status: AnnouncementStatus.approved,
        authorId: 'user-456',
        authorName: 'María García',
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(days: 30)),
      );

      final announcement3 = Announcement(
        id: '3',
        title: 'Servicio de plomería',
        description: 'Plomero profesional con experiencia',
        type: AnnouncementType.service,
        status: AnnouncementStatus.approved,
        authorId: 'user-789',
        authorName: 'Carlos López',
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(days: 30)),
        price: 100.0,
      );

      final announcements = [announcement1, announcement2, announcement3];

      // Search by title
      String searchQuery = 'bicicleta';
      var filtered = announcements.where((a) => 
        a.title.toLowerCase().contains(searchQuery.toLowerCase()) ||
        a.description.toLowerCase().contains(searchQuery.toLowerCase())
      ).toList();
      expect(filtered.length, equals(1));
      expect(filtered.first.id, equals('1'));

      // Search by description
      searchQuery = 'mecánico';
      filtered = announcements.where((a) => 
        a.title.toLowerCase().contains(searchQuery.toLowerCase()) ||
        a.description.toLowerCase().contains(searchQuery.toLowerCase())
      ).toList();
      expect(filtered.length, equals(1));
      expect(filtered.first.id, equals('2'));

      // Search by service type
      searchQuery = 'plomería';
      filtered = announcements.where((a) => 
        a.title.toLowerCase().contains(searchQuery.toLowerCase()) ||
        a.description.toLowerCase().contains(searchQuery.toLowerCase())
      ).toList();
      expect(filtered.length, equals(1));
      expect(filtered.first.id, equals('3'));

      // Search with no results
      searchQuery = 'computadora';
      filtered = announcements.where((a) => 
        a.title.toLowerCase().contains(searchQuery.toLowerCase()) ||
        a.description.toLowerCase().contains(searchQuery.toLowerCase())
      ).toList();
      expect(filtered.length, equals(0));
    });

    testWidgets('should validate urgent announcements priority', (tester) async {
      final urgentAnnouncement = Announcement(
        id: '1',
        title: 'Anuncio Urgente',
        description: 'Esto es urgente',
        type: AnnouncementType.general,
        status: AnnouncementStatus.approved,
        authorId: 'user-123',
        authorName: 'Usuario',
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(days: 30)),
        isUrgent: true,
      );

      final normalAnnouncement = Announcement(
        id: '2',
        title: 'Anuncio Normal',
        description: 'Esto es normal',
        type: AnnouncementType.general,
        status: AnnouncementStatus.approved,
        authorId: 'user-456',
        authorName: 'Usuario',
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(days: 30)),
        isUrgent: false,
      );

      final announcements = [normalAnnouncement, urgentAnnouncement];

      // Sort by urgency (urgent first)
      announcements.sort((a, b) {
        if (a.isUrgent && !b.isUrgent) return -1;
        if (!a.isUrgent && b.isUrgent) return 1;
        return b.createdAt.compareTo(a.createdAt); // Then by creation date
      });

      expect(announcements.first.id, equals('1')); // Urgent first
      expect(announcements.first.isUrgent, isTrue);
      expect(announcements.last.id, equals('2'));
      expect(announcements.last.isUrgent, isFalse);
    });

    testWidgets('should handle price validation for sale items', (tester) async {
      // Valid sale with price
      final validSaleAnnouncement = Announcement(
        id: '1',
        title: 'Vendo laptop',
        description: 'Laptop en buen estado',
        type: AnnouncementType.sale,
        status: AnnouncementStatus.approved,
        authorId: 'user-123',
        authorName: 'Vendedor',
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(days: 30)),
        price: 800.0,
      );

      // Sale without price
      final saleWithoutPrice = Announcement(
        id: '2',
        title: 'Vendo muebles',
        description: 'Varios muebles',
        type: AnnouncementType.sale,
        status: AnnouncementStatus.approved,
        authorId: 'user-456',
        authorName: 'Vendedor',
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(days: 30)),
      );

      // Service with price
      final serviceWithPrice = Announcement(
        id: '3',
        title: 'Limpieza de casas',
        description: 'Servicio de limpieza',
        type: AnnouncementType.service,
        status: AnnouncementStatus.approved,
        authorId: 'user-789',
        authorName: 'Limpiador',
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(days: 30)),
        price: 150.0,
      );

      // General announcement (no price expected)
      final generalAnnouncement = Announcement(
        id: '4',
        title: 'Información general',
        description: 'Aviso importante',
        type: AnnouncementType.general,
        status: AnnouncementStatus.approved,
        authorId: 'user-101',
        authorName: 'Usuario',
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(days: 30)),
      );

      // Validate price presence
      expect(validSaleAnnouncement.hasPrice, isTrue);
      expect(saleWithoutPrice.hasPrice, isFalse);
      expect(serviceWithPrice.hasPrice, isTrue);
      expect(generalAnnouncement.hasPrice, isFalse);

      // Validate price values
      expect(validSaleAnnouncement.price, equals(800.0));
      expect(saleWithoutPrice.price, isNull);
      expect(serviceWithPrice.price, equals(150.0));
      expect(generalAnnouncement.price, isNull);
    });

    testWidgets('should validate announcement moderation workflow', (tester) async {
      // Create pending announcement
      var announcement = Announcement(
        id: '1',
        title: 'Test Announcement',
        description: 'Awaiting moderation',
        type: AnnouncementType.sale,
        status: AnnouncementStatus.pending,
        authorId: 'user-123',
        authorName: 'User',
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(days: 30)),
        price: 100.0,
      );

      expect(announcement.status, equals(AnnouncementStatus.pending));
      expect(announcement.isActive, isFalse);

      // Approve announcement
      announcement = announcement.copyWith(
        status: AnnouncementStatus.approved,
      );

      expect(announcement.status, equals(AnnouncementStatus.approved));
      expect(announcement.isActive, isTrue);

      // Reject announcement
      announcement = announcement.copyWith(
        status: AnnouncementStatus.rejected,
        rejectionReason: 'Contenido inapropiado',
      );

      expect(announcement.status, equals(AnnouncementStatus.rejected));
      expect(announcement.isActive, isFalse);
      expect(announcement.rejectionReason, equals('Contenido inapropiado'));
    });

    testWidgets('should handle announcement statistics', (tester) async {
      final announcements = [
        Announcement(
          id: '1',
          title: 'Sale 1',
          description: 'Description',
          type: AnnouncementType.sale,
          status: AnnouncementStatus.approved,
          authorId: 'user-1',
          authorName: 'User 1',
          createdAt: DateTime.now(),
          expiresAt: DateTime.now().add(const Duration(days: 30)),
        ),
        Announcement(
          id: '2',
          title: 'Sale 2',
          description: 'Description',
          type: AnnouncementType.sale,
          status: AnnouncementStatus.pending,
          authorId: 'user-2',
          authorName: 'User 2',
          createdAt: DateTime.now(),
          expiresAt: DateTime.now().add(const Duration(days: 30)),
        ),
        Announcement(
          id: '3',
          title: 'Wanted 1',
          description: 'Description',
          type: AnnouncementType.wanted,
          status: AnnouncementStatus.approved,
          authorId: 'user-3',
          authorName: 'User 3',
          createdAt: DateTime.now(),
          expiresAt: DateTime.now().add(const Duration(days: 30)),
        ),
        Announcement(
          id: '4',
          title: 'Service 1',
          description: 'Description',
          type: AnnouncementType.service,
          status: AnnouncementStatus.rejected,
          authorId: 'user-4',
          authorName: 'User 4',
          createdAt: DateTime.now(),
          expiresAt: DateTime.now().add(const Duration(days: 30)),
        ),
      ];

      // Calculate statistics
      final totalCount = announcements.length;
      final approvedCount = announcements.where((a) => a.status == AnnouncementStatus.approved).length;
      final pendingCount = announcements.where((a) => a.status == AnnouncementStatus.pending).length;
      final rejectedCount = announcements.where((a) => a.status == AnnouncementStatus.rejected).length;
      final activeCount = announcements.where((a) => a.isActive).length;

      final saleCount = announcements.where((a) => a.type == AnnouncementType.sale).length;
      final wantedCount = announcements.where((a) => a.type == AnnouncementType.wanted).length;
      final serviceCount = announcements.where((a) => a.type == AnnouncementType.service).length;

      expect(totalCount, equals(4));
      expect(approvedCount, equals(2));
      expect(pendingCount, equals(1));
      expect(rejectedCount, equals(1));
      expect(activeCount, equals(2)); // Only approved announcements are active

      expect(saleCount, equals(2));
      expect(wantedCount, equals(1));
      expect(serviceCount, equals(1));
    });
  });
}
