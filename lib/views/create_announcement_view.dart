import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/announcement_controller.dart';
import '../controllers/auth_controller.dart';
import '../models/announcement_model.dart';

class CreateAnnouncementView extends StatefulWidget {
  const CreateAnnouncementView({super.key});

  @override
  State<CreateAnnouncementView> createState() => _CreateAnnouncementViewState();
}

class _CreateAnnouncementViewState extends State<CreateAnnouncementView> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _phoneController = TextEditingController();
  
  AnnouncementType _selectedType = AnnouncementType.general;
  bool _isUrgent = false;
  bool _includeContact = false;
  bool _isSubmitting = false;
  int _selectedDuration = 30;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear Anuncio'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Consumer2<AnnouncementController, AuthController>(
        builder: (context, announcementController, authController, child) {
          final user = authController.currentUser;
          if (user == null) {
            return const Center(child: Text('Usuario no autenticado'));
          }

          return Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Información de moderación
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue.shade600),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Revisión Requerida',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue.shade700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Su anuncio será revisado antes de ser publicado.',
                                  style: TextStyle(fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Tipo de anuncio
                  DropdownButtonFormField<AnnouncementType>(
                    value: _selectedType,
                    decoration: const InputDecoration(
                      labelText: 'Tipo de Anuncio',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.category),
                    ),
                    items: AnnouncementType.values.map((type) {
                      return DropdownMenuItem(
                        value: type,
                        child: Text(type.displayName),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedType = value!;
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  // Título
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Título *',
                      hintText: 'Ej: Se vende bicicleta nueva',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.title),
                    ),
                    maxLength: 100,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'El título es requerido';
                      }
                      if (value.length < 5) {
                        return 'El título debe tener al menos 5 caracteres';
                      }
                      return null;
                    },
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 16),

                  // Descripción
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Descripción *',
                      hintText: 'Describa su anuncio detalladamente...',
                      border: OutlineInputBorder(),
                      alignLabelWithHint: true,
                    ),
                    maxLines: 4,
                    maxLength: 1000,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'La descripción es requerida';
                      }
                      if (value.length < 20) {
                        return 'La descripción debe tener al menos 20 caracteres';
                      }
                      return null;
                    },
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 16),

                  // Precio (condicional)
                  if (_selectedType == AnnouncementType.sale || 
                      _selectedType == AnnouncementType.service) ...[
                    TextFormField(
                      controller: _priceController,
                      decoration: const InputDecoration(
                        labelText: 'Precio (opcional)',
                        hintText: '0.00',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.attach_money),
                        prefixText: '\$ ',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          final price = double.tryParse(value);
                          if (price == null || price < 0) {
                            return 'Ingrese un precio válido';
                          }
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Contacto adicional
                  CheckboxListTile(
                    title: const Text('Incluir información de contacto adicional'),
                    value: _includeContact,
                    onChanged: (value) {
                      setState(() {
                        _includeContact = value ?? false;
                      });
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                  ),

                  if (_includeContact) ...[
                    TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(
                        labelText: 'Teléfono de contacto',
                        hintText: 'Ej: 5555555555',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.phone),
                      ),
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (_includeContact && (value == null || value.trim().isEmpty)) {
                          return 'El teléfono es requerido si incluye contacto';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Marcar como urgente
                  CheckboxListTile(
                    title: const Text('Marcar como urgente'),
                    value: _isUrgent,
                    onChanged: (value) {
                      setState(() {
                        _isUrgent = value ?? false;
                      });
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                  const SizedBox(height: 16),

                  // Duración
                  DropdownButtonFormField<int>(
                    value: _selectedDuration,
                    decoration: const InputDecoration(
                      labelText: 'Duración del anuncio',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.schedule),
                    ),
                    items: const [
                      DropdownMenuItem(value: 7, child: Text('7 días')),
                      DropdownMenuItem(value: 15, child: Text('15 días')),
                      DropdownMenuItem(value: 30, child: Text('30 días')),
                      DropdownMenuItem(value: 60, child: Text('60 días')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedDuration = value!;
                      });
                    },
                  ),
                  const SizedBox(height: 32),

                  // Botón de envío
                  ElevatedButton(
                    onPressed: _isSubmitting ? null : () => _submitAnnouncement(
                      announcementController,
                      user,
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isSubmitting
                        ? const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                              SizedBox(width: 12),
                              Text('Enviando...'),
                            ],
                          )
                        : const Text(
                            'Enviar para Revisión',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                  ),
                  const SizedBox(height: 16),

                  // Términos
                  Text(
                    'Al enviar este anuncio acepta que será revisado por un administrador. '
                    'Los anuncios pueden ser rechazados si no cumplen con las normas de la comunidad.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _submitAnnouncement(
    AnnouncementController controller,
    dynamic user,
  ) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final price = _priceController.text.isNotEmpty 
          ? double.tryParse(_priceController.text)
          : null;

      await controller.createAnnouncement(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        type: _selectedType,
        authorId: user.uid,
        authorName: user.displayName,
        authorPhone: _includeContact ? _phoneController.text.trim() : null,
        authorEmail: _includeContact ? user.email : null,
        authorApartment: user.apartment,
        price: price,
        isUrgent: _isUrgent,
        daysValid: _selectedDuration,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Anuncio enviado para revisión'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }
}
