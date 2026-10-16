// AdminShell: permanent sidebar + connection banner wrapping all /admin/*
// routes. Concept: docs/design/screens/web-navigation.md. Replaces the
// per-screen AppBar nav actions that used to live only on LageScreen.
import 'package:bftag_core/bftag_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Width below which the sidebar auto-collapses to icons-only
/// (design-system §4.4 / web-navigation.md §3: tablet range 1024-1279 px).
const double _collapseBreakpoint = 1280;

const double _expandedWidth = 240;
const double _collapsedWidth = 72;

class _NavEntry {
  const _NavEntry({
    required this.navKey,
    required this.icon,
    required this.label,
    required this.route,
  });

  final Key navKey;
  final IconData icon;
  final String label;
  final String route;
}

const _navLage = _NavEntry(
  navKey: Key('nav-lage'),
  icon: Icons.home,
  label: 'Lage',
  route: '/admin',
);
const _navEinsaetze = _NavEntry(
  navKey: Key('nav-einsaetze'),
  icon: Icons.local_fire_department,
  label: 'Einsätze',
  route: '/admin/einsaetze',
);
const _navDurchsagen = _NavEntry(
  navKey: Key('nav-durchsagen'),
  icon: Icons.campaign,
  label: 'Durchsagen',
  route: '/admin/durchsagen',
);
const _navTagesablauf = _NavEntry(
  navKey: Key('nav-tagesablauf'),
  icon: Icons.event_note,
  label: 'Tagesablauf',
  route: '/admin/tagesablauf',
);
const _navSchichten = _NavEntry(
  navKey: Key('nav-schichten'),
  icon: Icons.schedule,
  label: 'Schichten',
  route: '/admin/schichten',
);
const _navBfTage = _NavEntry(
  navKey: Key('nav-bf-tage'),
  icon: Icons.calendar_month,
  label: 'BF-Tage',
  route: '/admin/bf-tage',
);
const _navPersons = _NavEntry(
  navKey: Key('nav-persons'),
  icon: Icons.group,
  label: 'Personen',
  route: '/admin/persons',
);
const _navFahrzeuge = _NavEntry(
  navKey: Key('nav-fahrzeuge'),
  icon: Icons.local_shipping,
  label: 'Fahrzeuge',
  route: '/admin/fahrzeuge',
);
const _navMonitors = _NavEntry(
  navKey: Key('nav-monitors'),
  icon: Icons.desktop_windows,
  label: 'Monitore',
  route: '/admin/monitors',
);
const _navSlides = _NavEntry(
  navKey: Key('nav-slides'),
  icon: Icons.image,
  label: 'Folien',
  route: '/admin/slides',
);

/// Operations-group entries (Betriebsablauf), always before "Verwaltung".
List<_NavEntry> _operationsEntries(Permission permission) => [
  _navLage,
  if (permission == Permission.preparation ||
      permission == Permission.dispatch ||
      permission == Permission.admin)
    _navEinsaetze,
  if (permission == Permission.dispatch || permission == Permission.admin)
    _navDurchsagen,
  if (permission == Permission.dispatch || permission == Permission.admin)
    _navTagesablauf,
  if (permission == Permission.dispatch || permission == Permission.admin)
    _navSchichten,
  if (permission == Permission.dispatch || permission == Permission.admin)
    _navBfTage,
];

/// "Verwaltung" group entries, only ever visible for Administrator.
List<_NavEntry> _adminEntries(Permission permission) => [
  if (permission == Permission.admin) ...[
    _navPersons,
    _navFahrzeuge,
    _navMonitors,
    _navSlides,
  ],
];

/// Permanent sidebar + connection banner wrapping all `/admin/*` routes
/// except `/admin/login` (web-navigation.md §3/§4).
class AdminShell extends ConsumerStatefulWidget {
  const AdminShell({super.key, required this.child, required this.location});

  final Widget child;
  final String location;

  @override
  ConsumerState<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends ConsumerState<AdminShell> {
  /// `null` = follow the width-based auto-collapse; otherwise the user's
  /// manual toggle choice for this session.
  bool? _manualCollapsed;

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionControllerProvider);
    final person = switch (session) {
      SessionSignedIn(person: final p) => p,
      _ => null,
    };
    final permission = person?.permission ?? Permission.crew;
    final connection =
        ref.watch(realtimeConnectionProvider).valueOrNull ??
        ConnectionStatus.connecting;
    final showBanner = connection != ConnectionStatus.live;

