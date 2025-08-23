import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../controllers/event_controller.dart';
import '../models/event_model.dart';

class CreateEditEventView extends StatefulWidget {
  final Event? event;

  const CreateEditEventView({super.key, this.event});

  @override
  State<CreateEditEventView> createState() => _CreateEditEventViewState();
}

class _CreateEditEventViewState extends State<CreateEditEventView> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _locationController;
  late TextEditingController _organizerController;
  late TextEditingController _organizerPhoneController;
  late TextEditingController _organizerEmailController;
  late TextEditingController _estimatedCostController;
  late TextEditingController _maxAttendeesController;
  late TextEditingController _requirementsController;
  
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  String _selectedCategory = 'Fiesta y Celebración';
  String _selectedTargetAudience = 'Toda la familia';
  bool _requiresRegistration = true;
  List<String> _selectedTags = [];

  // Categorías de eventos
  final List<String> _eventCategories = [
    'Fiesta y Celebración',
    'Reunión Vecinal',
    'Actividad Deportiva',
    'Evento Cultural',
    'Evento Educativo',
    'Evento Solidario',
    'Mejoras del Barrio',
    'Tema de Seguridad',
    'Jornada de Limpieza',
    'Otros',
  ];

  // Público objetivo
  final List<String> _targetAudiences = [
    'Toda la familia',
    'Solo adultos',
    'Niños y familias',
    'Jóvenes',
    'Adultos mayores',
    'Solo mujeres',
    'Solo hombres',
  ];

  // Tags disponibles
  final List<String> _availableTags = [
    'Gratis', 'Con costo', 'Al aire libre', 'Interior', 
    'Comida incluida', 'Música en vivo', 'DJ', 'Rifas',
    'Juegos', 'Actividades para niños', 'Bebidas incluidas',
    'Colaboración requerida', 'Materiales incluidos',
  ];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.event?.title ?? '');
    _descriptionController = TextEditingController(text: widget.event?.description ?? '');
    _locationController = TextEditingController(text: widget.event?.location ?? '');
    _organizerController = TextEditingController(text: widget.event?.organizer ?? '');
    _organizerPhoneController = TextEditingController(text: widget.event?.organizerPhone ?? '');
    _organizerEmailController = TextEditingController(text: widget.event?.organizerEmail ?? '');
    _estimatedCostController = TextEditingController(
      text: widget.event?.estimatedCost != null && widget.event!.estimatedCost > 0 
          ? widget.event!.estimatedCost.toString() 
          : ''
    );
    _maxAttendeesController = TextEditingController(
      text: widget.event?.maxAttendees != null && widget.event!.maxAttendees > 0
          ? widget.event!.maxAttendees.toString()
          : ''
    );
    _requirementsController = TextEditingController(text: widget.event?.requirements ?? '');
    
    _selectedDate = widget.event?.date ?? DateTime.now();
    _selectedTime = TimeOfDay.fromDateTime(widget.event?.date ?? DateTime.now());
    _selectedCategory = widget.event?.category ?? 'Fiesta y Celebración';
    _selectedTargetAudience = widget.event?.targetAudience ?? 'Toda la familia';
    _requiresRegistration = widget.event?.requiresRegistration ?? true;
    _selectedTags = List.from(widget.event?.tags ?? []);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _organizerController.dispose();
    _organizerPhoneController.dispose();
    _organizerEmailController.dispose();
    _estimatedCostController.dispose();
    _maxAttendeesController.dispose();
    _requirementsController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      setState(() {
        _selectedDate = date;
      });
    }
  }

  Future<void> _selectTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (time != null) {
      setState(() {
        _selectedTime = time;
      });
    }
  }

  void _saveEvent() {
    if (_formKey.currentState!.validate()) {
      final eventDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      final event = Event(
        id: widget.event?.id ?? '',
        title: _titleController.text,
        description: _descriptionController.text,
        location: _locationController.text,
        date: eventDateTime,
        organizer: _organizerController.text,
        organizerPhone: _organizerPhoneController.text,
        organizerEmail: _organizerEmailController.text,
        category: _selectedCategory,
        estimatedCost: _estimatedCostController.text.isNotEmpty ? double.tryParse(_estimatedCostController.text) ?? 0.0 : 0.0,
        maxAttendees: _maxAttendeesController.text.isNotEmpty ? int.tryParse(_maxAttendeesController.text) ?? 0 : 0,
        requiresRegistration: _requiresRegistration,
        requirements: _requirementsController.text,
        targetAudience: _selectedTargetAudience,
        tags: _selectedTags,
      );

      if (widget.event == null) {
        Provider.of<EventController>(context, listen: false).createEvent(event);
      } else {
        Provider.of<EventController>(context, listen: false).updateEvent(event);
      }

      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.event == null ? 'Crear Evento' : 'Editar Evento',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.green.shade50,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // Sección de información básica
            _buildSectionTitle('📋 Información Básica'),
            const SizedBox(height: 12),
            
            _buildTextField(
              controller: _titleController,
              label: 'Título del Evento',
              icon: Icons.event,
              validator: (value) => value?.isEmpty ?? true ? 'El título es requerido' : null,
            ),
            const SizedBox(height: 16),
            
            _buildTextField(
              controller: _descriptionController,
              label: 'Descripción',
              icon: Icons.description,
              maxLines: 3,
              validator: (value) => value?.isEmpty ?? true ? 'La descripción es requerida' : null,
            ),
            const SizedBox(height: 16),

            // Categoría
            _buildDropdownField(
              value: _selectedCategory,
              label: 'Categoría del Evento',
              icon: Icons.category,
              items: _eventCategories,
              onChanged: (value) => setState(() => _selectedCategory = value!),
            ),
            const SizedBox(height: 24),

            // Sección de fecha y hora
            _buildSectionTitle('📅 Fecha y Hora'),
            const SizedBox(height: 12),
            
            Row(
              children: [
                Expanded(
                  child: _buildDateTimeSelector(
                    title: 'Fecha',
                    subtitle: DateFormat('dd/MM/yyyy', 'es').format(_selectedDate),
                    icon: Icons.calendar_today,
                    onTap: _selectDate,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildDateTimeSelector(
                    title: 'Hora',
                    subtitle: _selectedTime.format(context),
                    icon: Icons.access_time,
                    onTap: _selectTime,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Sección de ubicación
            _buildSectionTitle('📍 Ubicación y Logística'),
            const SizedBox(height: 12),
            
            _buildTextField(
              controller: _locationController,
              label: 'Ubicación',
              icon: Icons.location_on,
              validator: (value) => value?.isEmpty ?? true ? 'La ubicación es requerida' : null,
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _maxAttendeesController,
                    label: 'Máx. Asistentes',
                    icon: Icons.people,
                    keyboardType: TextInputType.number,
                    hint: 'Opcional (0 = sin límite)',
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTextField(
                    controller: _estimatedCostController,
                    label: 'Costo Estimado',
                    icon: Icons.attach_money,
                    keyboardType: TextInputType.number,
                    hint: 'Opcional',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Sección del organizador
            _buildSectionTitle('👤 Información del Organizador'),
            const SizedBox(height: 12),
            
            _buildTextField(
              controller: _organizerController,
              label: 'Nombre del Organizador',
              icon: Icons.person,
              validator: (value) => value?.isEmpty ?? true ? 'El organizador es requerido' : null,
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _organizerPhoneController,
                    label: 'Teléfono',
                    icon: Icons.phone,
                    keyboardType: TextInputType.phone,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTextField(
                    controller: _organizerEmailController,
                    label: 'Email',
                    icon: Icons.email,
                    keyboardType: TextInputType.emailAddress,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Sección de público objetivo
            _buildSectionTitle('🎯 Público Objetivo'),
            const SizedBox(height: 12),
            
            _buildDropdownField(
              value: _selectedTargetAudience,
              label: 'Dirigido a',
              icon: Icons.groups,
              items: _targetAudiences,
              onChanged: (value) => setState(() => _selectedTargetAudience = value!),
            ),
            const SizedBox(height: 16),

            // Switch para registro requerido
            Card(
              child: SwitchListTile(
                title: const Text('Requiere Registro'),
                subtitle: Text(_requiresRegistration 
                    ? 'Los vecinos deben registrarse para asistir'
                    : 'Evento abierto sin registro previo'),
                value: _requiresRegistration,
                onChanged: (value) => setState(() => _requiresRegistration = value),
                activeColor: Colors.green,
              ),
            ),
            const SizedBox(height: 16),

            _buildTextField(
              controller: _requirementsController,
              label: 'Requisitos o Instrucciones',
              icon: Icons.info_outline,
              maxLines: 2,
              hint: 'Ej: Traer silla, plato, bebida...',
            ),
            const SizedBox(height: 24),

            // Sección de etiquetas
            _buildSectionTitle('🏷️ Etiquetas'),
            const SizedBox(height: 12),
            
            _buildTagsSelector(),
            const SizedBox(height: 32),

            // Botón de guardar
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _saveEvent,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade400,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                icon: const Icon(Icons.save),
                label: Text(
                  widget.event == null ? 'Crear Evento' : 'Guardar Cambios',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // Métodos helper para construir los widgets del formulario

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.green,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: Colors.green.shade400),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.green.shade400, width: 2),
        ),
        filled: true,
        fillColor: Colors.green.shade50,
      ),
    );
  }

  Widget _buildDropdownField({
    required String? value,
    required String label,
    required IconData icon,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      onChanged: onChanged,
      items: items.map((item) {
        return DropdownMenuItem(
          value: item,
          child: Text(item),
        );
      }).toList(),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.green.shade400),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.green.shade400, width: 2),
        ),
        filled: true,
        fillColor: Colors.green.shade50,
      ),
    );
  }

  Widget _buildDateTimeSelector({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: Colors.green.shade400),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: Colors.green.shade600,
            fontWeight: FontWeight.bold,
          ),
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildTagsSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Selecciona etiquetas relevantes:',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _availableTags.map((tag) {
            final isSelected = _selectedTags.contains(tag);
            return FilterChip(
              label: Text(tag),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedTags.add(tag);
                  } else {
                    _selectedTags.remove(tag);
                  }
                });
              },
              selectedColor: Colors.green.shade200,
              checkmarkColor: Colors.green.shade700,
              backgroundColor: Colors.grey.shade200,
            );
          }).toList(),
        ),
        if (_selectedTags.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              'Selecciona al menos una etiqueta para ayudar a categorizar el evento',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }
}
