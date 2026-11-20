import 'package:flutter/material.dart';

class AppSidebar extends StatelessWidget {
  const AppSidebar({
    super.key,
    this.selectedPage = 'dashboard',
  });

  final String selectedPage;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      width: 220,
      color: const Color(0xFF17191D),
      child: Column(
        children: [
          const SizedBox(height: 24),

          const Padding(
            padding:
                EdgeInsets.symmetric(
              horizontal: 20,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.speed,
                  color: Colors.redAccent,
                  size: 32,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Racing Data\nAnalyzer',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          _SidebarItem(
            icon:
                Icons.dashboard_outlined,
            label: 'Dashboard',
            selected:
                selectedPage ==
                    'dashboard',
            onTap: () {
              if (selectedPage !=
                  'dashboard') {
                Navigator.of(context)
                    .pushReplacementNamed(
                  '/',
                );
              }
            },
          ),

          _SidebarItem(
            icon:
                Icons.timer_outlined,
            label: 'Sessions',
            selected:
                selectedPage ==
                    'sessions',
            onTap: () {
              if (selectedPage !=
                  'sessions') {
                Navigator.of(context)
                    .pushReplacementNamed(
                  '/sessions',
                );
              }
            },
          ),

          const _SidebarItem(
            icon:
                Icons.directions_car_outlined,
            label: 'Cars',
          ),

          const _SidebarItem(
            icon:
                Icons.route_outlined,
            label: 'Tracks',
          ),

          const _SidebarItem(
            icon:
                Icons.analytics_outlined,
            label: 'Analysis',
          ),

          const Spacer(),

          _SidebarItem(
            icon:
                Icons.settings_outlined,
            label: 'Settings',
            selected:
                selectedPage ==
                    'settings',
            onTap: () {
              if (selectedPage !=
                  'settings') {
                Navigator.of(context)
                    .pushReplacementNamed(
                  '/settings',
                );
              }
            },
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _SidebarItem
    extends StatelessWidget {
  const _SidebarItem({
    required this.icon,
    required this.label,
    this.selected = false,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 4,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius:
              BorderRadius.circular(8),
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              color: selected
                  ? Colors.redAccent
                      .withValues(
                      alpha: 0.15,
                    )
                  : Colors.transparent,
              borderRadius:
                  BorderRadius.circular(
                8,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 28,
                  decoration:
                      BoxDecoration(
                    color: selected
                        ? Colors.redAccent
                        : Colors
                            .transparent,
                    borderRadius:
                        BorderRadius
                            .circular(2),
                  ),
                ),
                const SizedBox(
                  width: 12,
                ),
                Icon(
                  icon,
                  size: 22,
                  color: selected
                      ? Colors.redAccent
                      : Colors.white60,
                ),
                const SizedBox(
                  width: 14,
                ),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight:
                        selected
                            ? FontWeight
                                .w600
                            : FontWeight
                                .normal,
                    color: selected
                        ? Colors.white
                        : Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}