    return LayoutBuilder(
      builder: (context, constraints) {
        final autoCollapsed = constraints.maxWidth < _collapseBreakpoint;
        final collapsed = _manualCollapsed ?? autoCollapsed;

        return Scaffold(
          body: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Sidebar(
                collapsed: collapsed,
                location: widget.location,
                permission: permission,
                displayName: person?.displayName ?? '',
                permissionLabel: permission.label,
                onToggle: () {
                  setState(() {
                    _manualCollapsed = !collapsed;
                  });
                },
                onLogout: () {
                  ref.read(sessionControllerProvider.notifier).logout();
                },
              ),
              Expanded(
                child: Column(
                  children: [
                    if (showBanner)
                      const KeyedSubtree(
                        key: Key('connection-banner'),
                        child: ConnectionBanner(connected: false),
                      ),
                    Expanded(child: widget.child),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({
    required this.collapsed,
    required this.location,
    required this.permission,
    required this.displayName,
    required this.permissionLabel,
    required this.onToggle,
    required this.onLogout,
  });

  final bool collapsed;
  final String location;
  final Permission permission;
  final String displayName;
  final String permissionLabel;
  final VoidCallback onToggle;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spacing = theme.extension<BftagSpacing>() ?? const BftagSpacing();
    final operations = _operationsEntries(permission);
    final admin = _adminEntries(permission);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOutCubic,
      width: collapsed ? _collapsedWidth : _expandedWidth,
      color: theme.colorScheme.surfaceContainer,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SidebarHeader(collapsed: collapsed, onToggle: onToggle),
          Expanded(
            child: ListView(
              padding: EdgeInsets.symmetric(vertical: spacing.sm),
              children: [
                for (final entry in operations)
                  _NavItem(
                    entry: entry,
                    collapsed: collapsed,
                    active: _isActive(entry, location),
                  ),
                if (admin.isNotEmpty) ...[
                  _SectionHeading(
                    collapsed: collapsed,
                    label: 'Verwaltung',
                  ),
                  for (final entry in admin)
                    _NavItem(
                      entry: entry,
                      collapsed: collapsed,
                      active: _isActive(entry, location),
                    ),
                ],
              ],
            ),
          ),
          _SidebarFooter(
            collapsed: collapsed,
            displayName: displayName,
            permissionLabel: permissionLabel,
            onLogout: onLogout,
          ),
        ],
      ),
    );
  }

  bool _isActive(_NavEntry entry, String location) {
    if (entry.route == '/admin') {
      return location == '/admin';
    }
    return location.startsWith(entry.route);
  }
}

class _SidebarHeader extends StatelessWidget {
  const _SidebarHeader({required this.collapsed, required this.onToggle});

  final bool collapsed;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spacing = theme.extension<BftagSpacing>() ?? const BftagSpacing();
    return Padding(
      padding: EdgeInsets.all(spacing.lg),
      child: Row(
        mainAxisAlignment: collapsed
            ? MainAxisAlignment.center
            : MainAxisAlignment.spaceBetween,
        children: [
          if (!collapsed)
            Expanded(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.local_fire_department,
                    color: theme.colorScheme.primary,
                  ),
                  SizedBox(width: spacing.sm),
                  Flexible(
                    child: Text(
                      'BF-Tag',
                      style: theme.textTheme.titleMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          Tooltip(
            message: collapsed ? 'Seitenleiste ausklappen' : 'Seitenleiste einklappen',
            child: InkWell(
              onTap: onToggle,
              customBorder: const CircleBorder(),
              child: SizedBox(
                width: 32,
                height: 32,
                child: Icon(
                  collapsed ? Icons.menu : Icons.menu_open,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.collapsed, required this.label});

  final bool collapsed;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spacing = theme.extension<BftagSpacing>() ?? const BftagSpacing();
    if (collapsed) {
      return SizedBox(height: spacing.lg);
    }
    return Padding(
      padding: EdgeInsets.fromLTRB(spacing.lg, spacing.lg, spacing.lg, spacing.xs),
      child: Text(
        label,
        style: theme.textTheme.labelMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

/// A single, focusable sidebar entry with a visible 2 px primary focus
/// ring (design-system §8) and a [Tooltip] whose message doubles as the
/// accessible/semantics label in both expanded and collapsed states.
class _NavItem extends StatefulWidget {
  const _NavItem({
    required this.entry,
    required this.collapsed,
    required this.active,
  });

  final _NavEntry entry;
  final bool collapsed;
  final bool active;

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spacing = theme.extension<BftagSpacing>() ?? const BftagSpacing();
    final radii = theme.extension<BftagRadii>() ?? const BftagRadii();
    final entry = widget.entry;

    final content = Container(
      key: entry.navKey,
      height: 44,
      margin: EdgeInsets.symmetric(horizontal: spacing.sm, vertical: 2),
      decoration: BoxDecoration(
        color: widget.active ? theme.colorScheme.primaryContainer : null,
        borderRadius: BorderRadius.circular(radii.medium),
        border: Border(
          left: widget.active
              ? BorderSide(color: theme.colorScheme.primary, width: 3)
              : const BorderSide(width: 3, style: BorderStyle.none),
        ),
        boxShadow: _focused
            ? [
                BoxShadow(
                  color: theme.colorScheme.primary,
                  spreadRadius: 2,
                ),
              ]
            : null,
      ),
      padding: EdgeInsets.symmetric(
        horizontal: widget.collapsed ? spacing.sm : spacing.md,
      ),
      child: Row(
        mainAxisAlignment: widget.collapsed
            ? MainAxisAlignment.center
            : MainAxisAlignment.start,
        children: [
          Icon(
            entry.icon,
            color: widget.active
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurfaceVariant,
          ),
          if (!widget.collapsed) ...[
            SizedBox(width: spacing.sm),
            Expanded(
              child: Text(
                entry.label,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: widget.active
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ],
      ),
    );

    return Tooltip(
      message: entry.label,
      child: Focus(
        onFocusChange: (focused) => setState(() => _focused = focused),
        child: InkWell(
          borderRadius: BorderRadius.circular(radii.medium),
          onTap: () => context.go(entry.route),
          child: content,
        ),
      ),
    );
  }
}

class _SidebarFooter extends StatelessWidget {
  const _SidebarFooter({
    required this.collapsed,
    required this.displayName,
    required this.permissionLabel,
    required this.onLogout,
  });

  final bool collapsed;
  final String displayName;
  final String permissionLabel;
  final VoidCallback onLogout;

  String get _initials {
    final parts = displayName.trim().split(RegExp(r'\s+'));
    final letters = parts
        .where((p) => p.isNotEmpty)
        .map((p) => p[0].toUpperCase())
        .take(2)
        .join();
    return letters;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spacing = theme.extension<BftagSpacing>() ?? const BftagSpacing();
    final radii = theme.extension<BftagRadii>() ?? const BftagRadii();
    final tooltipText = '$displayName ($permissionLabel)';

    return Padding(
      padding: EdgeInsets.all(spacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: EdgeInsets.only(bottom: spacing.sm),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: theme.colorScheme.outline),
              ),
            ),
          ),
          if (collapsed)
            Tooltip(
              message: tooltipText,
              child: Center(
                child: CircleAvatar(
                  radius: 16,
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: Text(
                    _initials,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
              ),
            )
          else ...[
            Tooltip(
              message: displayName,
              child: Text(
                displayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium,
              ),
            ),
            Text(
              permissionLabel,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          SizedBox(height: spacing.sm),
          Tooltip(
            message: 'Abmelden',
            child: InkWell(
              key: const Key('logout'),
              borderRadius: BorderRadius.circular(radii.medium),
              onTap: onLogout,
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: spacing.xs),
                child: Row(
                  mainAxisAlignment: collapsed
                      ? MainAxisAlignment.center
                      : MainAxisAlignment.start,
                  children: [
                    Icon(Icons.logout, color: theme.colorScheme.onSurface),
                    if (!collapsed) ...[
                      SizedBox(width: spacing.sm),
                      Text('Abmelden', style: theme.textTheme.bodyMedium),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
