import 'dart:async';

import 'package:bftag_core/bftag_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../admin/api_errors.dart';

Future<bool> _confirm(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Ja',
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Abbrechen'),
        ),
        FilledButton(
          key: const Key('confirm-dialog-confirm'),
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return result ?? false;
}

/// Personen admin screen (`/admin/persons`, Berechtigung Administrator):
/// Personen anlegen/bearbeiten/deaktivieren, Web-Zugang. Keine Handy-Kopplung
/// mehr (BF-Tag ohne Handys: Jugendliche werden nur Fahrzeugen zugeteilt).
///
/// Loads `GET /persons` once on entry and after every mutation -- there is
/// no realtime subscription here (same pattern as VehiclesScreen).
class PersonsScreen extends ConsumerStatefulWidget {
  const PersonsScreen({super.key});

  @override
  ConsumerState<PersonsScreen> createState() => _PersonsScreenState();
}

class _PersonsScreenState extends ConsumerState<PersonsScreen> {
  List<Person>? _persons;
  String? _loadError;
  bool _showInactive = false;

  @override
  void initState() {
    super.initState();
    unawaited(_reload());
  }

  Future<void> _reload() async {
    try {
      final persons = await ref
          .read(personAdminRepositoryProvider)
          .listPersons();
      if (!mounted) return;
      setState(() {
        _persons = persons;
        _loadError = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadError = 'Personen konnten nicht geladen werden.';
      });
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _openCreateDialog() async {
    final result = await showDialog<_PersonFormResult>(
      context: context,
      builder: (context) => const _PersonFormDialog(),
    );
    if (result == null) return;
    try {
      await ref
          .read(personAdminRepositoryProvider)
          .createPerson(
            displayName: result.displayName,
            personType: result.personType,
            permission: result.permission,
          );
      await _reload();
    } catch (error) {
      _showError(
        describeApiError(error, 'Person konnte nicht angelegt werden.'),
      );
    }
  }

  Future<void> _openEditDialog(Person person) async {
    final result = await showDialog<_PersonFormResult>(
      context: context,
      builder: (context) => _PersonFormDialog(initial: person),
    );
    if (result == null) return;
    try {
      await ref
          .read(personAdminRepositoryProvider)
          .updatePerson(
            person.id,
            displayName: result.displayName,
            personType: result.personType,
            permission: result.permission,
          );
      await _reload();
    } catch (error) {
      _showError(
        describeApiError(error, 'Person konnte nicht gespeichert werden.'),
      );
    }
  }

  Future<void> _toggleActive(Person person) async {
    final activate = !person.active;
    final confirmed = await _confirm(
      context,
      title: activate ? 'Person reaktivieren' : 'Person deaktivieren',
      message: activate
          ? '${person.displayName} wieder aktivieren?'
          : '${person.displayName} deaktivieren? Alle Web-Sitzungen und '
                'Geräte dieser Person werden gesperrt.',
    );
    if (!confirmed) return;
    try {
      await ref
          .read(personAdminRepositoryProvider)
          .updatePerson(person.id, active: activate);
      await _reload();
    } catch (error) {
      _showError(
        describeApiError(error, 'Status konnte nicht geändert werden.'),
      );
    }
  }

  Future<void> _openWebAccessDialog(Person person) async {
    final result = await showDialog<_WebAccessDialogResult>(
      context: context,
      builder: (context) => _WebAccessDialog(person: person),
    );
    if (result == null) return;
    try {
      switch (result) {
        case _WebAccessSet(username: final username, password: final password):
          await ref
              .read(personAdminRepositoryProvider)
              .setWebAccess(person.id, username: username, password: password);
        case _WebAccessRemove():
          await ref
              .read(personAdminRepositoryProvider)
              .removeWebAccess(person.id);
      }
      await _reload();
    } catch (error) {
      _showError(
        describeApiError(error, 'Web-Zugang konnte nicht gespeichert werden.'),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final persons = _persons;
    final visible = persons
        ?.where((p) => _showInactive || p.active)
        .toList(growable: false);
    final spacing = Theme.of(context).extension<BftagSpacing>()!;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Personen'),
        actions: [
          Row(
            children: [
              const Text('inaktive anzeigen'),
              Switch(
                key: const Key('show-inactive'),
                value: _showInactive,
                onChanged: (value) => setState(() => _showInactive = value),
              ),
            ],
          ),
          Padding(
            padding: EdgeInsets.only(right: spacing.lg),
            child: FilledButton.icon(
              key: const Key('create-person'),
              onPressed: _openCreateDialog,
              icon: const Icon(Icons.add),
              label: const Text('Person anlegen'),
            ),
          ),
        ],
      ),
      body: _buildBody(context, visible),
    );
  }

  Widget _buildBody(BuildContext context, List<Person>? visible) {
    if (visible == null) {
      final loadError = _loadError;
      if (loadError != null) {
        return BftagStateView.error(message: loadError, onRetry: _reload);
      }
      return const BftagStateView.loading();
    }
    if (visible.isEmpty) {
      return BftagStateView.empty(
        icon: Icons.people_outline,
        title: 'Noch keine Personen angelegt.',
        action: FilledButton.icon(
          key: const Key('persons-empty-create'),
          onPressed: _openCreateDialog,
          icon: const Icon(Icons.add),
          label: const Text('Person anlegen'),
        ),
      );
    }
    final spacing = Theme.of(context).extension<BftagSpacing>()!;
    return ListView.separated(
      key: const Key('persons-list'),
      padding: EdgeInsets.only(bottom: spacing.xxxl + spacing.xl),
      itemCount: visible.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final person = visible[index];
        return _PersonRow(
          person: person,
          onEdit: () => _openEditDialog(person),
          onWebAccess: () => _openWebAccessDialog(person),
          onToggleActive: () => _toggleActive(person),
        );
      },
    );
  }
}

/// Personentyp-/Berechtigungs-Chip (design-system 5.3): `surfaceContainerHigh`
/// standardmäßig, `primaryContainer` für die Berechtigung „Administrator“
/// (hebt die mächtigste Rolle optisch ab, Abschnitt 3).
class _PersonChip extends StatelessWidget {
  const _PersonChip({required this.label, this.emphasize = false});

