import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/party_finance_model.dart';

class PartyFinanceController extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'party_transactions';

  // Obtener todas las transacciones de una fiesta
  Stream<List<PartyTransaction>> getPartyTransactions(String partyId) {
    print('🔍 Buscando transacciones para party ID: $partyId');
    return _firestore
        .collection(_collection)
        .where('partyId', isEqualTo: partyId)
        .snapshots()
        .map((snapshot) {
      print('📊 Documentos encontrados: ${snapshot.docs.length}');
      for (var doc in snapshot.docs) {
        print('📄 Doc ID: ${doc.id}, Data: ${doc.data()}');
      }
      final transactions = snapshot.docs
          .map((doc) => PartyTransaction.fromMap(doc.data(), doc.id))
          .toList();
      
      // Ordenar por fecha en memoria en lugar de en la query
      transactions.sort((a, b) => b.date.compareTo(a.date));
      print('🎯 Final transactions count: ${transactions.length}');
      return transactions;
    });
  }

  // Agregar una nueva transacción (ingreso o gasto)
  Future<void> addTransaction(PartyTransaction transaction) async {
    try {
      await _firestore.collection(_collection).add(transaction.toMap());
      notifyListeners();
    } catch (e) {
      throw Exception('Error al agregar transacción: $e');
    }
  }

  // Actualizar una transacción existente
  Future<void> updateTransaction(PartyTransaction transaction) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(transaction.id)
          .update(transaction.toMap());
      notifyListeners();
    } catch (e) {
      throw Exception('Error al actualizar transacción: $e');
    }
  }

  // Eliminar una transacción
  Future<void> deleteTransaction(String transactionId) async {
    try {
      await _firestore.collection(_collection).doc(transactionId).delete();
      notifyListeners();
    } catch (e) {
      throw Exception('Error al eliminar transacción: $e');
    }
  }

  // Verificar/Aprobar una transacción
  Future<void> verifyTransaction(String transactionId, bool isVerified) async {
    try {
      await _firestore.collection(_collection).doc(transactionId).update({
        'isVerified': isVerified,
      });
      notifyListeners();
    } catch (e) {
      throw Exception('Error al verificar transacción: $e');
    }
  }

  // Calcular el resumen financiero de una fiesta
  PartyFinanceSummary calculateFinanceSummary(List<PartyTransaction> transactions) {
    print('🧮 Calculando resumen para ${transactions.length} transacciones');
    double totalIngresos = 0;
    double totalGastos = 0;
    Map<String, double> gastosPorCategoria = {};
    Map<String, double> ingresosPorVecino = {};
    Set<String> contribuyentes = {};

    // Incluir TODAS las transacciones (verificadas y no verificadas) en el resumen
    for (var transaction in transactions) {
      print('💰 Procesando transacción: ${transaction.type}, ${transaction.amount}, verificada: ${transaction.isVerified}');
      
      if (transaction.type == 'ingreso') {
        totalIngresos += transaction.amount;
        ingresosPorVecino[transaction.contributorName] = 
            (ingresosPorVecino[transaction.contributorName] ?? 0) + transaction.amount;
        contribuyentes.add(transaction.contributorName);
      } else {
        totalGastos += transaction.amount;
        gastosPorCategoria[transaction.category] = 
            (gastosPorCategoria[transaction.category] ?? 0) + transaction.amount;
      }
    }

    print('💵 Total ingresos: $totalIngresos');
    print('💸 Total gastos: $totalGastos');
    print('⚖️ Balance: ${totalIngresos - totalGastos}');

    return PartyFinanceSummary(
      partyId: transactions.isNotEmpty ? transactions.first.partyId : '',
      totalIngresos: totalIngresos,
      totalGastos: totalGastos,
      balance: totalIngresos - totalGastos,
      gastosPorCategoria: gastosPorCategoria,
      ingresosPorVecino: ingresosPorVecino,
      totalContribuyentes: contribuyentes.length,
    );
  }

  // Obtener transacciones por tipo
  List<PartyTransaction> getTransactionsByType(List<PartyTransaction> transactions, String type) {
    return transactions.where((t) => t.type == type).toList();
  }

  // Obtener transacciones pendientes de verificación
  List<PartyTransaction> getPendingTransactions(List<PartyTransaction> transactions) {
    return transactions.where((t) => !t.isVerified).toList();
  }

  // Generar reporte financiero
  Map<String, dynamic> generateFinancialReport(PartyFinanceSummary summary, List<PartyTransaction> transactions) {
    return {
      'resumen': {
        'totalIngresos': summary.totalIngresos,
        'totalGastos': summary.totalGastos,
        'balance': summary.balance,
        'totalContribuyentes': summary.totalContribuyentes,
        'fecha_generacion': DateTime.now().toIso8601String(),
      },
      'detalle_gastos': summary.gastosPorCategoria,
      'detalle_ingresos': summary.ingresosPorVecino,
      'transacciones_verificadas': transactions.where((t) => t.isVerified).length,
      'transacciones_pendientes': transactions.where((t) => !t.isVerified).length,
    };
  }

  // Validar si hay fondos suficientes para un gasto
  bool hasSufficientFunds(PartyFinanceSummary summary, double proposedExpense) {
    return summary.balance >= proposedExpense;
  }
}
