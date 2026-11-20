import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class NavTab {
  const NavTab({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
}

const cinevaTabs = <NavTab>[
  NavTab(
    icon: Icons.home_outlined,
    activeIcon: Icons.home_rounded,
    label: 'Home',
  ),
  NavTab(
    icon: Icons.explore_outlined,
    activeIcon: Icons.explore_rounded,
    label: 'Explore',
  ),
  NavTab(
    icon: Icons.search_rounded,
    activeIcon: Icons.search_rounded,
    label: 'Search',
  ),
  NavTab(
    icon: Icons.auto_awesome_outlined,
    activeIcon: Icons.auto_awesome_rounded,
    label: 'AI',
  ),
  NavTab(
    icon: Icons.bookmark_border_rounded,
    activeIcon: Icons.bookmark_rounded,
    label: 'My List',
  ),
];

class CinevaNavBar extends StatefulWidget {
  const CinevaNavBar({
    super.key,
    required this.currentIndex,
    required this.onChanged,
  });

  final int currentIndex;
  final ValueChanged<int> onChanged;

  @override
  State<CinevaNavBar> createState() => _CinevaNavBarState();
}

class _CinevaNavBarState extends State<CinevaNavBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
    value: 1,
  );

  late final Animation<double> _popAnim = CurvedAnimation(
    parent: _pop,
    curve: Curves.easeOutBack,
  );

  int? _pressedIndex;

  void _select(int i) {
    if (i == widget.currentIndex) {
      _pop.forward(from: 0);
      return;
    }
    widget.onChanged(i);
  }

  @override
  void dispose() {
    _pop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.sm + 2,
      ),
      child: Container(
        height: 66,
        decoration: BoxDecoration(
          color: AppColors.surface.withValues(alpha: 0.97),
          borderRadius: BorderRadius.circular(AppRadius.xxl),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.55),
              blurRadius: 28,
              offset: const Offset(0, 14),
            ),
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.06),
              blurRadius: 24,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: AnimatedBuilder(
          animation: _popAnim,
          builder: (context, _) {
            return Row(
              children: List.generate(cinevaTabs.length, (i) {
                final active = i == widget.currentIndex;
                return Expanded(
                  child: _NavItem(
                    tab: cinevaTabs[i],
                    active: active,
                    pop: active && !reduceMotion ? _popAnim.value : 1,
                    pressed: _pressedIndex == i,
                    onPress: (pressed) =>
                        setState(() => _pressedIndex = pressed ? i : null),
                    onTap: () => _select(i),
                  ),
                );
              }),
            );
          },
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.tab,
    required this.active,
    required this.pop,
    required this.pressed,
    required this.onPress,
    required this.onTap,
  });

  final NavTab tab;
  final bool active;
  final double pop;
  final bool pressed;
  final ValueChanged<bool> onPress;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: active,
      button: true,
      label: tab.label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => onPress(true),
        onTapUp: (_) => onPress(false),
        onTapCancel: () => onPress(false),
        onTap: onTap,
        child: Center(
          child: AnimatedScale(
            scale: pressed ? 0.92 : 1,
            duration: const Duration(milliseconds: 140),
            curve: Curves.easeOutCubic,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 240),
                  curve: Curves.easeOutCubic,
                  width: active ? 42 : 36,
                  height: 30,
                  decoration: BoxDecoration(
                    color: active
                        ? AppColors.primary.withValues(alpha: 0.16)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    border: active
                        ? Border.all(
                            color: AppColors.primary.withValues(alpha: 0.22),
                          )
                        : null,
                  ),
                  alignment: Alignment.center,
                  child: AnimatedScale(
                    scale: active ? 1 + 0.05 * (pop - 1) : 1,
                    duration: const Duration(milliseconds: 240),
                    curve: Curves.easeOut,
                    child: Icon(
                      active ? tab.activeIcon : tab.icon,
                      size: 21,
                      color: active
                          ? AppColors.primarySoft
                          : AppColors.textMuted,
                    ),
                  ),
                ),
                const SizedBox(height: 3),
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOut,
                  style: AppType.caption.copyWith(
                    fontSize: 9.5,
                    letterSpacing: 0.1,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w600,
                    color: active ? AppColors.text : AppColors.textMuted,
                  ),
                  child: Text(tab.label),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
