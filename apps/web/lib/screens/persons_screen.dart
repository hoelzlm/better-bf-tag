import 'dart:async';

import 'package:bftag_core/bftag_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../admin/api_errors.dart';
import '../admin/pairing_pdf.dart';

String _formatDateTime(DateTime dateTime) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(dateTime.day)}.${two(dateTime.month)}.${dateTime.year} '
      '${two(dateTime.hour)}:${two(dateTime.minute)}';
}

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
/// Personen anlegen/bearbeiten/deaktivieren, Web-Zugang, Geräteliste,
/// Kopplungscodes (einzeln und als druckbare Liste).
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
      final persons = await ref.read(personAdminRepositoryProvider).listPersons();
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
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _openCreateDialog() async {
    final result = await showDialog<_PersonFormResult>(
      context: context,
      builder: (context) => const _PersonFormDialog(),
    );
    if (result == null) return;
    try {
      await ref.read(personAdminRepositoryProvider).createPerson(
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
      await ref.read(personAdminRepositoryProvider).updatePerson(
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
      _showError(describeApiError(error, 'Status konnte nicht geändert werden.'));
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
          await ref.read(personAdminRepositoryProvider).setWebAccess(
                person.id,
                username: username,
                password: password,
              );
        case _WebAccessRemove():
          await ref.read(personAdminRepositoryProvider).removeWebAccess(person.id);
      }
      await _reload();
    } catch (error) {
      _showError(
        describeApiError(error, 'Web-Zugang konnte nicht gespeichert werden.'),
      );
    }
  }

  Future<void> _openDevicesDialog(Person person) async {
    await showDialog<void>(
      context: context,
      builder: (context) => _PersonDevicesDialog(person: person),
    );
  }

  Future<void> _printPairingCodes() async {
    try {
      final items =
          await ref.read(personAdminRepositoryProvider).createPairingCodes();
      await Printing.layoutPdf(
        onLayout: (format) => buildPairingCodesPdf(items),
      );
    } catch (error) {
      _showError(
        describeApiError(error, 'Kopplungscodes konnten nicht erzeugt werden.'),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final persons = _persons;
    final visible = persons
        ?.where((p) => _showInactive || p.active)
        .toList(growable: false);
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
          IconButton(
            key: const Key('print-pairing-codes'),
            icon: const Icon(Icons.print),
            tooltip: 'Kopplungscodes drucken',
            onPressed: _printPairingCodes,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('create-person'),
        onPressed: _openCreateDialog,
        icon: const Icon(Icons.add),
        label: const Text('Person anlegen'),
      ),
      body: visible == null
          ? Center(
              child: _loadError != null
                  ? Text(_loadError!)
                  : const CircularProgressIndicator(),
            )
          : ListView.builder(
              key: const Key('persons-list'),
              padding: const EdgeInsets.only(bottom: 88),
              itemCount: visible.length,
              itemBuilder: (context, index) {
                final person = visible[index];
                return ListTile(
                  key: Key('person-${person.id}'),
                  title: Text(person.displayName),
                  subtitle: Text(
                    '${person.personType.label} · ${person.permission.label}'
                    ' · ${person.hasWebAccess ? person.username ?? '' : '–'}'
                    '${person.active ? '' : ' · deaktiviert'}',
                  ),
                  onTap: () => _openEditDialog(person),
                  trailing: Wrap(
                    spacing: 4,
                    children: [
                      if (person.permission != Permission.crew)
                        IconButton(
                          key: Key('web-access-${person.id}'),
                          icon: const Icon(Icons.lock_open),
                          tooltip: 'Web-Zugang',
                          onPressed: () => _openWebAccessDialog(person),
                        ),
                      IconButton(
                        key: Key('devices-${person.id}'),
                        icon: const Icon(Icons.devices),
                        tooltip: 'Geräte',
                        onPressed: () => _openDevicesDialog(person),
                      ),
                      Switch(
                        key: Key('active-switch-${person.id}'),
                        value: person.active,
                        onChanged: (_) => _toggleActive(person),
                      ),
                    ],
                  ),
                );
              },
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
                    onSelected: (_) =>
                        setState(() => _permission = permission),
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

class _PersonDevicesDialog extends ConsumerStatefulWidget {
  const _PersonDevicesDialog({required this.person});

  final Person person;

  @override
  ConsumerState<_PersonDevicesDialog> createState() =>
      _PersonDevicesDialogState();
}

class _PersonDevicesDialogState extends ConsumerState<_PersonDevicesDialog> {
  List<Device>? _devices;
  String? _error;
  PairingCodeItem? _pairingCode;

  @override
  void initState() {
    super.initState();
    unawaited(_reload());
  }

  Future<void> _reload() async {
    try {
      final devices = await _repository.listPersonDevices(widget.person.id);
      if (!mounted) return;
      setState(() {
        _devices = devices;
        _error = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Geräte konnten nicht geladen werden.');
    }
  }

  PersonAdminRepository get _repository =>
      ref.read(personAdminRepositoryProvider);

  Future<void> _revoke(Device device) async {
    final confirmed = await _confirm(
      context,
      title: 'Gerät sperren',
      message: 'Dieses Gerät wird sofort abgemeldet und muss neu gekoppelt '
          'werden.',
      confirmLabel: 'Sperren',
    );
    if (!confirmed) return;
    try {
      await _repository.revokeDevice(device.id);
      await _reload();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gerät konnte nicht gesperrt werden.')),
      );
    }
  }

  Future<void> _createPairingCode() async {
    try {
      final item = await _repository.createPairingCode(widget.person.id);
      if (!mounted) return;
      setState(() => _pairingCode = item);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            describeApiError(
              error,
              'Kopplungscode konnte nicht erzeugt werden.',
            ),
          ),
        ),
      );
    }
  }

  Widget _buildPairingCodeContent(PairingCodeItem item) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ExcludeSemantics(
          child: QrImageView(
            data: item.rawCode,
            size: 220,
            backgroundColor: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          item.code,
          key: const Key('pairing-code-text'),
          style: const TextStyle(
            fontFamily: 'monospace',
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text('gültig bis ${_formatDateTime(item.expiresAt.toLocal())}'),
        const SizedBox(height: 8),
        const Text(
          'Dieser Code wird nur einmal angezeigt.',
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildDevicesContent(List<Device> devices) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (devices.isEmpty) const Text('Keine Geräte gekoppelt.'),
        for (final device in devices)
          ListTile(
            key: Key('device-${device.id}'),
            title: Text(
              '${device.platform.label}'
              '${device.deviceName != null ? ' – ${device.deviceName}' : ''}',
            ),
            subtitle: Text(
              'App ${device.appVersion} · gekoppelt am '
              '${_formatDateTime(device.createdAt.toLocal())} · '
              'zuletzt gesehen '
              '${_formatDateTime(device.lastSeenAt.toLocal())} · '
              '${device.isRevoked ? 'gesperrt' : 'aktiv'}',
            ),
            trailing: device.isRevoked
                ? null
                : TextButton(
                    key: Key('revoke-device-${device.id}'),
                    onPressed: () => _revoke(device),
                    child: const Text('Sperren'),
                  ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final devices = _devices;
    final pairingCode = _pairingCode;
    return AlertDialog(
      title: Text(
        pairingCode != null
            ? 'Kopplungscode'
            : 'Geräte von ${widget.person.displayName}',
      ),
      content: SizedBox(
        width: 480,
        child: pairingCode != null
            ? _buildPairingCodeContent(pairingCode)
            : devices == null
                ? SizedBox(
                    height: 80,
                    child: Center(
                      child: _error != null
                          ? Text(_error!)
                          : const CircularProgressIndicator(),
                    ),
                  )
                : _buildDevicesContent(devices),
      ),
      actions: pairingCode != null
          ? [
              TextButton(
                onPressed: () => setState(() => _pairingCode = null),
                child: const Text('Zurück'),
              ),
            ]
          : [
              TextButton(
                key: const Key('create-pairing-code'),
                onPressed: _createPairingCode,
                child: const Text('Kopplungscode erzeugen'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Schließen'),
              ),
            ],
    );
  }
}
