import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

/// Sidebar width on web desktop.
const double kWebSidebarWidth = 240.0;

/// Breakpoint below which the layout falls back to the mobile style (full-width, bottom nav).
const double kWebBreakpoint = 900.0;

/// Returns true when the layout should use the web desktop shell
/// (running on web AND viewport width >= [kWebBreakpoint]).
bool isWebDesktop(BuildContext context) {
  if (!kIsWeb) return false;
  return MediaQuery.of(context).size.width >= kWebBreakpoint;
}

/// A nav item descriptor consumed by [WebShell].
class WebNavItem {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const WebNavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });
}

/// [WebShell] provides a web-desktop–optimised layout shell.
///
/// On **web desktop** (kIsWeb && width >= 900):
///   - Left sidebar (240px fixed) shows nav items.
///   - Content panel expands to fill the remaining viewport width.
///   - The outer background is slightly tinted for depth.
///
/// On **mobile / narrow web**:
///   - Acts as a transparent pass-through; renders [child] directly.
class WebShell extends StatelessWidget {
  /// The scrollable/page content for the active tab.
  final Widget child;

  /// Navigation items rendered in the sidebar (web desktop only).
  final List<WebNavItem> navItems;

  /// Bottom accessory widget (e.g. note input bar) pinned above the nav.
  /// On web desktop this is pinned at the bottom of the content panel.
  final Widget? bottomAccessory;

  /// Whether to show the bottom note-input bar (web desktop only).
  final bool showBottomAccessory;

  const WebShell({
    super.key,
    required this.child,
    required this.navItems,
    this.bottomAccessory,
    this.showBottomAccessory = false,
  });

  @override
  Widget build(BuildContext context) {
    if (!isWebDesktop(context)) {
      // Mobile / narrow → pass-through, keep existing layout untouched.
      return child;
    }

    final bg = Theme.of(context).scaffoldBackgroundColor;
    final primary = Theme.of(context).primaryColor;

    return Scaffold(
      backgroundColor: bg,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Sidebar ────────────────────────────────────────────────
          SizedBox(
            width: kWebSidebarWidth,
            child: _Sidebar(
              navItems: navItems,
              bg: bg,
              primary: primary,
            ),
          ),

          // Hairline divider
          VerticalDivider(
            width: 1,
            thickness: 1,
            color: primary.withOpacity(0.07),
          ),

          // ── Content panel (fills remaining space) ───────────────────────
          Expanded(
            child: Container(
              color: bg,
              child: Column(
                children: [
                  Expanded(child: child),
                  if (showBottomAccessory && bottomAccessory != null)
                    bottomAccessory!,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Sidebar ──────────────────────────────────────────────────────────────────
class _Sidebar extends StatelessWidget {
  final List<WebNavItem> navItems;
  final Color bg;
  final Color primary;

  const _Sidebar({
    required this.navItems,
    required this.bg,
    required this.primary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: bg,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // App logo / wordmark
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 8, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pace',
                  style: TextStyle(
                    color: primary,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1.0,
                  ),
                ),
                Text(
                  'Danica.sys',
                  style: TextStyle(
                    color: primary.withOpacity(0.5),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),

          // Nav items
          ...navItems.map((item) => _SidebarNavItem(item: item, primary: primary, bg: bg)),
        ],
      ),
    );
  }
}

class _SidebarNavItem extends StatefulWidget {
  final WebNavItem item;
  final Color primary;
  final Color bg;

  const _SidebarNavItem({
    required this.item,
    required this.primary,
    required this.bg,
  });

  @override
  State<_SidebarNavItem> createState() => _SidebarNavItemState();
}

class _SidebarNavItemState extends State<_SidebarNavItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final isActive = widget.item.isActive;
    final primary = widget.primary;
    final bg = widget.bg;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.item.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isActive
                  ? primary
                  : _hovered
                      ? primary.withOpacity(0.07)
                      : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  widget.item.icon,
                  size: 18,
                  color: isActive
                      ? bg
                      : primary.withOpacity(_hovered ? 0.7 : 0.45),
                ),
                const SizedBox(width: 10),
                Text(
                  widget.item.label,
                  style: TextStyle(
                    color: isActive
                        ? bg
                        : primary.withOpacity(_hovered ? 0.8 : 0.55),
                    fontSize: 14,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                    letterSpacing: -0.2,
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
