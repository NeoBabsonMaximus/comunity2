import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../controllers/party_finance_controller.dart';
import '../controllers/auth_controller.dart';
import '../models/party_finance_model.dart';
import '../models/event_model.dart';
import 'add_transaction_view.dart';
import 'financial_report_view.dart';

class PartyFinanceView extends StatefulWidget {
  final Event party;

  const PartyFinanceView({
    super.key,
    required this.party,
  });

  @override
  State<PartyFinanceView> createState() => _PartyFinanceViewState();
}

class _PartyFinanceViewState extends State<PartyFinanceView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final currencyFormatter = NumberFormat.currency(locale: 'es_MX', symbol: '\$');

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PartyFinanceController(),
      child: Scaffold(
        appBar: AppBar(
          title: Consumer<AuthController>(
            builder: (context, authController, child) {
              final canManage = authController.currentUser?.canManageFinances == true;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        canManage ? 'Finanzas de la Fiesta' : 'Reporte Financiero',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      if (!canManage) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Solo lectura',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.blue.shade700,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  Text(
                    widget.party.title,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ],
              );
            },
          ),
          backgroundColor: Colors.green.shade50,
          elevation: 0,
          bottom: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(icon: Icon(Icons.analytics), text: 'Resumen'),
              Tab(icon: Icon(Icons.trending_up), text: 'Ingresos'),
              Tab(icon: Icon(Icons.trending_down), text: 'Gastos'),
              Tab(icon: Icon(Icons.pending_actions), text: 'Pendientes'),
            ],
            labelColor: Colors.green.shade700,
            unselectedLabelColor: Colors.grey.shade600,
            indicatorColor: Colors.green.shade700,
          ),
        ),
        body: Consumer<PartyFinanceController>(
          builder: (context, controller, child) {
            return StreamBuilder<List<PartyTransaction>>(
              stream: controller.getPartyTransactions(widget.party.id),
              builder: (context, snapshot) {
                print('📊 Snapshot state: ${snapshot.connectionState}');
                print('❌ Has error: ${snapshot.hasError}');
                print('✅ Has data: ${snapshot.hasData}');
                print('📈 Data length: ${snapshot.data?.length ?? 0}');

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  print('Error en StreamBuilder: ${snapshot.error}');
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error, size: 64, color: Colors.red.shade300),
                        const SizedBox(height: 16),
                        Text(
                          'Error al cargar las transacciones',
                          style: TextStyle(
                            color: Colors.red.shade600,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${snapshot.error}',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                final transactions = snapshot.data ?? [];
                final summary = controller.calculateFinanceSummary(transactions);

                return TabBarView(
                  controller: _tabController,
                  children: [
                    _buildSummaryTab(summary, transactions, controller),
                    _buildIncomesTab(transactions, controller),
                    _buildExpensesTab(transactions, controller),
                    _buildPendingTab(transactions, controller),
                  ],
                );
              },
            );
          },
        ),
        floatingActionButton: Consumer<AuthController>(
          builder: (context, authController, child) {
            if (authController.currentUser?.canManageFinances == true) {
              return FloatingActionButton.extended(
                onPressed: () => _showAddTransactionDialog(),
                backgroundColor: Colors.green.shade400,
                icon: const Icon(Icons.add),
                label: const Text('Agregar'),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildSummaryTab(PartyFinanceSummary summary, List<PartyTransaction> transactions, PartyFinanceController controller) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Tarjetas de resumen principal
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
          
          // Balance
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: summary.balance >= 0 ? Colors.green.shade50 : Colors.red.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: summary.balance >= 0 ? Colors.green.shade200 : Colors.red.shade200,
                width: 2,
              ),
            ),
            child: Column(
              children: [
                Text(
                  'Balance Final',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  currencyFormatter.format(summary.balance),
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: summary.balance >= 0 ? Colors.green.shade700 : Colors.red.shade700,
                  ),
                ),
                if (summary.balance < 0) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.red.shade100,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '⚠️ Déficit - Se necesitan más fondos',
                      style: TextStyle(
                        color: Colors.red.shade700,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Estadísticas adicionales
          Row(
            children: [
              Expanded(
                child: _buildInfoCard(
                  'Contribuyentes',
                  '${summary.totalContribuyentes} vecinos',
                  Icons.people,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildInfoCard(
                  'Transacciones',
                  '${transactions.where((t) => t.isVerified).length} verificadas',
                  Icons.verified,
                  Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Botón de reporte (disponible para todos)
          Consumer<AuthController>(
            builder: (context, authController, child) {
              final canManage = authController.currentUser?.canManageFinances == true;
              return SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _navigateToFinancialReport(summary, transactions),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade400,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.receipt_long),
                  label: Text(
                    canManage ? 'Generar Reporte Completo' : 'Ver Reporte Detallado',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String title, String amount, MaterialColor color, IconData icon) {
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
          Row(
            children: [
              Icon(icon, color: color.shade600, size: 24),
              const Spacer(),
            ],
          ),
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
            amount,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String title, String subtitle, IconData icon, MaterialColor color) {
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
            subtitle,
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

  Widget _buildIncomesTab(List<PartyTransaction> transactions, PartyFinanceController controller) {
    final incomes = controller.getTransactionsByType(transactions, 'ingreso');
    
    return _buildTransactionList(
      incomes,
      'ingresos',
      Colors.green,
      'No hay ingresos registrados aún.\n¡Agrega las colaboraciones de los vecinos!',
      controller,
    );
  }

  Widget _buildExpensesTab(List<PartyTransaction> transactions, PartyFinanceController controller) {
    final expenses = controller.getTransactionsByType(transactions, 'gasto');
    
    return _buildTransactionList(
      expenses,
      'gastos',
      Colors.red,
      'No hay gastos registrados aún.\n¡Registra las compras para la fiesta!',
      controller,
    );
  }

  Widget _buildPendingTab(List<PartyTransaction> transactions, PartyFinanceController controller) {
    final pending = controller.getPendingTransactions(transactions);
    
    if (pending.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 80,
              color: Colors.green.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              '¡Todo verificado!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.green.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'No hay transacciones pendientes de verificación',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: pending.length,
      itemBuilder: (context, index) {
        final transaction = pending[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.orange.shade100,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                Icons.pending,
                color: Colors.orange.shade600,
              ),
            ),
            title: Text(
              transaction.description,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text('Por: ${transaction.contributorName}'),
                const SizedBox(height: 2),
                Text(
                  DateFormat('dd/MM/yyyy - HH:mm').format(transaction.date),
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  currencyFormatter.format(transaction.amount),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: transaction.type == 'ingreso' ? Colors.green.shade600 : Colors.red.shade600,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Consumer<AuthController>(
                  builder: (context, authController, child) {
                    if (authController.currentUser?.canManageFinances == true) {
                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            onPressed: () => _verifyTransaction(controller, transaction, true),
                            icon: Icon(Icons.check, color: Colors.green.shade600),
                            iconSize: 20,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                          ),
                          IconButton(
                            onPressed: () => _verifyTransaction(controller, transaction, false),
                            icon: Icon(Icons.close, color: Colors.red.shade600),
                            iconSize: 20,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                          ),
                        ],
                      );
                    }
                    return Text(
                      'Pendiente de verificación',
                      style: TextStyle(
                        color: Colors.orange.shade600,
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTransactionList(
    List<PartyTransaction> transactions,
    String type,
    MaterialColor color,
    String emptyMessage,
    PartyFinanceController controller,
  ) {
    if (transactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              type == 'ingresos' ? Icons.money_off : Icons.shopping_cart_outlined,
              size: 80,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              emptyMessage,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: transactions.length,
      itemBuilder: (context, index) {
        final transaction = transactions[index];
        final categoryInfo = type == 'ingresos' 
            ? ExpenseCategories.incomeCategories[transaction.category] 
            : ExpenseCategories.categories[transaction.category];

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: transaction.isVerified ? 1 : 3,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: transaction.isVerified ? color.shade100 : Colors.orange.shade100,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                transaction.isVerified 
                    ? (type == 'ingresos' ? Icons.trending_up : Icons.trending_down)
                    : Icons.pending,
                color: transaction.isVerified ? color.shade600 : Colors.orange.shade600,
              ),
            ),
            title: Text(
              transaction.description,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text('$categoryInfo • ${transaction.contributorName}'),
                const SizedBox(height: 2),
                Text(
                  DateFormat('dd/MM/yyyy - HH:mm').format(transaction.date),
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
                if (!transaction.isVerified) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'Pendiente de verificación',
                      style: TextStyle(
                        color: Colors.orange.shade700,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            trailing: Text(
              currencyFormatter.format(transaction.amount),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color.shade600,
                fontSize: 16,
              ),
            ),
          ),
        );
      },
    );
  }

  void _showAddTransactionDialog() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddTransactionView(partyId: widget.party.id),
      ),
    );
  }

  void _navigateToFinancialReport(PartyFinanceSummary summary, List<PartyTransaction> transactions) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FinancialReportView(
          party: widget.party,
          summary: summary,
          transactions: transactions,
        ),
      ),
    );
  }

  void _verifyTransaction(PartyFinanceController controller, PartyTransaction transaction, bool isApproved) async {
    try {
      if (isApproved) {
        await controller.verifyTransaction(transaction.id, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Transacción verificada y aprobada'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        await controller.deleteTransaction(transaction.id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Transacción rechazada y eliminada'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
