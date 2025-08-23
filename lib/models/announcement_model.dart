import 'package:cloud_firestore/cloud_firestore.dart';

enum AnnouncementType {
  sale('se-vende', '🏷️ Se Vende'),
  wanted('se-busca', '🔍 Se Busca'),
  service('servicio', '🔧 Servicio'),
  general('general', '📢 General'),
  community('comunidad', '🏘️ Comunidad');

  const AnnouncementType(this.value, this.displayName);
  final String value;
  final String displayName;
}

enum AnnouncementStatus {
  pending('pendiente', '⏳ Pendiente'),
  approved('aprobado', '✅ Aprobado'),
  rejected('rechazado', '❌ Rechazado'),
  expired('expirado', '⏰ Expirado');

  const AnnouncementStatus(this.value, this.displayName);
  final String value;
  final String displayName;
}

class Announcement {
  final String id;
  final String title;
  final String description;
  final AnnouncementType type;
  final AnnouncementStatus status;
  final String authorId;
  final String authorName;
  final String? authorPhone;
  final String? authorEmail;
  final String? authorApartment;
  final double? price;
  final List<String> images;
  final DateTime createdAt;
  final DateTime? approvedAt;
  final String? approvedBy;
  final DateTime expiresAt;
  final String? rejectionReason;
  final List<String> tags;
  final bool isUrgent;
  final int viewCount;
  final List<String> interestedUsers;

  Announcement({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.status,
    required this.authorId,
    required this.authorName,
    this.authorPhone,
    this.authorEmail,
    this.authorApartment,
    this.price,
    this.images = const [],
    required this.createdAt,
    this.approvedAt,
    this.approvedBy,
    required this.expiresAt,
    this.rejectionReason,
    this.tags = const [],
    this.isUrgent = false,
    this.viewCount = 0,
    this.interestedUsers = const [],
  });

  // Getters útiles
  bool get isPending => status == AnnouncementStatus.pending;
  bool get isApproved => status == AnnouncementStatus.approved;
  bool get isRejected => status == AnnouncementStatus.rejected;
  bool get isExpired => status == AnnouncementStatus.expired || DateTime.now().isAfter(expiresAt);
  bool get isActive => isApproved && !isExpired;
  bool get hasPrice => price != null && price! > 0;
  bool get hasImages => images.isNotEmpty;
  bool get hasContact => authorPhone != null || authorEmail != null;

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'type': type.value,
      'status': status.value,
      'authorId': authorId,
      'authorName': authorName,
      'authorPhone': authorPhone,
      'authorEmail': authorEmail,
      'authorApartment': authorApartment,
      'price': price,
      'images': images,
      'createdAt': Timestamp.fromDate(createdAt),
      'approvedAt': approvedAt != null ? Timestamp.fromDate(approvedAt!) : null,
      'approvedBy': approvedBy,
      'expiresAt': Timestamp.fromDate(expiresAt),
      'rejectionReason': rejectionReason,
      'tags': tags,
      'isUrgent': isUrgent,
      'viewCount': viewCount,
      'interestedUsers': interestedUsers,
    };
  }

  factory Announcement.fromMap(Map<String, dynamic> map, String id) {
    return Announcement(
      id: id,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      type: AnnouncementType.values.firstWhere(
        (e) => e.value == map['type'],
        orElse: () => AnnouncementType.general,
      ),
      status: AnnouncementStatus.values.firstWhere(
        (e) => e.value == map['status'],
        orElse: () => AnnouncementStatus.pending,
      ),
      authorId: map['authorId'] ?? '',
      authorName: map['authorName'] ?? '',
      authorPhone: map['authorPhone'],
      authorEmail: map['authorEmail'],
      authorApartment: map['authorApartment'],
      price: map['price']?.toDouble(),
      images: List<String>.from(map['images'] ?? []),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      approvedAt: map['approvedAt'] != null ? (map['approvedAt'] as Timestamp).toDate() : null,
      approvedBy: map['approvedBy'],
      expiresAt: (map['expiresAt'] as Timestamp).toDate(),
      rejectionReason: map['rejectionReason'],
      tags: List<String>.from(map['tags'] ?? []),
      isUrgent: map['isUrgent'] ?? false,
      viewCount: map['viewCount'] ?? 0,
      interestedUsers: List<String>.from(map['interestedUsers'] ?? []),
    );
  }

  Announcement copyWith({
    String? title,
    String? description,
    AnnouncementType? type,
    AnnouncementStatus? status,
    String? authorId,
    String? authorName,
    String? authorPhone,
    String? authorEmail,
    String? authorApartment,
    double? price,
    List<String>? images,
    DateTime? createdAt,
    DateTime? approvedAt,
    String? approvedBy,
    DateTime? expiresAt,
    String? rejectionReason,
    List<String>? tags,
    bool? isUrgent,
    int? viewCount,
    List<String>? interestedUsers,
  }) {
    return Announcement(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      status: status ?? this.status,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      authorPhone: authorPhone ?? this.authorPhone,
      authorEmail: authorEmail ?? this.authorEmail,
      authorApartment: authorApartment ?? this.authorApartment,
      price: price ?? this.price,
      images: images ?? this.images,
      createdAt: createdAt ?? this.createdAt,
      approvedAt: approvedAt ?? this.approvedAt,
      approvedBy: approvedBy ?? this.approvedBy,
      expiresAt: expiresAt ?? this.expiresAt,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      tags: tags ?? this.tags,
      isUrgent: isUrgent ?? this.isUrgent,
      viewCount: viewCount ?? this.viewCount,
      interestedUsers: interestedUsers ?? this.interestedUsers,
    );
  }
}
