import 'package:cloud_firestore/cloud_firestore.dart';

// Modelo para las transacciones financieras de las fiestas
class PartyTransaction {
  final String id;
  final String partyId;
  final String type; // 'ingreso' o 'gasto'
  final String category; // 'decoracion', 'comida', 'musica', 'colaboracion_vecino', etc.
  final double amount;
  final String description;
  final String contributorName; // Nombre del vecino que contribuyó o gastó
  final DateTime date;
  final String? receiptUrl; // URL de la foto del recibo
  final bool isVerified; // Si fue verificado por el organizador

  PartyTransaction({
    required this.id,
    required this.partyId,
    required this.type,
    required this.category,
    required this.amount,
    required this.description,
    required this.contributorName,
    required this.date,
    this.receiptUrl,
    this.isVerified = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'partyId': partyId,
      'type': type,
      'category': category,
      'amount': amount,
      'description': description,
      'contributorName': contributorName,
      'date': Timestamp.fromDate(date),
      'receiptUrl': receiptUrl,
      'isVerified': isVerified,
    };
  }

  factory PartyTransaction.fromMap(Map<String, dynamic> map, String id) {
    return PartyTransaction(
      id: id,
      partyId: map['partyId'] ?? '',
      type: map['type'] ?? '',
      category: map['category'] ?? '',
      amount: (map['amount'] ?? 0.0).toDouble(),
      description: map['description'] ?? '',
      contributorName: map['contributorName'] ?? '',
      date: (map['date'] as Timestamp).toDate(),
      receiptUrl: map['receiptUrl'],
      isVerified: map['isVerified'] ?? false,
    );
  }
}

// Modelo para el resumen financiero de la fiesta
class PartyFinanceSummary {
  final String partyId;
  final double totalIngresos;
  final double totalGastos;
  final double balance;
  final Map<String, double> gastosPorCategoria;
  final Map<String, double> ingresosPorVecino;
  final int totalContribuyentes;

  PartyFinanceSummary({
    required this.partyId,
    required this.totalIngresos,
    required this.totalGastos,
    required this.balance,
    required this.gastosPorCategoria,
    required this.ingresosPorVecino,
    required this.totalContribuyentes,
  });
}

// Categorías predefinidas para gastos
class ExpenseCategories {
  static const Map<String, String> categories = {
    'decoracion': '🎈 Decoración',
    'comida': '🍕 Comida y Bebidas',
    'musica': '🎵 Música y Sonido',
    'limpieza': '🧹 Limpieza',
    'seguridad': '🔒 Seguridad',
    'permisos': '📄 Permisos',
    'premios': '🏆 Premios y Rifas',
    'otros_gastos': '📦 Otros Gastos',
  };

  static const Map<String, String> incomeCategories = {
    'colaboracion': '🤝 Colaboración Vecino',
    'rifa': '🎫 Rifa',
    'venta': '🛍️ Venta de Productos',
    'patrocinio': '🏢 Patrocinio Local',
    'otros_ingresos': '💰 Otros Ingresos',
  };
}
