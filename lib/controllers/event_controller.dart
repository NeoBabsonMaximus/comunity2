import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/event_model.dart';

class EventController extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'events';

  // Obtener todos los eventos
  Stream<List<Event>> getEvents() {
    return _firestore
        .collection(_collection)
        .orderBy('date')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Event.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  // Crear un nuevo evento
  Future<void> createEvent(Event event) async {
    await _firestore.collection(_collection).add(event.toMap());
  }

  // Actualizar un evento existente
  Future<void> updateEvent(Event event) async {
    await _firestore
        .collection(_collection)
        .doc(event.id)
        .update(event.toMap());
  }

  // Eliminar un evento
  Future<void> deleteEvent(String eventId) async {
    await _firestore.collection(_collection).doc(eventId).delete();
  }

  // Registrarse o desregistrarse de un evento (nuevo sistema con nombres)
  Future<void> registerForEvent(String eventId, String userId, String userName) async {
    try {
      await _firestore.collection(_collection).doc(eventId).update({
        'attendees': FieldValue.arrayUnion(['$userId|$userName'])
      });
      notifyListeners();
      print('Usuario $userName registrado en evento $eventId');
    } catch (e) {
      print('Error al registrarse en evento: $e');
      rethrow;
    }
  }

  Future<void> unregisterFromEvent(String eventId, String userId, String userName) async {
    try {
      await _firestore.collection(_collection).doc(eventId).update({
        'attendees': FieldValue.arrayRemove(['$userId|$userName'])
      });
      notifyListeners();
      print('Usuario $userName desregistrado del evento $eventId');
    } catch (e) {
      print('Error al desregistrarse del evento: $e');
      rethrow;
    }
  }

  // Verificar si un usuario está registrado en un evento
  bool isUserRegistered(Event event, String userId) {
    return event.attendees.any((attendee) => attendee.startsWith('$userId|'));
  }

  // Obtener lista de nombres de asistentes
  List<String> getAttendeeNames(Event event) {
    return event.attendees.map((attendee) {
      final parts = attendee.split('|');
      return parts.length > 1 ? parts[1] : attendee;
    }).toList();
  }

  // Registrar asistencia a un evento (método legacy)
  Future<void> registerAttendance(String eventId, String userId) async {
    await _firestore.collection(_collection).doc(eventId).update({
      'attendees': FieldValue.arrayUnion([userId])
    });
  }

  // Cancelar asistencia a un evento
  Future<void> cancelAttendance(String eventId, String userId) async {
    await _firestore.collection(_collection).doc(eventId).update({
      'attendees': FieldValue.arrayRemove([userId])
    });
  }

  // Toggle favorite status por usuario
  Future<void> toggleFavorite(String eventId, String userId) async {
    try {
      final userFavoritesRef = _firestore.collection('user_favorites').doc(userId);
      final doc = await userFavoritesRef.get();
      
      List<String> favorites = [];
      if (doc.exists) {
        favorites = List<String>.from(doc.data()?['favoriteEvents'] ?? []);
      }
      
      if (favorites.contains(eventId)) {
        favorites.remove(eventId);
      } else {
        favorites.add(eventId);
      }
      
      await userFavoritesRef.set({
        'favoriteEvents': favorites,
        'lastUpdated': Timestamp.now(),
      });
      
      notifyListeners();
      print('Favorito actualizado para usuario $userId: $eventId');
    } catch (e) {
      print('Error al actualizar favorito: $e');
    }
  }

  // Verificar si un evento es favorito para un usuario
  Future<bool> isFavoriteForUser(String eventId, String userId) async {
    try {
      final doc = await _firestore.collection('user_favorites').doc(userId).get();
      if (!doc.exists) return false;
      
      List<String> favorites = List<String>.from(doc.data()?['favoriteEvents'] ?? []);
      return favorites.contains(eventId);
    } catch (e) {
      print('Error checking favorite: $e');
      return false;
    }
  }

  // Obtener eventos favoritos de un usuario
  Stream<List<Event>> getUserFavoriteEvents(String userId) {
    return _firestore.collection('user_favorites').doc(userId).snapshots().asyncMap((userDoc) async {
      if (!userDoc.exists) return [];
      
      List<String> favoriteIds = List<String>.from(userDoc.data()?['favoriteEvents'] ?? []);
      if (favoriteIds.isEmpty) return [];
      
      // Obtener los eventos favoritos
      List<Event> favoriteEvents = [];
      for (String eventId in favoriteIds) {
        try {
          final eventDoc = await _firestore.collection(_collection).doc(eventId).get();
          if (eventDoc.exists) {
            favoriteEvents.add(Event.fromMap(eventDoc.data()!, eventDoc.id));
          }
        } catch (e) {
          print('Error loading favorite event $eventId: $e');
        }
      }
      
      return favoriteEvents;
    });
  }

  // Verificar si un usuario está registrado para un evento (asíncrono)
  Future<bool> isUserRegisteredForEvent(String eventId, String userId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(eventId).get();
      if (!doc.exists) return false;
      
      final event = Event.fromMap(doc.data()!, doc.id);
      return event.attendees.any((attendee) => attendee.startsWith('$userId|'));
    } catch (e) {
      print('Error checking user registration: $e');
      return false;
    }
  }

  // Verificar si el usuario puede registrarse (no está ya registrado)
  Future<bool> canUserRegister(String eventId, String userId) async {
    return !(await isUserRegisteredForEvent(eventId, userId));
  }

  // Obtener el número de participantes de un evento
  Future<int> getEventAttendeeCount(String eventId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(eventId).get();
      if (!doc.exists) return 0;
      
      final event = Event.fromMap(doc.data()!, doc.id);
      return event.attendees.length;
    } catch (e) {
      print('Error getting attendee count: $e');
      return 0;
    }
  }

  // Obtener eventos próximos (para compatibilidad con código existente)
  List<Event> getUpcomingEvents() {
    // Este método ahora es síncrono pero limitado
    // Se recomienda usar getEvents() para datos en tiempo real
    return [];
  }

  // Obtener evento por ID
  Event? getEventById(String id) {
    // Implementar si es necesario
    return null;
  }

  // Obtener eventos favoritos
  Stream<List<Event>> getFavoriteEvents() {
    return _firestore
        .collection(_collection)
        .where('isFavorite', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Event.fromMap(doc.data(), doc.id))
            .toList());
  }
}
