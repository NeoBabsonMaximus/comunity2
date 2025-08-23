import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:comunity2/models/announcement_model.dart';

void main() {
  group('AnnouncementType', () {
    test('should have correct values', () {
      expect(AnnouncementType.sale.value, 'se-vende');
      expect(AnnouncementType.wanted.value, 'se-busca');
      expect(AnnouncementType.service.value, 'servicio');
      expect(AnnouncementType.general.value, 'general');
      expect(AnnouncementType.community.value, 'comunidad');
    });

    test('should have correct display names', () {
      expect(AnnouncementType.sale.displayName, '🏷️ Se Vende');
      expect(AnnouncementType.wanted.displayName, '🔍 Se Busca');
      expect(AnnouncementType.service.displayName, '🔧 Servicio');
      expect(AnnouncementType.general.displayName, '📢 General');
      expect(AnnouncementType.community.displayName, '🏘️ Comunidad');
    });
  });

  group('AnnouncementStatus', () {
    test('should have correct values', () {
      expect(AnnouncementStatus.pending.value, 'pendiente');
      expect(AnnouncementStatus.approved.value, 'aprobado');
      expect(AnnouncementStatus.rejected.value, 'rechazado');
      expect(AnnouncementStatus.expired.value, 'expirado');
    });

    test('should have correct display names', () {
      expect(AnnouncementStatus.pending.displayName, '⏳ Pendiente');
      expect(AnnouncementStatus.approved.displayName, '✅ Aprobado');
      expect(AnnouncementStatus.rejected.displayName, '❌ Rechazado');
      expect(AnnouncementStatus.expired.displayName, '⏰ Expirado');
    });
  });

  group('Announcement', () {
    final testTimestamp = Timestamp.fromDate(DateTime(2025, 1, 1));
    final testExpiryTimestamp = Timestamp.fromDate(DateTime(2025, 12, 1)); // Future date
    
    final testData = {
      'title': 'Test Announcement',
      'description': 'Test description',
      'type': 'se-vende',
      'status': 'aprobado',
      'isUrgent': false,
      'price': 1000.0,
      'authorId': 'user123',
      'authorName': 'Test User',
      'authorApartment': 'Apto 101',
      'authorPhone': '555-0123',
      'authorEmail': 'test@example.com',
      'createdAt': testTimestamp,
      'expiresAt': testExpiryTimestamp,
      'approvedAt': testTimestamp,
      'approvedBy': 'admin123',
      'rejectionReason': null,
      'tags': <String>[],
      'images': <String>[],
      'viewCount': 0,
      'interestedUsers': <String>[],
    };

    test('should create from Map data', () {
      final announcement = Announcement.fromMap(testData, 'test-id');

      expect(announcement.id, 'test-id');
      expect(announcement.title, 'Test Announcement');
      expect(announcement.description, 'Test description');
      expect(announcement.type, AnnouncementType.sale);
      expect(announcement.status, AnnouncementStatus.approved);
      expect(announcement.isUrgent, false);
      expect(announcement.price, 1000.0);
      expect(announcement.authorId, 'user123');
      expect(announcement.authorName, 'Test User');
      expect(announcement.authorApartment, 'Apto 101');
      expect(announcement.authorPhone, '555-0123');
      expect(announcement.authorEmail, 'test@example.com');
      expect(announcement.createdAt, testTimestamp.toDate());
      expect(announcement.expiresAt, testExpiryTimestamp.toDate());
      expect(announcement.approvedAt, testTimestamp.toDate());
      expect(announcement.approvedBy, 'admin123');
      expect(announcement.rejectionReason, null);
    });

    test('should convert to Map data', () {
      final announcement = Announcement.fromMap(testData, 'test-id');
      final mapData = announcement.toMap();

      expect(mapData['title'], 'Test Announcement');
      expect(mapData['description'], 'Test description');
      expect(mapData['type'], 'se-vende');
      expect(mapData['status'], 'aprobado');
      expect(mapData['isUrgent'], false);
      expect(mapData['price'], 1000.0);
      expect(mapData['authorId'], 'user123');
      expect(mapData['authorName'], 'Test User');
      expect(mapData['authorApartment'], 'Apto 101');
      expect(mapData['authorPhone'], '555-0123');
      expect(mapData['authorEmail'], 'test@example.com');
      expect(mapData['createdAt'], isA<Timestamp>());
      expect(mapData['expiresAt'], isA<Timestamp>());
      expect(mapData['approvedAt'], isA<Timestamp>());
      expect(mapData['approvedBy'], 'admin123');
      expect(mapData['rejectionReason'], null);
    });

    test('should handle null values correctly', () {
      final dataWithNulls = Map<String, dynamic>.from(testData);
      dataWithNulls['price'] = null;
      dataWithNulls['authorPhone'] = null;
      dataWithNulls['approvedAt'] = null;
      dataWithNulls['approvedBy'] = null;

      final announcement = Announcement.fromMap(dataWithNulls, 'test-id');

      expect(announcement.price, null);
      expect(announcement.authorPhone, null);
      expect(announcement.approvedAt, null);
      expect(announcement.approvedBy, null);
    });

    test('should use default values for missing fields', () {
      final minimalData = {
        'title': 'Test',
        'description': 'Test description',
        'type': 'general',
        'status': 'pendiente',
        'authorId': 'user123',
        'authorName': 'Test User',
        'createdAt': testTimestamp,
        'expiresAt': testExpiryTimestamp,
      };

      final announcement = Announcement.fromMap(minimalData, 'test-id');

      expect(announcement.type, AnnouncementType.general);
      expect(announcement.status, AnnouncementStatus.pending);
      expect(announcement.isUrgent, false);
      expect(announcement.viewCount, 0);
      expect(announcement.images, isEmpty);
      expect(announcement.tags, isEmpty);
      expect(announcement.interestedUsers, isEmpty);
    });

    test('should check if announcement is expired correctly', () {
      final now = DateTime.now();
      
      // Future expiry date - not expired
      final futureData = Map<String, dynamic>.from(testData);
      futureData['expiresAt'] = Timestamp.fromDate(now.add(Duration(days: 1)));
      final futureAnnouncement = Announcement.fromMap(futureData, 'test-id');
      expect(futureAnnouncement.isExpired, false);

      // Past expiry date - expired
      final pastData = Map<String, dynamic>.from(testData);
      pastData['expiresAt'] = Timestamp.fromDate(now.subtract(Duration(days: 1)));
      final pastAnnouncement = Announcement.fromMap(pastData, 'test-id');
      expect(pastAnnouncement.isExpired, true);
    });

    test('should check if announcement is active correctly', () {
      final now = DateTime.now();
      
      // Approved and not expired - active
      final activeData = Map<String, dynamic>.from(testData);
      activeData['status'] = 'aprobado';
      activeData['expiresAt'] = Timestamp.fromDate(now.add(Duration(days: 1)));
      final activeAnnouncement = Announcement.fromMap(activeData, 'test-id');
      expect(activeAnnouncement.isActive, true);

      // Pending - not active
      final pendingData = Map<String, dynamic>.from(testData);
      pendingData['status'] = 'pendiente';
      final pendingAnnouncement = Announcement.fromMap(pendingData, 'test-id');
      expect(pendingAnnouncement.isActive, false);

      // Expired - not active
      final expiredData = Map<String, dynamic>.from(testData);
      expiredData['status'] = 'aprobado';
      expiredData['expiresAt'] = Timestamp.fromDate(now.subtract(Duration(days: 1)));
      final expiredAnnouncement = Announcement.fromMap(expiredData, 'test-id');
      expect(expiredAnnouncement.isActive, false);
    });

    test('should check status getters correctly', () {
      // Pending
      final pendingData = Map<String, dynamic>.from(testData);
      pendingData['status'] = 'pendiente';
      final pendingAnnouncement = Announcement.fromMap(pendingData, 'test-id');
      expect(pendingAnnouncement.isPending, true);
      expect(pendingAnnouncement.isApproved, false);
      expect(pendingAnnouncement.isRejected, false);

      // Approved
      final approvedData = Map<String, dynamic>.from(testData);
      approvedData['status'] = 'aprobado';
      final approvedAnnouncement = Announcement.fromMap(approvedData, 'test-id');
      expect(approvedAnnouncement.isPending, false);
      expect(approvedAnnouncement.isApproved, true);
      expect(approvedAnnouncement.isRejected, false);

      // Rejected
      final rejectedData = Map<String, dynamic>.from(testData);
      rejectedData['status'] = 'rechazado';
      final rejectedAnnouncement = Announcement.fromMap(rejectedData, 'test-id');
      expect(rejectedAnnouncement.isPending, false);
      expect(rejectedAnnouncement.isApproved, false);
      expect(rejectedAnnouncement.isRejected, true);
    });

    test('should check helper getters correctly', () {
      // Has price
      final withPriceData = Map<String, dynamic>.from(testData);
      withPriceData['price'] = 1000.0;
      final withPriceAnnouncement = Announcement.fromMap(withPriceData, 'test-id');
      expect(withPriceAnnouncement.hasPrice, true);

      // No price
      final noPriceData = Map<String, dynamic>.from(testData);
      noPriceData['price'] = null;
      final noPriceAnnouncement = Announcement.fromMap(noPriceData, 'test-id');
      expect(noPriceAnnouncement.hasPrice, false);

      // Has contact
      final withContactData = Map<String, dynamic>.from(testData);
      withContactData['authorPhone'] = '555-0123';
      final withContactAnnouncement = Announcement.fromMap(withContactData, 'test-id');
      expect(withContactAnnouncement.hasContact, true);

      // No contact
      final noContactData = Map<String, dynamic>.from(testData);
      noContactData['authorPhone'] = null;
      noContactData['authorEmail'] = null;
      final noContactAnnouncement = Announcement.fromMap(noContactData, 'test-id');
      expect(noContactAnnouncement.hasContact, false);
    });

    test('should create copy with modified values', () {
      final original = Announcement.fromMap(testData, 'test-id');
      final copy = original.copyWith(
        title: 'Modified Title',
        price: 2000.0,
        isUrgent: true,
      );

      expect(copy.title, 'Modified Title');
      expect(copy.price, 2000.0);
      expect(copy.isUrgent, true);
      // Other values should remain the same
      expect(copy.description, original.description);
      expect(copy.authorName, original.authorName);
      expect(copy.id, original.id);
    });
  });
}
