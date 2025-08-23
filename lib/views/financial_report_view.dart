import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../models/party_finance_model.dart';
import '../models/event_model.dart';

class FinancialReportView extends StatelessWidget {
  final Event party;
  final PartyFinanceSummary summary;
  final List<PartyTransaction> transactions;

  const FinancialReportView({
    super.key,
    required this.party,
    required this.summary,
    required this.transactions,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(locale: 'es_MX', symbol: '\$');
    final dateFormatter = DateFormat('dd/MM/yyyy');
    final verifiedTransactions = transactions.where((t) => t.isVerified).toList();

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Reporte Financiero',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              party.title,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.blue.shade50,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => _shareReport(context),
            icon: const Icon(Icons.share),
            tooltip: 'Compartir Reporte',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header del reporte
            _buildReportHeader(currencyFormatter, dateFormatter),
            const SizedBox(height: 24),

            // Resumen ejecutivo
            _buildExecutiveSummary(currencyFormatter),
            const SizedBox(height: 24),

            // Detalle de ingresos
            _buildIncomeDetail(currencyFormatter),
            const SizedBox(height: 24),

            // Detalle de gastos
            _buildExpenseDetail(currencyFormatter),
            const SizedBox(height: 24),

            // Análisis de participación
            _buildParticipationAnalysis(),
            const SizedBox(height: 24),

            // Lista detallada de transacciones
            _buildTransactionDetail(currencyFormatter, verifiedTransactions),
          ],
        ),
      ),
    );
  }

  Widget _buildReportHeader(NumberFormat currencyFormatter, DateFormat dateFormatter) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade400, Colors.blue.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.receipt_long,
                color: Colors.white,
                size: 32,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Reporte de Transparencia Financiera',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Generado el ${dateFormatter.format(DateTime.now())}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Balance Final',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        currencyFormatter.format(summary.balance),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: summary.balance >= 0 
                        ? Colors.green.withOpacity(0.2)
                        : Colors.red.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    summary.balance >= 0 
                        ? Icons.trending_up
                        : Icons.trending_down,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExecutiveSummary(NumberFormat currencyFormatter) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '📊 Resumen Ejecutivo',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                'Total Ingresos',
                currencyFormatter.format(summary.totalIngresos),
                Colors.green,
                Icons.trending_up,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSummaryCard(
                'Total Gastos',
                currencyFormatter.format(summary.totalGastos),
                Colors.red,
                Icons.trending_down,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                'Contribuyentes',
                '${summary.totalContribuyentes} vecinos',
                Colors.blue,
                Icons.people,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSummaryCard(
                'Transparencia',
                '${transactions.where((t) => t.isVerified).length}/${transactions.length} verificadas',
                Colors.orange,
                Icons.verified,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSummaryCard(String title, String value, MaterialColor color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color.shade600, size: 24),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: color.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIncomeDetail(NumberFormat currencyFormatter) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '💰 Detalle de Ingresos',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        if (summary.ingresosPorVecino.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Text(
                'No hay ingresos registrados',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          )
        else
          ...summary.ingresosPorVecino.entries.map((entry) {
            final percentage = (entry.value / summary.totalIngresos) * 100;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.key,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${percentage.toStringAsFixed(1)}% del total',
                          style: TextStyle(
                            color: Colors.green.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    currencyFormatter.format(entry.value),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade700,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }

  Widget _buildExpenseDetail(NumberFormat currencyFormatter) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '💸 Detalle de Gastos por Categoría',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        if (summary.gastosPorCategoria.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Text(
                'No hay gastos registrados',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          )
        else
          ...summary.gastosPorCategoria.entries.map((entry) {
            final percentage = (entry.value / summary.totalGastos) * 100;
            final categoryInfo = ExpenseCategories.categories[entry.key] ?? entry.key;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          categoryInfo,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${percentage.toStringAsFixed(1)}% del total',
                          style: TextStyle(
                            color: Colors.red.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    currencyFormatter.format(entry.value),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.red.shade700,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }

  Widget _buildParticipationAnalysis() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '👥 Análisis de Participación',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildParticipationMetric(
                    'Vecinos Participantes',
                    '${summary.totalContribuyentes}',
                    Icons.people,
                    Colors.blue,
                  ),
                  _buildParticipationMetric(
                    'Promedio por Persona',
                    NumberFormat.currency(locale: 'es_MX', symbol: '\$').format(
                      summary.totalContribuyentes > 0 
                          ? summary.totalIngresos / summary.totalContribuyentes
                          : 0,
                    ),
                    Icons.account_balance_wallet,
                    Colors.green,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (summary.totalContribuyentes > 0) ...[
                Text(
                  '🎉 ¡Excelente participación comunitaria!',
                  style: TextStyle(
                    color: Colors.blue.shade700,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'La colaboración de ${summary.totalContribuyentes} vecinos demuestra el espíritu comunitario de nuestro barrio.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.blue.shade600,
                    fontSize: 14,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildParticipationMetric(String title, String value, IconData icon, MaterialColor color) {
    return Column(
      children: [
        Icon(icon, color: color.shade600, size: 32),
        const SizedBox(height: 8),
        Text(
          title,
          style: TextStyle(
            color: color.shade600,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: color.shade700,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionDetail(NumberFormat currencyFormatter, List<PartyTransaction> verifiedTransactions) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '📋 Detalle de Transacciones Verificadas',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        if (verifiedTransactions.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Text(
                'No hay transacciones verificadas',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          )
        else
          ...verifiedTransactions.map((transaction) {
            final isIncome = transaction.type == 'ingreso';
            final color = isIncome ? Colors.green : Colors.red;
            final categoryInfo = isIncome
                ? ExpenseCategories.incomeCategories[transaction.category]
                : ExpenseCategories.categories[transaction.category];

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.shade100,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color.shade100,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      isIncome ? Icons.trending_up : Icons.trending_down,
                      color: color.shade600,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          transaction.description,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$categoryInfo • ${transaction.contributorName}',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          DateFormat('dd/MM/yyyy - HH:mm').format(transaction.date),
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    currencyFormatter.format(transaction.amount),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: color.shade700,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }

  void _shareReport(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(locale: 'es_MX', symbol: '\$');
    final dateFormatter = DateFormat('dd/MM/yyyy HH:mm');
    final verifiedTransactions = transactions.where((t) => t.isVerified).toList();
    
    // Generar el texto del reporte
    String reportText = '''
📊 REPORTE FINANCIERO - ${party.title.toUpperCase()}
═══════════════════════════════════════════════

📅 Fecha del evento: ${DateFormat('dd/MM/yyyy').format(party.date)}
📍 Ubicación: ${party.location}

💰 RESUMEN FINANCIERO
═══════════════════════════════════════════════
• Total de Ingresos: ${currencyFormatter.format(summary.totalIngresos)}
• Total de Gastos: ${currencyFormatter.format(summary.totalGastos)}
• Balance Final: ${currencyFormatter.format(summary.balance)}

📈 ESTADÍSTICAS
═══════════════════════════════════════════════
• Total de Transacciones: ${transactions.length}
• Transacciones Verificadas: ${verifiedTransactions.length}
• Pendientes de Verificación: ${transactions.length - verifiedTransactions.length}

💸 DETALLE DE TRANSACCIONES VERIFICADAS
═══════════════════════════════════════════════''';

    // Agregar ingresos
    final incomes = verifiedTransactions.where((t) => t.type == 'ingreso').toList();
    if (incomes.isNotEmpty) {
      reportText += '\n\n💰 INGRESOS (${incomes.length}):';
      for (var transaction in incomes) {
        reportText += '\n• ${transaction.description}';
        reportText += '\n  ${currencyFormatter.format(transaction.amount)}';
        reportText += '\n  ${dateFormatter.format(transaction.date)}';
        reportText += '\n  Contribuyente: ${transaction.contributorName}';
        if (transaction.category.isNotEmpty) {
          reportText += '\n  Categoría: ${transaction.category}';
        }
        reportText += '\n';
      }
    }

    // Agregar gastos
    final expenses = verifiedTransactions.where((t) => t.type == 'gasto').toList();
    if (expenses.isNotEmpty) {
      reportText += '\n\n💸 GASTOS (${expenses.length}):';
      for (var transaction in expenses) {
        reportText += '\n• ${transaction.description}';
        reportText += '\n  ${currencyFormatter.format(transaction.amount)}';
        reportText += '\n  ${dateFormatter.format(transaction.date)}';
        reportText += '\n  Responsable: ${transaction.contributorName}';
        if (transaction.category.isNotEmpty) {
          reportText += '\n  Categoría: ${transaction.category}';
        }
        reportText += '\n';
      }
    }

    // Agregar análisis por categorías
    if (verifiedTransactions.isNotEmpty) {
      final Map<String, double> incomesByCategory = {};
      final Map<String, double> expensesByCategory = {};
      
      for (var transaction in verifiedTransactions) {
        final category = transaction.category.isEmpty ? 'Sin categoría' : transaction.category;
        
        if (transaction.type == 'ingreso') {
          incomesByCategory[category] = (incomesByCategory[category] ?? 0) + transaction.amount;
        } else {
          expensesByCategory[category] = (expensesByCategory[category] ?? 0) + transaction.amount;
        }
      }
      
      if (incomesByCategory.isNotEmpty) {
        reportText += '\n\n📊 INGRESOS POR CATEGORÍA:';
        incomesByCategory.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value))
          ..forEach((entry) {
            reportText += '\n• ${entry.key}: ${currencyFormatter.format(entry.value)}';
          });
      }
      
      if (expensesByCategory.isNotEmpty) {
        reportText += '\n\n📊 GASTOS POR CATEGORÍA:';
        expensesByCategory.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value))
          ..forEach((entry) {
            reportText += '\n• ${entry.key}: ${currencyFormatter.format(entry.value)}';
          });
      }
    }

    // Agregar información de contribuyentes
    if (summary.ingresosPorVecino.isNotEmpty) {
      reportText += '\n\n👥 CONTRIBUCIONES POR VECINO:';
      summary.ingresosPorVecino.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value))
        ..forEach((entry) {
          reportText += '\n• ${entry.key}: ${currencyFormatter.format(entry.value)}';
        });
    }

    // Agregar pie del reporte
    reportText += '\n\n═══════════════════════════════════════════════';
    reportText += '\n📱 Generado por Community App';
    reportText += '\n🕒 ${dateFormatter.format(DateTime.now())}';
    reportText += '\n═══════════════════════════════════════════════';

    // Compartir el reporte
    Share.share(
      reportText,
      subject: 'Reporte Financiero - ${party.title}',
    ).then((_) {
      // Mostrar confirmación - verificar si el widget sigue montado
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Reporte compartido exitosamente'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }).catchError((error) {
      // Mostrar error si falla el compartir - verificar si el widget sigue montado
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Text('Error al compartir: $error'),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    });
  }
}
