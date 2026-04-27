import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../theme.dart';
import '../../providers/providers.dart';
import '../../widgets/widgets.dart';

class ShellScreen extends ConsumerWidget {
  final Widget child;

  const ShellScreen({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final size = MediaQuery.of(context).size;
    final isWide = size.width > 800;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: isWide
          ? Row(children: [
              _Sidebar(),
              Expanded(child: child),
            ])
          : Column(children: [
              Expanded(child: child),
              _BottomNav(),
            ]),
    );
  }
}

class _Sidebar extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).matchedLocation;
    final user = ref.watch(authStateProvider).value;

    return Container(
      width: 240,
      color: AppColors.surface,
      child: Column(
        children: [
          const SizedBox(height: 32),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: CineMatchLogo(fontSize: 22),
          ),
          const SizedBox(height: 40),
          _NavItem(
            icon: Icons.home_rounded,
            label: 'Home',
            active: location == '/',
            onTap: () => context.go('/'),
          ),
          _NavItem(
            icon: Icons.search_rounded,
            label: 'Discover',
            active: location.startsWith('/search'),
            onTap: () => context.go('/search'),
          ),
          _NavItem(
            icon: Icons.history_rounded,
            label: 'History',
            active: location == '/history',
            onTap: () => context.go('/history'),
          ),
          _NavItem(
            icon: Icons.person_rounded,
            label: 'Profile',
            active: location == '/profile',
            onTap: () => context.go('/profile'),
          ),
          const Spacer(),
          const Divider(color: AppColors.border, indent: 20, endIndent: 20),
          if (user != null)
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: AppColors.primary,
                    backgroundImage: user.photoURL != null
                        ? NetworkImage(user.photoURL!)
                        : null,
                    child: user.photoURL == null
                        ? Text(
                            (user.displayName ?? user.email)![0].toUpperCase(),
                            style: const TextStyle(
                                color: Colors.white, fontSize: 14),
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.displayName ?? 'User',
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          user.email ?? '',
                          style: const TextStyle(
                              fontSize: 11, color: AppColors.textMuted),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _NavItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: AppConstants.animationFast,
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: widget.active
                ? AppColors.primaryGlow
                : _hovered
                    ? AppColors.surfaceVariant
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: widget.active
                  ? AppColors.primary.withOpacity(0.3)
                  : Colors.transparent,
              width: 0.5,
            ),
          ),
          child: Row(
            children: [
              Icon(
                widget.icon,
                color: widget.active ? AppColors.primary : AppColors.textMuted,
                size: 20,
              ),
              const SizedBox(width: 12),
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: widget.active ? FontWeight.w600 : FontWeight.w400,
                  color: widget.active
                      ? AppColors.primary
                      : AppColors.textSecondary,
                ),
              ),
              if (widget.active) ...[
                const Spacer(),
                Container(
                  width: 4,
                  height: 4,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
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
}

class _BottomNav extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).matchedLocation;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border, width: 0.5)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _BottomNavItem(
              icon: Icons.home_rounded,
              label: 'Home',
              active: location == '/',
              onTap: () => context.go('/'),
            ),
            _BottomNavItem(
              icon: Icons.search_rounded,
              label: 'Discover',
              active: location.startsWith('/search'),
              onTap: () => context.go('/search'),
            ),
            _BottomNavItem(
              icon: Icons.history_rounded,
              label: 'History',
              active: location == '/history',
              onTap: () => context.go('/history'),
            ),
            _BottomNavItem(
              icon: Icons.person_rounded,
              label: 'Profile',
              active: location == '/profile',
              onTap: () => context.go('/profile'),
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _BottomNavItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                color: active ? AppColors.primary : AppColors.textMuted,
                size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                color: active ? AppColors.primary : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
