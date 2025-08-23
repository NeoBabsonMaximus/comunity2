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

  void _changeSorting(String newSortBy) {
    setState(() {
      if (_sortBy == newSortBy) {
        _sortAscending = !_sortAscending;
      } else {
        _sortBy = newSortBy;
        _sortAscending = true;
      }
      _sortUsers();
    });
  }

  void _clearSearch() {
    _searchController.clear();
    _filterUsers();
  }

  String _getSortingDescription() {
    String description = '';
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
        description = 'por fecha';
        break;
      case 'apartment':
        description = 'por apartamento';
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

    final isPromoting = user.role == UserRole.user;
    final action = isPromoting ? 'promover a administrador' : 'degradar a usuario';
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${isPromoting ? 'Promover' : 'Degradar'} Usuario'),
        content: Text(
          '¿Estás seguro que deseas $action a ${user.displayName}?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: isPromoting ? Colors.green : Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: Text(isPromoting ? 'Promover' : 'Degradar'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    bool success;
    if (isPromoting) {
      success = await authController.promoteUserToAdmin(user.uid);
    } else {
      success = await authController.demoteAdminToUser(user.uid);
    }

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Usuario ${isPromoting ? 'promovido' : 'degradado'} exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
        await _loadUsers(); // Recargar la lista y aplicar filtro
        _filterUsers(); // Aplicar filtro actual
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authController.errorMessage ?? 'Error modificando usuario'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Gestión de Usuarios'),
            if (_users.isNotEmpty)
              Text(
                '${_filteredUsers.length} de ${_users.length} usuarios • ${_getSortingDescription()}',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
              ),
          ],
        ),
        actions: [
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
                    const Text('Por fecha registro'),
                  ],
                ),
              ),
            ],
          ),
          // Botón de estadísticas
          if (_users.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.analytics),
              tooltip: 'Estadísticas de usuarios',
              onPressed: _showStatsDialog,
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Recargar usuarios',
            onPressed: _loadUsers,
          ),
        ],
      ),
      body: Column(
        children: [
          // Campo de búsqueda
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar por nombre, email o apartamento...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: _clearSearch,
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey.shade100,
              ),
            ),
          ),
          
          // Lista de usuarios
          Expanded(
            child: _buildUsersList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showInfoDialog,
        tooltip: 'Información sobre gestión de usuarios',
        child: const Icon(Icons.info_outline),
      ),
    );
  }

  Widget _buildUsersList() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_users.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No se encontraron usuarios',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'Los usuarios aparecerán aquí cuando se registren',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    if (_filteredUsers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off, size: 64, color: Colors.grey),
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
        leading: CircleAvatar(
          backgroundColor: user.isAdmin 
              ? Colors.purple.shade100 
              : Colors.blue.shade100,
          child: Icon(
            user.isAdmin ? Icons.admin_panel_settings : Icons.person,
            color: user.isAdmin 
                ? Colors.purple.shade600 
                : Colors.blue.shade600,
          ),
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
                    color: user.isAdmin 
                        ? Colors.purple.shade50 
                        : Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    user.isAdmin ? '👑 Admin' : '👤 Usuario',
                    style: TextStyle(
                      fontSize: 12,
                      color: user.isAdmin 
                          ? Colors.purple.shade600 
                          : Colors.blue.shade600,
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
                ],
              ),
        isThreeLine: true,
      ),
    );
  }

  void _showStatsDialog() {
    final totalUsers = _users.length;
    final adminUsers = _users.where((u) => u.isAdmin).length;
    final regularUsers = totalUsers - adminUsers;
    final usersWithPhone = _users.where((u) => u.phone != null && u.phone!.isNotEmpty).length;
    final usersWithApartment = _users.where((u) => u.apartment != null && u.apartment!.isNotEmpty).length;
    final activeUsers = _users.where((u) => u.isActive).length;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.analytics, color: Colors.blue),
            SizedBox(width: 8),
            Text('Estadísticas de Usuarios'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatRow('👥 Total de usuarios', '$totalUsers'),
            const Divider(),
            _buildStatRow('👑 Administradores', '$adminUsers'),
            _buildStatRow('👤 Usuarios regulares', '$regularUsers'),
            const Divider(),
            _buildStatRow('✅ Usuarios activos', '$activeUsers'),
            _buildStatRow('📱 Con teléfono', '$usersWithPhone'),
            _buildStatRow('🏠 Con apartamento/casa', '$usersWithApartment'),
            const SizedBox(height: 16),
            if (_searchController.text.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Filtro actual:',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '"${_searchController.text}"',
                      style: const TextStyle(fontStyle: FontStyle.italic),
                    ),
                    const SizedBox(height: 4),
                    Text('Mostrando ${_filteredUsers.length} de $totalUsers usuarios'),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Información'),
        content: const Text(
          'Los usuarios pueden registrarse usando el código de comunidad: ${CommunityConstants.communityCode}\n\n'
          'Utiliza el buscador para encontrar usuarios específicos.\n\n'
          'Desde aquí puedes promover usuarios a administradores o degradar administradores a usuarios normales.',
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