  final String label;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spacing = theme.extension<BftagSpacing>()!;
    final radii = theme.extension<BftagRadii>()!;
    final background = emphasize
        ? theme.colorScheme.primaryContainer
        : theme.colorScheme.surfaceContainerHigh;
    final foreground = emphasize
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurfaceVariant;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: spacing.sm,
        vertical: spacing.xs / 2,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(radii.small),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelMedium?.copyWith(color: foreground),
      ),
    );
  }
}

/// Personenzeile (design-system 5.3 Tabellenstil): Name + Chips oben,
/// Benutzername (falls Web-Zugang) sowie Aktionen (Web-Zugang,
/// Aktiv-Switch) darunter.
class _PersonRow extends StatelessWidget {
  const _PersonRow({
    required this.person,
    required this.onEdit,
    required this.onWebAccess,
    required this.onToggleActive,
  });

  final Person person;
  final VoidCallback onEdit;
  final VoidCallback onWebAccess;
  final VoidCallback onToggleActive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spacing = theme.extension<BftagSpacing>()!;
    final username = person.hasWebAccess ? person.username : null;
    return InkWell(
      key: Key('person-${person.id}'),
      onTap: onEdit,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: spacing.lg,
          vertical: spacing.sm,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Tooltip(
                    message: person.displayName,
                    child: Text(
                      person.displayName,
                      style: theme.textTheme.titleMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                SizedBox(width: spacing.sm),
                Wrap(
                  spacing: spacing.xs,
                  children: [
                    _PersonChip(label: person.personType.label),
                    _PersonChip(
                      label: person.permission.label,
                      emphasize: person.permission == Permission.admin,
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: spacing.xs),
            Row(
              children: [
                Expanded(
                  child: username != null
                      ? Text(
                          username,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          overflow: TextOverflow.ellipsis,
                        )
                      : const SizedBox.shrink(),
                ),
                if (person.permission != Permission.crew)
                  Tooltip(
                    message: 'Web-Zugang',
                    child: TextButton.icon(
                      key: Key('web-access-${person.id}'),
                      onPressed: onWebAccess,
                      icon: const Icon(Icons.lock_open),
                      label: const Text('Web-Zugang'),
                    ),
                  ),
                SizedBox(width: spacing.sm),
                Text(
                  person.active ? 'aktiv' : 'deaktiviert',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                Switch(
                  key: Key('active-switch-${person.id}'),
                  value: person.active,
                  onChanged: (_) => onToggleActive(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PersonFormResult {
  const _PersonFormResult({
    required this.displayName,
    required this.personType,
    required this.permission,
  });

  final String displayName;
  final PersonType personType;
  final Permission permission;
}

class _PersonFormDialog extends StatefulWidget {
  const _PersonFormDialog({this.initial});

  final Person? initial;

  @override
  State<_PersonFormDialog> createState() => _PersonFormDialogState();
}

class _PersonFormDialogState extends State<_PersonFormDialog> {
  late final TextEditingController _displayNameController;
  late PersonType _personType;
  late Permission _permission;

  @override
  void initState() {
    super.initState();
    _displayNameController = TextEditingController(
      text: widget.initial?.displayName ?? '',
    );
    _personType = widget.initial?.personType ?? PersonType.youth;
    _permission = widget.initial?.permission ?? Permission.crew;
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    super.dispose();
  }

  void _setPersonType(PersonType type) {
    setState(() {
      _personType = type;
      if (type != PersonType.supervisor && _permission == Permission.admin) {
        _permission = Permission.crew;
      }
    });
  }

  void _submit() {
    Navigator.of(context).pop(
      _PersonFormResult(
        displayName: _displayNameController.text.trim(),
        personType: _personType,
        permission: _permission,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.initial != null;
    final allowedPermissions = Permission.values.where(
      (p) => p != Permission.admin || _personType == PersonType.supervisor,
    );
    return AlertDialog(
      title: Text(isEdit ? 'Person bearbeiten' : 'Person anlegen'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              key: const Key('person-form-display-name'),
              controller: _displayNameController,
              decoration: const InputDecoration(labelText: 'Anzeigename'),
            ),
            const SizedBox(height: 12),
            const Text('Personentyp'),
            Wrap(
              spacing: 4,
              children: [
                for (final type in PersonType.values)
                  ChoiceChip(
                    key: Key('person-type-${type.name}'),
                    label: Text(type.label),
                    selected: _personType == type,
                    onSelected: (_) => _setPersonType(type),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            const Text('Berechtigung'),
            Wrap(
              spacing: 4,
              children: [
                for (final permission in allowedPermissions)
                  ChoiceChip(
                    key: Key('permission-${permission.name}'),
                    label: Text(permission.label),
                    selected: _permission == permission,
                    onSelected: (_) => setState(() => _permission = permission),
                  ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Abbrechen'),
        ),
        FilledButton(
          key: const Key('person-form-submit'),
          onPressed: _submit,
          child: const Text('Speichern'),
        ),
      ],
    );
  }
}

sealed class _WebAccessDialogResult {}

class _WebAccessSet extends _WebAccessDialogResult {
  _WebAccessSet({required this.username, required this.password});

  final String username;
  final String password;
}

class _WebAccessRemove extends _WebAccessDialogResult {}

class _WebAccessDialog extends StatefulWidget {
  const _WebAccessDialog({required this.person});

  final Person person;

  @override
  State<_WebAccessDialog> createState() => _WebAccessDialogState();
}

class _WebAccessDialogState extends State<_WebAccessDialog> {
  late final TextEditingController _usernameController;
  final _passwordController = TextEditingController();
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController(
      text: widget.person.username ?? '',
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    final password = _passwordController.text;
    if (password.length < 8) {
      setState(() {
        _errorText = 'Passwort muss mindestens 8 Zeichen lang sein.';
      });
      return;
    }
    Navigator.of(context).pop(
      _WebAccessSet(
        username: _usernameController.text.trim(),
        password: password,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Web-Zugang'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              key: const Key('web-access-username'),
              controller: _usernameController,
              decoration: const InputDecoration(labelText: 'Benutzername'),
            ),
            TextField(
              key: const Key('web-access-password'),
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Passwort'),
            ),
            if (_errorText != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  _errorText!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
          ],
        ),
      ),
      actions: [
        if (widget.person.hasWebAccess)
          TextButton(
            key: const Key('web-access-remove'),
            onPressed: () => Navigator.of(context).pop(_WebAccessRemove()),
            child: const Text('Web-Zugang entfernen'),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Abbrechen'),
        ),
        FilledButton(
          key: const Key('web-access-submit'),
          onPressed: _submit,
          child: const Text('Speichern'),
        ),
      ],
    );
  }
}
