import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/auth_controller.dart';
import '../models/user_model.dart';

class UserManagementView extends StatefulWidget {
  const UserManagementView({super.key});

  @override
  State<UserManagementView> createState() => _UserManagementViewState();
}

class _UserManagementViewState extends State<UserManagementView> {
  List<AppUser> _users = [];
  List<AppUser> _filteredUsers = [];
  bool _loading = true;
  final TextEditingController _searchController = TextEditingController();
  String _sortBy = 'name'; // 'name', 'email', 'role', 'date'
  bool _sortAscending = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
    _searchController.addListener(_filterUsers);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() => _loading = true);
    try {
      final authController = Provider.of<AuthController>(context, listen: false);
      final users = await authController.getAllUsers();
      setState(() {
        _users = users;
        _filteredUsers = users; // Inicialmente, mostrar todos
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error cargando usuarios: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _filterUsers() {
    final query = _searchController.text.toLowerCase().trim();
    setState(() {
      if (query.isEmpty) {
        _filteredUsers = List.from(_users);
      } else {
        _filteredUsers = _users.where((user) {
          final name = user.displayName.toLowerCase();
          final email = user.email.toLowerCase();
          final apartment = user.apartment?.toLowerCase() ?? '';
          return name.contains(query) || 
                 email.contains(query) || 
                 apartment.contains(query);
        }).toList();
      }
      _sortUsers();
    });
  }

  void _sortUsers() {
    _filteredUsers.sort((a, b) {
      int comparison = 0;
      
      switch (_sortBy) {
        case 'name':
          comparison = a.displayName.compareTo(b.displayName);
          break;
        case 'email':
          comparison = a.email.compareTo(b.email);
          break;
        case 'role':
          // Admins primero si ascendente
          comparison = a.isAdmin == b.isAdmin ? 
              a.displayName.compareTo(b.displayName) :
              (a.isAdmin ? -1 : 1);
          break;
        case 'date':
          comparison = a.createdAt.compareTo(b.createdAt);
          break;
        case 'apartment':
          final apartmentA = a.apartment ?? '';
          final apartmentB = b.apartment ?? '';
          comparison = apartmentA.compareTo(apartmentB);
          break;
      }
      
      return _sortAscending ? comparison : -comparison;
    });
  }

  void _changeSorting(String sortBy) {
    setState(() {
      if (_sortBy == sortBy) {
        _sortAscending = !_sortAscending;
      } else {
        _sortBy = sortBy;
        _sortAscending = true;
      }
      _sortUsers();
    });
  }

  void _clearSearch() {
    _searchController.clear();
    _filterUsers();
  }

  String _getSortDescription() {
    String description;
    switch (_sortBy) {
      case 'name':
        description = 'por nombre';
        break;
      case 'email':
        description = 'por email';
        break;
      case 'role':
        description = 'por rol';
        break;
      case 'date':
        description = 'por fecha de registro';
        break;
      case 'apartment':
        description = 'por apartamento';
        break;
      default:
        description = 'por nombre';
        break;
    }
    return description + (_sortAscending ? ' ↑' : ' ↓');
  }

  Future<void> _toggleUserRole(AppUser user) async {
    final authController = Provider.of<AuthController>(context, listen: false);
    final currentUser = authController.currentUser;
    
    // No permitir que el usuario se modifique a sí mismo
    if (currentUser?.uid == user.uid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No puedes modificar tu propio rol'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    bool success;
    if (user.isAdmin) {
      success = await authController.demoteAdminToUser(user.uid);
    } else {
      success = await authController.promoteUserToAdmin(user.uid);
    }

    if (success) {
      await _loadUsers();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(user.isAdmin 
              ? '${user.displayName} degradado a usuario regular'
              : '${user.displayName} promovido a administrador'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authController.errorMessage ?? 'Error modificando usuario'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _toggleUserStatus(AppUser user) async {
    final authController = Provider.of<AuthController>(context, listen: false);
    final currentUser = authController.currentUser;
    
    // No permitir que el usuario se bloquee a sí mismo
    if (currentUser?.uid == user.uid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No puedes bloquear tu propia cuenta'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Mostrar diálogo de confirmación
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(user.isActive ? 'Bloquear Usuario' : 'Desbloquear Usuario'),
        content: Text(
          user.isActive 
            ? '¿Estás seguro de que deseas bloquear a ${user.displayName}? No podrá acceder a la aplicación.'
            : '¿Estás seguro de que deseas desbloquear a ${user.displayName}? Podrá acceder nuevamente a la aplicación.'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: user.isActive ? Colors.red : Colors.green,
            ),
            child: Text(user.isActive ? 'Bloquear' : 'Desbloquear'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    bool success;
    if (user.isActive) {
      success = await authController.blockUser(user.uid);
    } else {
      success = await authController.unblockUser(user.uid);
    }

    if (success) {
      await _loadUsers();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(user.isActive 
              ? '${user.displayName} ha sido bloqueado'
              : '${user.displayName} ha sido desbloqueado'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authController.errorMessage ?? 'Error modificando estado del usuario'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Gestión de Usuarios'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _showInfoDialog,
            icon: const Icon(Icons.info_outline),
          ),
        ],
      ),
      body: Column(
        children: [
          // Cabecera con estadísticas
          _buildStatsHeader(),
          // Controles de búsqueda y filtros
          _buildSearchAndFilters(),
          // Lista de usuarios
          Expanded(
            child: _buildUsersList(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsHeader() {
    if (_loading) {
      return Container(
        padding: const EdgeInsets.all(16),
        color: Colors.white,
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 8),
            Text('Cargando estadísticas...'),
          ],
        ),
      );
    }

    final totalUsers = _users.length;
    final adminUsers = _users.where((u) => u.isAdmin).length;
    final regularUsers = totalUsers - adminUsers;
    final usersWithPhone = _users.where((u) => u.phone != null && u.phone!.isNotEmpty).length;
    final usersWithApartment = _users.where((u) => u.apartment != null && u.apartment!.isNotEmpty).length;
    final activeUsers = _users.where((u) => u.isActive).length;
    final blockedUsers = totalUsers - activeUsers;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.people, color: Colors.green, size: 24),
              const SizedBox(width: 8),
              Text(
                'Resumen de Usuarios',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              _buildStatChip('Total', totalUsers, Colors.blue),
              _buildStatChip('👑 Admins', adminUsers, Colors.purple),
              _buildStatChip('👤 Usuarios', regularUsers, Colors.orange),
              _buildStatChip('✅ Activos', activeUsers, Colors.green),
              if (blockedUsers > 0) _buildStatChip('🚫 Bloqueados', blockedUsers, Colors.red),
              _buildStatChip('📞 Con teléfono', usersWithPhone, Colors.indigo),
              _buildStatChip('🏠 Con apartamento', usersWithApartment, Colors.teal),
            ],
          ),
          if (_searchController.text.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.search, size: 16, color: Colors.amber.shade700),
                  const SizedBox(width: 4),
                  Text(
                    'Buscando: "${_searchController.text}"',
                    style: TextStyle(fontSize: 12, color: Colors.amber.shade700),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Text('Mostrando ${_filteredUsers.length} de $totalUsers usuarios'),
          ],
        ],
      ),
    );
  }

  Widget _buildStatChip(String label, int count, MaterialColor color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        '$label: $count',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color.shade700,
        ),
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        children: [
          // Barra de búsqueda
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Buscar por nombre, email o apartamento...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      onPressed: _clearSearch,
                      icon: const Icon(Icons.clear),
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              fillColor: Colors.grey.shade100,
              filled: true,
            ),
          ),
          const SizedBox(height: 12),
          // Fila de controles
          Row(
            children: [
              // Indicador de ordenamiento actual
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.sort, size: 16, color: Colors.green.shade600),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Ordenado ${_getSortDescription()}',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.green.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Botón de ordenamiento
              PopupMenuButton<String>(
                icon: const Icon(Icons.sort),
                tooltip: 'Ordenar usuarios',
                onSelected: _changeSorting,
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'name',
                    child: Row(
                      children: [
                        Icon(
                          _sortBy == 'name' 
                              ? (_sortAscending ? Icons.arrow_upward : Icons.arrow_downward)
                              : Icons.sort_by_alpha,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        const Text('Por nombre'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'role',
                    child: Row(
                      children: [
                        Icon(
                          _sortBy == 'role'
                              ? (_sortAscending ? Icons.arrow_upward : Icons.arrow_downward)
                              : Icons.admin_panel_settings,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        const Text('Por rol'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'email',
                    child: Row(
                      children: [
                        Icon(
                          _sortBy == 'email'
                              ? (_sortAscending ? Icons.arrow_upward : Icons.arrow_downward)
                              : Icons.email,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        const Text('Por email'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'apartment',
                    child: Row(
                      children: [
                        Icon(
                          _sortBy == 'apartment'
                              ? (_sortAscending ? Icons.arrow_upward : Icons.arrow_downward)
                              : Icons.home,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        const Text('Por apartamento'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'date',
                    child: Row(
                      children: [
                        Icon(
                          _sortBy == 'date'
                              ? (_sortAscending ? Icons.arrow_upward : Icons.arrow_downward)
                              : Icons.calendar_today,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        const Text('Por fecha'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUsersList() {
    if (_loading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Cargando usuarios...'),
          ],
        ),
      );
    }

    if (_filteredUsers.isEmpty && _searchController.text.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No se encontraron resultados',
              style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            Text(
              'Intenta con otros términos de búsqueda',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _clearSearch,
              icon: const Icon(Icons.clear),
              label: const Text('Limpiar búsqueda'),
            ),
          ],
        ),
      );
    }

    if (_users.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text('No hay usuarios registrados'),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadUsers,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _filteredUsers.length,
        separatorBuilder: (context, index) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final user = _filteredUsers[index];
          final currentUser = Provider.of<AuthController>(context).currentUser;
          final isCurrentUser = currentUser?.uid == user.uid;
          
          return _buildUserCard(user, isCurrentUser);
        },
      ),
    );
  }

  Widget _buildUserCard(AppUser user, bool isCurrentUser) {
    return Card(
      child: ListTile(
        leading: Stack(
          children: [
            CircleAvatar(
              backgroundColor: user.isActive
                  ? (user.isAdmin 
                      ? Colors.purple.shade100 
                      : Colors.blue.shade100)
                  : Colors.red.shade100,
              child: Icon(
                user.isAdmin ? Icons.admin_panel_settings : Icons.person,
                color: user.isActive
                    ? (user.isAdmin 
                        ? Colors.purple.shade600 
                        : Colors.blue.shade600)
                    : Colors.red.shade600,
              ),
            ),
            if (!user.isActive)
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.block,
                    color: Colors.white,
                    size: 12,
                  ),
                ),
              ),
          ],
        ),
        title: Row(
          children: [
            Expanded(child: Text(user.displayName)),
            if (isCurrentUser)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Tú',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.green.shade600,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(user.email),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: user.isActive
                        ? (user.isAdmin 
                            ? Colors.purple.shade50 
                            : Colors.blue.shade50)
                        : Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    user.isActive
                        ? (user.isAdmin ? '👑 Admin' : '👤 Usuario')
                        : '🚫 Bloqueado',
                    style: TextStyle(
                      fontSize: 12,
                      color: user.isActive
                          ? (user.isAdmin 
                              ? Colors.purple.shade600 
                              : Colors.blue.shade600)
                          : Colors.red.shade600,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (user.apartment != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      user.apartment!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange.shade600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            if (user.phone != null) ...[
              const SizedBox(height: 2),
              Text(
                '📞 ${user.phone}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ],
        ),
        trailing: isCurrentUser
            ? null
            : PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'toggle_role') {
                    _toggleUserRole(user);
                  } else if (value == 'toggle_status') {
                    _toggleUserStatus(user);
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'toggle_role',
                    child: Row(
                      children: [
                        Icon(
                          user.isAdmin 
                              ? Icons.person_remove 
                              : Icons.admin_panel_settings,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          user.isAdmin 
                              ? 'Degradar a Usuario' 
                              : 'Promover a Admin',
                        ),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'toggle_status',
                    child: Row(
                      children: [
                        Icon(
                          user.isActive 
                              ? Icons.block 
                              : Icons.check_circle,
                          size: 20,
                          color: user.isActive ? Colors.red : Colors.green,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          user.isActive 
                              ? 'Bloquear Usuario' 
                              : 'Desbloquear Usuario',
                          style: TextStyle(
                            color: user.isActive ? Colors.red : Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
        isThreeLine: true,
      ),
    );
  }

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Información'),
        content: const Text(
          'Desde aquí puedes gestionar todos los usuarios de la comunidad.\n\n'
          '• Promover usuarios a administradores o degradar administradores\n'
          '• Bloquear o desbloquear usuarios\n'
          '• Buscar usuarios por nombre, email o apartamento\n'
          '• Ver estadísticas de la comunidad\n\n'
          'Los usuarios bloqueados no podrán acceder a la aplicación.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }
}
