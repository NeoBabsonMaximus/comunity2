import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:comunity2/models/user_model.dart';

void main() {
  group('UserRole', () {
    test('should have correct values', () {
      expect(UserRole.user.name, 'user');
      expect(UserRole.admin.name, 'admin');
    });
  });

  group('AppUser', () {
    final testTimestamp = Timestamp.fromDate(DateTime(2025, 1, 1));
    final testLastLoginTimestamp = Timestamp.fromDate(DateTime(2025, 1, 2));
    
    final testData = {
      'uid': 'test-uid',
      'email': 'test@example.com',
      'displayName': 'Test User',
      'apartment': 'Apto 101',
      'phone': '555-0123',
      'role': 'user',
      'isActive': true,
      'createdAt': testTimestamp,
      'lastLogin': testLastLoginTimestamp,
    };

    test('should create from Map data', () {
      final user = AppUser.fromMap(testData);

      expect(user.uid, 'test-uid');
      expect(user.email, 'test@example.com');
      expect(user.displayName, 'Test User');
      expect(user.apartment, 'Apto 101');
      expect(user.phone, '555-0123');
      expect(user.role, UserRole.user);
      expect(user.isActive, true);
      expect(user.createdAt, testTimestamp.toDate());
      expect(user.lastLogin, testLastLoginTimestamp.toDate());
    });

    test('should convert to Map data', () {
      final user = AppUser.fromMap(testData);
      final mapData = user.toMap();

      expect(mapData['uid'], 'test-uid');
      expect(mapData['email'], 'test@example.com');
      expect(mapData['displayName'], 'Test User');
      expect(mapData['apartment'], 'Apto 101');
      expect(mapData['phone'], '555-0123');
      expect(mapData['role'], 'user');
      expect(mapData['isActive'], true);
      expect(mapData['createdAt'], isA<Timestamp>());
      expect(mapData['lastLogin'], isA<Timestamp>());
    });

    test('should handle null values correctly', () {
      final dataWithNulls = {
        'uid': 'test-uid',
        'email': 'test@example.com',
        'displayName': 'Test User',
        'apartment': null,
        'phone': null,
        'role': 'user',
        'isActive': true,
        'createdAt': testTimestamp,
        'lastLogin': null,
      };

      final user = AppUser.fromMap(dataWithNulls);

      expect(user.apartment, null);
      expect(user.phone, null);
      expect(user.lastLogin, isNotNull); // Should use DateTime.now() as fallback
    });

    test('should use default values for missing fields', () {
      final minimalData = {
        'uid': 'test-uid',
        'email': 'test@example.com',
        'displayName': 'Test User',
        'createdAt': testTimestamp,
      };

      final user = AppUser.fromMap(minimalData);

      expect(user.role, UserRole.user); // Default role
      expect(user.isActive, true); // Default value
      expect(user.lastLogin, isNotNull); // Should use DateTime.now() as fallback
    });

    test('should parse different date formats correctly', () {
      // Test with string date
      final stringDateData = Map<String, dynamic>.from(testData);
      stringDateData['createdAt'] = '2025-01-01T00:00:00.000Z';
      stringDateData['lastLogin'] = '2025-01-02T00:00:00.000Z';
      
      final userWithStringDates = AppUser.fromMap(stringDateData);
      expect(userWithStringDates.createdAt, DateTime.parse('2025-01-01T00:00:00.000Z'));
      expect(userWithStringDates.lastLogin, DateTime.parse('2025-01-02T00:00:00.000Z'));

      // Test with DateTime objects
      final dateTimeData = Map<String, dynamic>.from(testData);
      dateTimeData['createdAt'] = DateTime(2025, 1, 1);
      dateTimeData['lastLogin'] = DateTime(2025, 1, 2);
      
      final userWithDateTimes = AppUser.fromMap(dateTimeData);
      expect(userWithDateTimes.createdAt, DateTime(2025, 1, 1));
      expect(userWithDateTimes.lastLogin, DateTime(2025, 1, 2));
    });

    test('should check role getters correctly', () {
      // User role
      final userData = Map<String, dynamic>.from(testData);
      userData['role'] = 'user';
      final user = AppUser.fromMap(userData);
      expect(user.isUser, true);
      expect(user.isAdmin, false);

      // Admin role
      final adminData = Map<String, dynamic>.from(testData);
      adminData['role'] = 'admin';
      final admin = AppUser.fromMap(adminData);
      expect(admin.isUser, false);
      expect(admin.isAdmin, true);
    });

    test('should check permission getters correctly for user', () {
      final userData = Map<String, dynamic>.from(testData);
      userData['role'] = 'user';
      final user = AppUser.fromMap(userData);

      expect(user.canCreateEvents, false);
      expect(user.canManageFinances, false);
      expect(user.canViewReports, false);
      expect(user.canManageUsers, false);
    });

    test('should check permission getters correctly for admin', () {
      final adminData = Map<String, dynamic>.from(testData);
      adminData['role'] = 'admin';
      final admin = AppUser.fromMap(adminData);

      expect(admin.canCreateEvents, true);
      expect(admin.canManageFinances, true);
      expect(admin.canViewReports, true);
      expect(admin.canManageUsers, true);
    });

    test('should create copy with modified values', () {
      final original = AppUser.fromMap(testData);
      final copy = original.copyWith(
        displayName: 'Modified Name',
        apartment: 'Apto 202',
        role: UserRole.admin,
        isActive: false,
      );

      expect(copy.displayName, 'Modified Name');
      expect(copy.apartment, 'Apto 202');
      expect(copy.role, UserRole.admin);
      expect(copy.isActive, false);
      // Other values should remain the same
      expect(copy.email, original.email);
      expect(copy.phone, original.phone);
      expect(copy.uid, original.uid);
    });

    test('should handle invalid role gracefully', () {
      final invalidRoleData = Map<String, dynamic>.from(testData);
      invalidRoleData['role'] = 'invalid_role';
      
      final user = AppUser.fromMap(invalidRoleData);
      expect(user.role, UserRole.user); // Should default to user role
    });
  });

  group('CommunityConstants', () {
    test('should have correct values', () {
      expect(CommunityConstants.communityCode, 'COMUNIDAD2025');
      expect(CommunityConstants.defaultAdminEmail, 'admin@comunidad.com');
    });
  });
}
