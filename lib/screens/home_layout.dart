import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import 'dashboard/dashboard_screen.dart';
import 'agenda/agenda_screen.dart';
import 'agenda/events_screen.dart';
import 'habits/habits_screen.dart';
import 'calendar/calendar_screen.dart';
import 'settings/settings_screen.dart';

class HomeLayout extends StatefulWidget {
  const HomeLayout({super.key});

  @override
  State<HomeLayout> createState() => _HomeLayoutState();
}

class _HomeLayoutState extends State<HomeLayout> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const DashboardScreen(),
    const AgendaScreen(),
    const EventsScreen(),
    const HabitsScreen(),
    const CalendarScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final theme = Theme.of(context);
    final isWide = MediaQuery.of(context).size.width >= 600;

    final destinations = [
      const NavigationDestination(
        icon: Icon(Icons.dashboard_outlined),
        selectedIcon: Icon(Icons.dashboard),
        label: 'Panel',
      ),
      const NavigationDestination(
        icon: Icon(Icons.check_box_outlined),
        selectedIcon: Icon(Icons.check_box),
        label: 'Tareas',
      ),
      const NavigationDestination(
        icon: Icon(Icons.event_outlined),
        selectedIcon: Icon(Icons.event),
        label: 'Eventos',
      ),
      const NavigationDestination(
        icon: Icon(Icons.repeat_rounded),
        selectedIcon: Icon(Icons.repeat),
        label: 'Hábitos',
      ),
      const NavigationDestination(
        icon: Icon(Icons.calendar_month_outlined),
        selectedIcon: Icon(Icons.calendar_month),
        label: 'Calendario',
      ),
      const NavigationDestination(
        icon: Icon(Icons.settings_outlined),
        selectedIcon: Icon(Icons.settings),
        label: 'Ajustes',
      ),
    ];

    final railDestinations = [
      const NavigationRailDestination(
        icon: Icon(Icons.dashboard_outlined),
        selectedIcon: Icon(Icons.dashboard),
        label: Text('Panel'),
      ),
      const NavigationRailDestination(
        icon: Icon(Icons.check_box_outlined),
        selectedIcon: Icon(Icons.check_box),
        label: Text('Tareas'),
      ),
      const NavigationRailDestination(
        icon: Icon(Icons.event_outlined),
        selectedIcon: Icon(Icons.event),
        label: Text('Eventos'),
      ),
      const NavigationRailDestination(
        icon: Icon(Icons.repeat_rounded),
        selectedIcon: Icon(Icons.repeat),
        label: Text('Hábitos'),
      ),
      const NavigationRailDestination(
        icon: Icon(Icons.calendar_month_outlined),
        selectedIcon: Icon(Icons.calendar_month),
        label: Text('Calendario'),
      ),
      const NavigationRailDestination(
        icon: Icon(Icons.settings_outlined),
        selectedIcon: Icon(Icons.settings),
        label: Text('Ajustes'),
      ),
    ];

    final Widget body = AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: _screens[_selectedIndex],
    );

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.today, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              'Mi Agenda',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
        actions: [
          // Theme Toggle
          IconButton(
            icon: Icon(appState.isDarkMode ? Icons.light_mode : Icons.dark_mode),
            tooltip: appState.isDarkMode ? 'Cambiar a modo claro' : 'Cambiar a modo oscuro',
            onPressed: appState.toggleTheme,
          ),
          // User profile / email label (hidden on very small screens)
          if (MediaQuery.of(context).size.width >= 400)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Chip(
                avatar: CircleAvatar(
                  backgroundColor: theme.colorScheme.primary,
                  child: Text(
                    appState.currentUser?.email[0].toUpperCase() ?? 'U',
                    style: TextStyle(color: theme.colorScheme.onPrimary, fontSize: 11),
                  ),
                ),
                label: Text(
                  appState.currentUser?.email ?? '',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ),
        ],
      ),
      body: isWide
          ? Row(
              children: [
                NavigationRail(
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: (idx) {
                    setState(() {
                      _selectedIndex = idx;
                    });
                  },
                  labelType: NavigationRailLabelType.all,
                  destinations: railDestinations,
                ),
                const VerticalDivider(thickness: 1, width: 1),
                Expanded(
                  child: body,
                ),
              ],
            )
          : body,
      bottomNavigationBar: isWide
          ? null
          : NavigationBar(
              selectedIndex: _selectedIndex,
              onDestinationSelected: (idx) {
                setState(() {
                  _selectedIndex = idx;
                });
              },
              destinations: destinations,
            ),
    );
  }
}
