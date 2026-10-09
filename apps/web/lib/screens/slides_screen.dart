import 'dart:async';
import 'dart:typed_data';

import 'package:bftag_core/bftag_core.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../admin/api_errors.dart';

/// `SLIDE_IMAGE_MAX_BYTES` (ADR 0014): client-side pre-check before upload,
/// the server enforces this authoritatively.
const _maxSlideImageBytes = 5 * 1024 * 1024;

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

/// Guesses the image content type for client-side validation (ADR 0014:
/// png/jpeg/webp by magic bytes); `null` if none match. The server checks
/// the same magic bytes authoritatively, so a false positive here is only
/// ever caught later by the 415 response.
String? _detectImageContentType(Uint8List bytes) {
  if (bytes.length >= 8 &&
      bytes[0] == 0x89 &&
      bytes[1] == 0x50 &&
      bytes[2] == 0x4E &&
      bytes[3] == 0x47 &&
      bytes[4] == 0x0D &&
      bytes[5] == 0x0A &&
      bytes[6] == 0x1A &&
      bytes[7] == 0x0A) {
    return 'image/png';
  }
  if (bytes.length >= 3 &&
      bytes[0] == 0xFF &&
      bytes[1] == 0xD8 &&
      bytes[2] == 0xFF) {
    return 'image/jpeg';
  }
  if (bytes.length >= 12 &&
      bytes[0] == 0x52 &&
      bytes[1] == 0x49 &&
      bytes[2] == 0x46 &&
      bytes[3] == 0x46 &&
      bytes[8] == 0x57 &&
      bytes[9] == 0x45 &&
      bytes[10] == 0x42 &&
      bytes[11] == 0x50) {
    return 'image/webp';
  }
  return null;
}

/// Folien admin screen (`/admin/slides`, Berechtigung Administrator):
/// Liste mit Ziehen zum Sortieren, Schalter aktiv/inaktiv, Anlegen und
/// Bearbeiten im Dialog, Bild hochladen/entfernen, Löschen mit Rückfrage
/// (ADR 0014).
///
/// Loads `GET /slides` once on entry and after every mutation -- there is
/// no realtime subscription here (same pattern as VehiclesScreen).
class SlidesScreen extends ConsumerStatefulWidget {
  const SlidesScreen({super.key});

  @override
  ConsumerState<SlidesScreen> createState() => _SlidesScreenState();
}

