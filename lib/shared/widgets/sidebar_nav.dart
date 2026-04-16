import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_colors.dart';
import '../../core/l10n/app_localizations.dart';

class SidebarNav extends StatefulWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  const SidebarNav({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  @override
  State<SidebarNav> createState() => _SidebarNavState();
}

class _SidebarNavState extends State<SidebarNav> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    final items = [
      _NavItem(Icons.home_rounded, l10n.get('home')),
      _NavItem(Icons.download_rounded, l10n.get('downloads')),
      _NavItem(Icons.history_rounded, l10n.get('history')),
      _NavItem(Icons.settings_rounded, l10n.get('settings')),
    ];

    return MouseRegion(
      onEnter: (_) => setState(() => _expanded = true),
      onExit: (_) => setState(() => _expanded = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        width: _expanded ? 180 : 72,
        decoration: BoxDecoration(
          color: AppColors.sidebarBg,
          border: Border(
            right: BorderSide(color: AppColors.border, width: 0.5),
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: 16),
            ...List.generate(items.length, (index) {
              final item = items[index];
              final isSelected = widget.selectedIndex == index;

              return Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => widget.onDestinationSelected(index),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: isSelected
                            ? AppColors.primary.withValues(alpha: 0.15)
                            : Colors.transparent,
                        border: isSelected
                            ? Border.all(
                                color:
                                    AppColors.primary.withValues(alpha: 0.3))
                            : null,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            item.icon,
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.textMuted,
                            size: 22,
                          ),
                          if (_expanded) ...[
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                item.label,
                                style: TextStyle(
                                  color: isSelected
                                      ? AppColors.primary
                                      : AppColors.textSecondary,
                                  fontSize: 14,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
            const Spacer(),
            // Version badge
            if (_expanded)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'v1.0.0',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11,
                  ),
                ),
              )
                  .animate()
                  .fadeIn(duration: 200.ms),
          ],
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;

  const _NavItem(this.icon, this.label);
}
