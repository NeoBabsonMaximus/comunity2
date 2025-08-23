import 'package:cloud_firestore/cloud_firestore.dart';

class Event {
  final String id;
  final String title;
  final String description;
  final DateTime date;
  final String location;
  final String organizer;
  final String organizerPhone; // Teléfono del organizador
  final String organizerEmail; // Email del organizador
  final String category; // Categoría del evento
  final double estimatedCost; // Costo estimado
  final int maxAttendees; // Número máximo de asistentes
  final bool requiresRegistration; // Si requiere registro
  final String requirements; // Requisitos especiales
  final String targetAudience; // Público objetivo
  final List<String> tags; // Etiquetas del evento
  final List<String> attendees;
  final bool isFavorite;

  Event({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.location,
    required this.organizer,
    this.organizerPhone = '',
    this.organizerEmail = '',
    this.category = 'general',
    this.estimatedCost = 0.0,
    this.maxAttendees = 0,
    this.requiresRegistration = true,
    this.requirements = '',
    this.targetAudience = 'todos',
    this.tags = const [],
    this.attendees = const [],
    this.isFavorite = false,
  });

  factory Event.fromMap(Map<String, dynamic> map, String id) {
    return Event(
      id: id,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      date: (map['date'] as Timestamp).toDate(),
      location: map['location'] ?? '',
      organizer: map['organizer'] ?? '',
      organizerPhone: map['organizerPhone'] ?? '',
      organizerEmail: map['organizerEmail'] ?? '',
      category: map['category'] ?? 'general',
      estimatedCost: (map['estimatedCost'] ?? 0.0).toDouble(),
      maxAttendees: map['maxAttendees'] ?? 0,
      requiresRegistration: map['requiresRegistration'] ?? true,
      requirements: map['requirements'] ?? '',
      targetAudience: map['targetAudience'] ?? 'todos',
      tags: List<String>.from(map['tags'] ?? []),
      attendees: List<String>.from(map['attendees'] ?? []),
      isFavorite: map['isFavorite'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'date': date,
      'location': location,
      'organizer': organizer,
      'organizerPhone': organizerPhone,
      'organizerEmail': organizerEmail,
      'category': category,
      'estimatedCost': estimatedCost,
      'maxAttendees': maxAttendees,
      'requiresRegistration': requiresRegistration,
      'requirements': requirements,
      'targetAudience': targetAudience,
      'tags': tags,
      'attendees': attendees,
      'isFavorite': isFavorite,
    };
  }

  Event copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? date,
    String? location,
    String? organizer,
    List<String>? attendees,
    bool? isFavorite,
  }) {
    return Event(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      date: date ?? this.date,
      location: location ?? this.location,
      organizer: organizer ?? this.organizer,
      attendees: attendees ?? this.attendees,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }
}
