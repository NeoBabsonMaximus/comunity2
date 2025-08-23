import 'package:flutter_test/flutter_test.dart';
import 'package:comunity2/models/announcement_model.dart';
import 'package:comunity2/models/user_model.dart';

void main() {
  group('AnnouncementsView Widget Tests', () {
    testWidgets('should create Announcement model with valid data', (tester) async {
      // Test announcement model creation
      final announcement = Announcement(
        id: '1',
        title: 'Test Announcement',
        description: 'Test Description',
        type: AnnouncementType.sale,
        status: AnnouncementStatus.approved,
        authorId: 'user-123',
        authorName: 'Test User',
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(days: 30)),
        price: 100.0,
      );
      
      expect(announcement.id, equals('1'));
      expect(announcement.title, equals('Test Announcement'));
      expect(announcement.type, equals(AnnouncementType.sale));
      expect(announcement.status, equals(AnnouncementStatus.approved));
      expect(announcement.price, equals(100.0));
      expect(announcement.hasPrice, isTrue);
      expect(announcement.isActive, isTrue);
    });

    testWidgets('should validate announcement types correctly', (tester) async {
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

      expect(saleAnnouncement.type, equals(AnnouncementType.sale));
      expect(wantedAnnouncement.type, equals(AnnouncementType.wanted));
      expect(saleAnnouncement.hasPrice, isTrue);
      expect(wantedAnnouncement.hasPrice, isFalse);
    });

    testWidgets('should validate user roles correctly', (tester) async {
      final adminUser = AppUser(
        uid: 'admin-123',
        email: 'admin@example.com',
        displayName: 'Admin User',
        role: UserRole.admin,
        createdAt: DateTime.now(),
        lastLogin: DateTime.now(),
      );

      final regularUser = AppUser(
        uid: 'user-123',
        email: 'user@example.com',
        displayName: 'Regular User',
        role: UserRole.user,
        createdAt: DateTime.now(),
        lastLogin: DateTime.now(),
      );

      expect(adminUser.isAdmin, isTrue);
      expect(regularUser.isAdmin, isFalse);
      expect(adminUser.canManageUsers, isTrue);
      expect(regularUser.canManageUsers, isFalse);
    });

    testWidgets('should handle announcement status changes', (tester) async {
      final pendingAnnouncement = Announcement(
        id: '1',
        title: 'Pending Announcement',
        description: 'Awaiting approval',
        type: AnnouncementType.general,
        status: AnnouncementStatus.pending,
        authorId: 'user-123',
        authorName: 'User',
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(days: 30)),
      );

      final approvedAnnouncement = pendingAnnouncement.copyWith(
        status: AnnouncementStatus.approved,
      );

      final rejectedAnnouncement = pendingAnnouncement.copyWith(
        status: AnnouncementStatus.rejected,
      );

      expect(pendingAnnouncement.status, equals(AnnouncementStatus.pending));
      expect(approvedAnnouncement.status, equals(AnnouncementStatus.approved));
      expect(rejectedAnnouncement.status, equals(AnnouncementStatus.rejected));

      expect(pendingAnnouncement.isActive, isFalse);
      expect(approvedAnnouncement.isActive, isTrue);
      expect(rejectedAnnouncement.isActive, isFalse);
    });

    testWidgets('should validate urgent announcements', (tester) async {
      final urgentAnnouncement = Announcement(
        id: '1',
        title: 'Urgent Announcement',
        description: 'Very important',
        type: AnnouncementType.community,
        status: AnnouncementStatus.approved,
        authorId: 'user-123',
        authorName: 'User',
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(days: 30)),
        isUrgent: true,
      );

      final normalAnnouncement = Announcement(
        id: '2',
        title: 'Normal Announcement',
        description: 'Regular importance',
        type: AnnouncementType.general,
        status: AnnouncementStatus.approved,
        authorId: 'user-456',
        authorName: 'User',
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(days: 30)),
        isUrgent: false,
      );

      expect(urgentAnnouncement.isUrgent, isTrue);
      expect(normalAnnouncement.isUrgent, isFalse);
    });

    testWidgets('should handle expiration dates correctly', (tester) async {
      final expiredAnnouncement = Announcement(
        id: '1',
        title: 'Expired Announcement',
        description: 'This is expired',
        type: AnnouncementType.sale,
        status: AnnouncementStatus.approved,
        authorId: 'user-123',
        authorName: 'User',
        createdAt: DateTime.now().subtract(const Duration(days: 60)),
        expiresAt: DateTime.now().subtract(const Duration(days: 1)),
      );

      final activeAnnouncement = Announcement(
        id: '2',
        title: 'Active Announcement',
        description: 'This is still active',
        type: AnnouncementType.wanted,
        status: AnnouncementStatus.approved,
        authorId: 'user-456',
        authorName: 'User',
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(days: 15)),
      );

      expect(expiredAnnouncement.isExpired, isTrue);
      expect(activeAnnouncement.isExpired, isFalse);
      expect(expiredAnnouncement.isActive, isFalse); // Expired announcements are not active
      expect(activeAnnouncement.isActive, isTrue);
    });

    testWidgets('should convert announcement to/from map correctly', (tester) async {
      final originalAnnouncement = Announcement(
        id: '1',
        title: 'Test Announcement',
        description: 'Test Description',
        type: AnnouncementType.service,
        status: AnnouncementStatus.approved,
        authorId: 'user-123',
        authorName: 'Test User',
        authorPhone: '+1234567890',
        authorEmail: 'test@example.com',
        authorApartment: '101',
        price: 150.0,
        createdAt: DateTime(2024, 1, 1, 12, 0, 0),
        expiresAt: DateTime(2024, 2, 1, 12, 0, 0),
        isUrgent: true,
        tags: ['test', 'service'],
      );

      // Convert to map
      final map = originalAnnouncement.toMap();
      
      // Convert back from map
      final convertedAnnouncement = Announcement.fromMap(map, '1');

      expect(convertedAnnouncement.title, equals(originalAnnouncement.title));
      expect(convertedAnnouncement.description, equals(originalAnnouncement.description));
      expect(convertedAnnouncement.type, equals(originalAnnouncement.type));
      expect(convertedAnnouncement.status, equals(originalAnnouncement.status));
      expect(convertedAnnouncement.authorId, equals(originalAnnouncement.authorId));
      expect(convertedAnnouncement.price, equals(originalAnnouncement.price));
      expect(convertedAnnouncement.isUrgent, equals(originalAnnouncement.isUrgent));
      expect(convertedAnnouncement.tags, equals(originalAnnouncement.tags));
    });
  });
}