class _SlidesScreenState extends ConsumerState<SlidesScreen> {
  List<Slide>? _slides;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    unawaited(_reload());
  }

  Future<void> _reload() async {
    try {
      final slides = await ref.read(slideAdminRepositoryProvider).list();
      if (!mounted) return;
      setState(() {
        _slides = slides;
        _loadError = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadError = 'Folien konnten nicht geladen werden.';
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
    final result = await showDialog<_SlideFormResult>(
      context: context,
      builder: (context) => const _SlideFormDialog(),
    );
    if (result == null) return;
    try {
      await ref.read(slideAdminRepositoryProvider).create(
            title: result.title,
            body: result.body,
            durationSeconds: result.durationSeconds,
            active: result.active,
          );
      await _reload();
    } catch (error) {
      _showError(describeApiError(error, 'Folie konnte nicht angelegt werden.'));
    }
  }

  Future<void> _openEditDialog(Slide slide) async {
    final result = await showDialog<_SlideFormResult>(
      context: context,
      builder: (context) => _SlideFormDialog(initial: slide),
    );
    if (result == null) return;
    try {
      await ref.read(slideAdminRepositoryProvider).update(
            slide.id,
            title: result.title,
            body: result.body,
            durationSeconds: result.durationSeconds,
            active: result.active,
          );
      await _reload();
    } catch (error) {
      _showError(
        describeApiError(error, 'Folie konnte nicht gespeichert werden.'),
      );
    }
  }

  Future<void> _toggleActive(Slide slide, bool active) async {
    try {
      await ref
          .read(slideAdminRepositoryProvider)
          .update(slide.id, active: active);
      await _reload();
    } catch (error) {
      _showError(describeApiError(error, 'Status konnte nicht geändert werden.'));
    }
  }

  Future<void> _delete(Slide slide) async {
    final confirmed = await _confirm(
      context,
      title: 'Folie löschen',
      message: '„${slide.title}“ wird endgültig gelöscht.',
      confirmLabel: 'Löschen',
    );
    if (!confirmed) return;
    try {
      await ref.read(slideAdminRepositoryProvider).delete(slide.id);
      await _reload();
    } catch (error) {
      _showError(describeApiError(error, 'Folie konnte nicht gelöscht werden.'));
    }
  }

  Future<void> _reorder(int oldIndex, int newIndex) async {
    final slides = _slides;
    if (slides == null) return;
    final updated = List<Slide>.of(slides);
    final moved = updated.removeAt(oldIndex);
    updated.insert(newIndex, moved);
    setState(() => _slides = updated);
    try {
      await ref
          .read(slideAdminRepositoryProvider)
          .reorder(updated.map((s) => s.id).toList());
      await _reload();
    } catch (error) {
      _showError(
        describeApiError(error, 'Reihenfolge konnte nicht gespeichert werden.'),
      );
      await _reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    final slides = _slides;
    return Scaffold(
      appBar: AppBar(title: const Text('Folien')),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('create-slide'),
        onPressed: _openCreateDialog,
        icon: const Icon(Icons.add),
        label: const Text('Folie anlegen'),
      ),
      body: slides == null
          ? Center(
              child: _loadError != null
                  ? Text(_loadError!)
                  : const CircularProgressIndicator(),
            )
          : ReorderableListView.builder(
              key: const Key('slides-list'),
              padding: const EdgeInsets.only(bottom: 88),
              itemCount: slides.length,
              onReorderItem: _reorder,
              itemBuilder: (context, index) {
                final slide = slides[index];
                return ListTile(
                  key: ValueKey(slide.id),
                  leading: slide.image != null
                      ? SizedBox(
                          width: 48,
                          height: 48,
                          child: _SlideThumbnail(
                            slideId: slide.id,
                            version: slide.image!.version,
                          ),
                        )
                      : const Icon(Icons.image_not_supported_outlined),
                  title: Text(slide.title),
                  subtitle: Text('${slide.durationSeconds} s'),
                  onTap: () => _openEditDialog(slide),
                  trailing: Wrap(
                    spacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Switch(
                        key: Key('active-switch-${slide.id}'),
                        value: slide.active,
                        onChanged: (value) => _toggleActive(slide, value),
                      ),
                      IconButton(
                        key: Key('delete-slide-${slide.id}'),
                        icon: const Icon(Icons.delete_outline),
                        tooltip: 'Löschen',
                        onPressed: () => _delete(slide),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

/// Loads and shows a slide's thumbnail via [SlideImageLoader]; nothing
/// while loading or on error (same approach as `SlideRotator`'s
/// `_SlideImage`).
class _SlideThumbnail extends ConsumerStatefulWidget {
  const _SlideThumbnail({required this.slideId, required this.version});

  final String slideId;
  final String version;

  @override
  ConsumerState<_SlideThumbnail> createState() => _SlideThumbnailState();
}

class _SlideThumbnailState extends ConsumerState<_SlideThumbnail> {
  late Future<Uint8List> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  void didUpdateWidget(covariant _SlideThumbnail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.slideId != widget.slideId ||
        oldWidget.version != widget.version) {
      _future = _load();
    }
  }

  Future<Uint8List> _load() =>
      ref.read(slideImageLoaderProvider).load(widget.slideId, widget.version);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done ||
            !snapshot.hasData) {
          return const SizedBox.shrink();
        }
        return Image.memory(
          snapshot.data!,
          key: const Key('slide-thumbnail'),
          fit: BoxFit.cover,
        );
      },
    );
  }
}

class _SlideFormResult {
  const _SlideFormResult({
    required this.title,
    required this.body,
    required this.durationSeconds,
    required this.active,
  });

  final String title;
  final String body;
  final int durationSeconds;
  final bool active;
}

class _SlideFormDialog extends ConsumerStatefulWidget {
  const _SlideFormDialog({this.initial});

  final Slide? initial;

  @override
  ConsumerState<_SlideFormDialog> createState() => _SlideFormDialogState();
}

class _SlideFormDialogState extends ConsumerState<_SlideFormDialog> {
  late final TextEditingController _titleController;
  late final TextEditingController _bodyController;
  late final TextEditingController _durationController;
  late bool _active;
  bool _showPreview = false;
  bool _uploadingImage = false;
  SlideImage? _image;
  String? _titleError;
  String? _bodyError;
  String? _durationError;
  String? _imageError;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _titleController = TextEditingController(text: initial?.title ?? '');
    _bodyController = TextEditingController(text: initial?.body ?? '');
    _durationController = TextEditingController(
      text: '${initial?.durationSeconds ?? 10}',
    );
    _active = initial?.active ?? true;
    _image = initial?.image;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  bool _validate() {
    final title = _titleController.text.trim();
    final body = _bodyController.text;
    final duration = int.tryParse(_durationController.text.trim());
    String? titleError;
    String? bodyError;
    String? durationError;
    if (title.isEmpty) {
      titleError = 'Titel ist erforderlich.';
    } else if (title.length > 200) {
      titleError = 'Titel darf höchstens 200 Zeichen haben.';
    }
    if (body.length > 5000) {
      bodyError = 'Text darf höchstens 5000 Zeichen haben.';
    }
    if (duration == null || duration < 3 || duration > 300) {
      durationError =
          'Anzeigedauer muss zwischen 3 und 300 Sekunden liegen.';
    }
    setState(() {
      _titleError = titleError;
      _bodyError = bodyError;
      _durationError = durationError;
    });
    return titleError == null && bodyError == null && durationError == null;
  }

  void _submit() {
    if (!_validate()) return;
    Navigator.of(context).pop(
      _SlideFormResult(
        title: _titleController.text.trim(),
        body: _bodyController.text,
        durationSeconds: int.parse(_durationController.text.trim()),
        active: _active,
      ),
    );
  }

  Future<void> _pickImage() async {
    final slideId = widget.initial?.id;
    if (slideId == null) return;
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    final bytes = file.bytes;
    if (bytes == null) return;
    if (bytes.length > _maxSlideImageBytes) {
      setState(() => _imageError = 'Bild ist zu groß (max. 5 MB).');
      return;
    }
    final contentType = _detectImageContentType(bytes);
    if (contentType == null) {
      setState(() => _imageError = 'Nur PNG, JPEG oder WebP.');
      return;
    }
    setState(() {
      _imageError = null;
      _uploadingImage = true;
    });
    try {
      final slide = await ref
          .read(slideAdminRepositoryProvider)
          .uploadImage(slideId, bytes, contentType);
      if (!mounted) return;
      setState(() {
        _image = slide.image;
        _uploadingImage = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _imageError = describeSlideImageError(error);
        _uploadingImage = false;
      });
    }
  }

  Future<void> _removeImage() async {
    final slideId = widget.initial?.id;
    if (slideId == null) return;
    try {
      await ref.read(slideAdminRepositoryProvider).deleteImage(slideId);
      if (!mounted) return;
      setState(() {
        _image = null;
        _imageError = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _imageError = describeSlideImageError(error));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.initial != null;
    return AlertDialog(
      title: Text(isEdit ? 'Folie bearbeiten' : 'Folie anlegen'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              key: const Key('slide-form-title'),
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Titel',
                errorText: _titleError,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text('Text (Markdown)'),
                const Spacer(),
                TextButton(
                  key: const Key('slide-form-preview-toggle'),
                  onPressed: () =>
                      setState(() => _showPreview = !_showPreview),
                  child: Text(_showPreview ? 'Bearbeiten' : 'Vorschau'),
                ),
              ],
            ),
            if (_showPreview)
              Container(
                key: const Key('slide-form-preview'),
                width: double.infinity,
                constraints: const BoxConstraints(minHeight: 80),
                alignment: Alignment.topLeft,
                child: MarkdownBody(data: _bodyController.text),
              )
            else
              TextField(
                key: const Key('slide-form-body'),
                controller: _bodyController,
                maxLines: 6,
                decoration: InputDecoration(
                  labelText: 'Text',
                  errorText: _bodyError,
                ),
              ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('slide-form-duration'),
              controller: _durationController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Anzeigedauer (Sekunden)',
                errorText: _durationError,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text('aktiv'),
                Switch(
                  key: const Key('slide-form-active'),
                  value: _active,
                  onChanged: (value) => setState(() => _active = value),
                ),
              ],
            ),
            if (isEdit) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  TextButton(
                    key: const Key('slide-form-upload-image'),
                    onPressed: _uploadingImage ? null : _pickImage,
                    child: const Text('Bild hochladen'),
                  ),
                  if (_image != null)
                    TextButton(
                      key: const Key('slide-form-remove-image'),
                      onPressed: _removeImage,
                      child: const Text('Bild entfernen'),
                    ),
                ],
              ),
              if (_imageError != null)
                Text(
                  _imageError!,
                  key: const Key('slide-form-image-error'),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Abbrechen'),
        ),
        FilledButton(
          key: const Key('slide-form-submit'),
          onPressed: _submit,
          child: const Text('Speichern'),
        ),
      ],
    );
  }
}
