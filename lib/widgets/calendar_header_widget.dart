import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/event_model.dart';

class CalendarHeaderWidget extends StatefulWidget {
  final List<Event> events;
  final Function(DateTime) onDateSelected;
  final DateTime selectedDate;

  const CalendarHeaderWidget({
    super.key,
    required this.events,
    required this.onDateSelected,
    required this.selectedDate,
  });

  @override
  State<CalendarHeaderWidget> createState() => _CalendarHeaderWidgetState();
}

class _CalendarHeaderWidgetState extends State<CalendarHeaderWidget> {
  late ScrollController _scrollController;
  late DateTime _currentWeekStart;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _currentWeekStart = _getWeekStart(DateTime.now());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  DateTime _getWeekStart(DateTime date) {
    return date.subtract(Duration(days: date.weekday - 1));
  }

  int _getEventsForDate(DateTime date) {
    return widget.events.where((event) {
      return event.date.year == date.year &&
          event.date.month == date.month &&
          event.date.day == date.day;
    }).length;
  }

  Widget _buildDateCard(DateTime date) {
    final isSelected = widget.selectedDate.year == date.year &&
        widget.selectedDate.month == date.month &&
        widget.selectedDate.day == date.day;
    
    final isToday = DateTime.now().year == date.year &&
        DateTime.now().month == date.month &&
        DateTime.now().day == date.day;
    
    final eventsCount = _getEventsForDate(date);
    final isPast = date.isBefore(DateTime.now().subtract(const Duration(days: 1)));

    return GestureDetector(
      onTap: () => widget.onDateSelected(date),
      child: Container(
        width: 60,
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).primaryColor
              : isToday
                  ? Theme.of(context).primaryColor.withOpacity(0.1)
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: isToday && !isSelected
              ? Border.all(color: Theme.of(context).primaryColor, width: 2)
              : null,
        ),
        child: IntrinsicHeight(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                DateFormat('E', 'es').format(date).substring(0, 3),
                style: TextStyle(
                  color: isSelected
                      ? Colors.white
                      : isPast
                          ? Colors.grey
                          : Theme.of(context).textTheme.bodySmall?.color,
                  fontSize: 9,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                date.day.toString(),
                style: TextStyle(
                  color: isSelected
                      ? Colors.white
                      : isPast
                          ? Colors.grey
                          : Theme.of(context).textTheme.titleLarge?.color,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (eventsCount > 0) ...[
                const SizedBox(height: 2),
                Container(
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.white
                        : Theme.of(context).primaryColor,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Column(
        children: [
          // Encabezado del mes
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat('MMMM yyyy', 'es').format(widget.selectedDate),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _currentWeekStart = _currentWeekStart.subtract(const Duration(days: 7));
                        });
                      },
                      icon: const Icon(Icons.chevron_left),
                    ),
                    IconButton(
                      onPressed: () {
                        final today = DateTime.now();
                        widget.onDateSelected(today);
                        setState(() {
                          _currentWeekStart = _getWeekStart(today);
                        });
                      },
                      icon: const Icon(Icons.today),
                    ),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _currentWeekStart = _currentWeekStart.add(const Duration(days: 7));
                        });
                      },
                      icon: const Icon(Icons.chevron_right),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Calendario horizontal
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: 14, // Mostrar 2 semanas
              itemBuilder: (context, index) {
                final date = _currentWeekStart.add(Duration(days: index));
                return _buildDateCard(date);
              },
            ),
          ),
        ],
      ),
    );
  }
}
