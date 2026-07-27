import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// App-wide Android/system back handling with wood-themed exit confirm.
///
/// - If the navigator can pop (level, dialog, etc.) → pop that route.
/// - If already at the root shell → show themed "Exit game?" dialog.
class AppExitScope extends StatelessWidget {
  const AppExitScope({
    Key? key,
    required this.navigatorKey,
    required this.child,
  }) : super(key: key);

  final GlobalKey<NavigatorState> navigatorKey;
  final Widget child;

  Future<void> _onBack() async {
    final nav = navigatorKey.currentState;
    if (nav != null && nav.canPop()) {
      nav.pop();
      return;
    }

    final ctx = navigatorKey.currentContext ?? nav?.context;
    if (ctx == null) {
      SystemNavigator.pop();
      return;
    }

    final shouldExit = await showDialog<bool>(
      context: ctx,
      barrierColor: Colors.black54,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF6B4226), Color(0xFF2A1808)],
              ),
              border: Border.all(color: const Color(0xFFC4A574), width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.45),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.logout_rounded,
                  color: Color(0xFFFFB04A),
                  size: 42,
                ),
                const SizedBox(height: 10),
                Text(
                  'EXIT GAME?',
                  style: GoogleFonts.nunito(
                    color: const Color(0xFFFFF1D6),
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your progress is saved. Leave the forest for now?',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.nunito(
                    color: Colors.white70,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: _ExitDialogAction(
                        label: 'STAY',
                        colors: const [Color(0xFF8B5A2B), Color(0xFF5C3A1E)],
                        onTap: () => Navigator.pop(dialogContext, false),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _ExitDialogAction(
                        label: 'EXIT',
                        colors: const [Color(0xFFFF6B5A), Color(0xFFC62828)],
                        onTap: () => Navigator.pop(dialogContext, true),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    if (shouldExit == true) {
      SystemNavigator.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _onBack();
      },
      child: child,
    );
  }
}

class _ExitDialogAction extends StatelessWidget {
  const _ExitDialogAction({
    required this.label,
    required this.colors,
    required this.onTap,
  });

  final String label;
  final List<Color> colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          height: 46,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: colors,
            ),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.35),
              width: 1.5,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.nunito(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 14,
                letterSpacing: 0.4,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
