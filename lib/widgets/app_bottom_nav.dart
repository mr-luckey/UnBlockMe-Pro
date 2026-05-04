import 'package:blocked/routing/routing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

enum AppBottomTab { home, levels, editor, settings }

class AppBottomNav extends StatelessWidget {
  const AppBottomNav({Key? key, required this.current}) : super(key: key);

  final AppBottomTab current;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withOpacity(0.96),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            children: [
              _item(
                context,
                tab: AppBottomTab.home,
                icon: Icons.home_rounded,
                label: 'Home',
                onTap: () => context.read<NavigatorCubit>().navigateToHome(),
              ),
              _item(
                context,
                tab: AppBottomTab.levels,
                icon: Icons.bar_chart_rounded,
                label: 'Levels',
                onTap: () =>
                    context.read<NavigatorCubit>().navigateToChapterSelection(),
              ),
              _item(
                context,
                tab: AppBottomTab.editor,
                icon: Icons.edit_rounded,
                label: 'Editor',
                onTap: () => context.read<NavigatorCubit>().navigateToEditor(),
              ),
              _item(
                context,
                tab: AppBottomTab.settings,
                icon: Icons.settings_rounded,
                label: 'Settings',
                onTap: () => context.read<NavigatorCubit>().navigateToSettings(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _item(
    BuildContext context, {
    required AppBottomTab tab,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final active = tab == current;
    final color = active
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.onSurfaceVariant;
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color),
              const SizedBox(height: 2),
              Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color)),
            ],
          ),
        ),
      ),
    );
  }
}
