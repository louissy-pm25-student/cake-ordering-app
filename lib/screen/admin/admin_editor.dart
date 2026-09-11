import 'dart:convert';
import 'dart:ui' show ImmutableBuffer;

import 'package:flutter/material.dart';
import 'package:file_selector/file_selector.dart';

import '../../model/admin/admin_record.dart';
import '../../model/admin/admin_schema.dart';
import '../../viewmodel/admin/admin_viewmodel.dart';
import '../../ui/cake_style.dart';

Future<bool?> editAdminRecord(
  BuildContext context,
  AdminViewModel vm,
  String section, {
  AdminRecord? record,
}) => showDialog<bool>(
  context: context,
  barrierDismissible: false,
  builder: (_) => AdminEditor(vm: vm, section: section, record: record),
);

class AdminEditor extends StatefulWidget {
  final AdminViewModel vm;
  final String section;
  final AdminRecord? record;
  const AdminEditor({
    required this.vm,
    required this.section,
    this.record,
    super.key,
  });
  @override
  State<AdminEditor> createState() => _AdminEditorState();
}

class _AdminEditorState extends State<AdminEditor> {
  final _form = GlobalKey<FormState>();
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, dynamic> _values = {};
  String? _error;
  bool _saving = false;
  @override
  void initState() {
    super.initState();
    for (final field in sectionFor(widget.section).fields) {
      final value = widget.record?.values[field.key];
      if (field.type == 'bool') {
        _values[field.key] = value ?? true;
      } else if (field.type == 'photo') {
        _values[field.key] = value ?? '';
      } else if (field.reference != null || field.options.isNotEmpty) {
        _values[field.key] =
            value ?? (field.options.isNotEmpty ? field.options.first : '');
      } else {
        final fallback = field.key == 'quantity'
            ? '1'
            : field.type == 'date' && field.required
            ? widget.vm.today
            : field.type == 'number' ||
                  field.type == 'signed' ||
                  field.type == 'integer'
            ? '0'
            : '';
        _controllers[field.key] = TextEditingController(
          text: field.type == 'password' ? '' : '${value ?? fallback}',
        );
      }
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final values = {
      ...?widget.record?.values,
      ..._values,
      ..._controllers.map((key, value) => MapEntry(key, value.text.trim())),
    };
    final ok = await widget.vm.save(
      widget.section,
      values,
      id: widget.record?.id,
    );
    if (!mounted) return;
    if (ok) {
      Navigator.pop(context, true);
    } else {
      setState(() {
        _saving = false;
        _error = widget.vm.error;
      });
    }
  }

  Future<void> _photo(String key) async {
    try {
      final file = await openFile(
        acceptedTypeGroups: [
          const XTypeGroup(
            label: 'Cake images',
            extensions: ['png', 'jpg', 'jpeg', 'webp'],
            mimeTypes: ['image/png', 'image/jpeg', 'image/webp'],
          ),
        ],
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      if (bytes.length > 2 * 1024 * 1024) {
        if (mounted) {
          setState(() => _error = 'Choose an image smaller than 2 MB.');
        }
        return;
      }
      // Decode before saving so invalid uploads never reach the menu.
      final codec = await PaintingBinding.instance
          .instantiateImageCodecWithSize(
            await ImmutableBuffer.fromUint8List(bytes),
          );
      codec.dispose();
      if (mounted) setState(() => _values[key] = base64Encode(bytes));
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'Could not load that image. Choose PNG, JPEG or WebP.',
        );
      }
    }
  }

  Widget _field(AdminField field) {
    if (field.type == 'bool') {
      return SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(field.label),
        value: _values[field.key] == true,
        onChanged: _saving
            ? null
            : (value) => setState(() => _values[field.key] = value),
      );
    }
    if (field.type == 'photo') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if ('${_values[field.key]}'.isNotEmpty)
            SizedBox(
              height: 120,
              width: double.infinity,
              child: Image.memory(
                base64Decode('${_values[field.key]}'),
                fit: BoxFit.contain,
              ),
            ),
          Wrap(
            children: [
              TextButton.icon(
                onPressed: _saving ? null : () => _photo(field.key),
                icon: const Icon(Icons.photo_library_outlined),
                label: const Text('Choose photo (up to 2 MB)'),
              ),
              TextButton(
                onPressed: _saving
                    ? null
                    : () => setState(() => _values[field.key] = ''),
                child: const Text('Remove photo'),
              ),
            ],
          ),
        ],
      );
    }
    if (field.reference != null || field.options.isNotEmpty) {
      final options = field.reference == null
          ? {for (final option in field.options) option: option}
          : {
              for (final row in widget.vm.records(field.reference!))
                row.id: [
                  row.text('name', row.text('customer', row.id)),
                  row.text('date'),
                ].where((s) => s.isNotEmpty).join(' · '),
            };
      if (!field.required) options[''] = 'None';
      var current = '${_values[field.key] ?? ''}';
      if (current.isNotEmpty && !options.containsKey(current)) {
        options[current] = '$current (unavailable)';
      }
      return DropdownButtonFormField<String>(
        initialValue: options.containsKey(current) ? current : null,
        isExpanded: true,
        decoration: InputDecoration(labelText: field.label),
        items: options.entries
            .map(
              (e) => DropdownMenuItem(
                value: e.key,
                child: Text(e.value, overflow: TextOverflow.ellipsis),
              ),
            )
            .toList(),
        onChanged: _saving ? null : (v) => _values[field.key] = v ?? '',
        validator: (v) => field.required && (v == null || v.isEmpty)
            ? 'Select ${field.label}.'
            : null,
      );
    }
    final controller = _controllers[field.key]!;
    return TextFormField(
      controller: controller,
      enabled: !_saving,
      obscureText: field.type == 'password',
      maxLines: field.type == 'multiline' ? 3 : 1,
      keyboardType: ['number', 'integer', 'signed'].contains(field.type)
          ? const TextInputType.numberWithOptions(decimal: true, signed: true)
          : TextInputType.text,
      decoration: InputDecoration(
        labelText: field.label,
        suffixIcon: field.type == 'date'
            ? IconButton(
                onPressed: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate:
                        DateTime.tryParse(controller.text) ?? DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2100),
                  );
                  if (date != null) controller.text = dayKey(date);
                },
                icon: const Icon(Icons.calendar_today_outlined),
              )
            : null,
      ),
      validator: (v) {
        if (field.required && (v ?? '').trim().isEmpty) {
          return '${field.label} is required.';
        }
        if (['number', 'integer', 'signed'].contains(field.type) &&
            (v ?? '').isNotEmpty &&
            double.tryParse(v!) == null) {
          return 'Enter a number.';
        }
        return null;
      },
    );
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    backgroundColor: CakeStyle.cream,
    title: Text(
      '${widget.record == null ? 'Add' : 'Edit'} ${sectionFor(widget.section).title}',
    ),
    content: SizedBox(
      width: 520,
      child: SingleChildScrollView(
        child: Form(
          key: _form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final field in sectionFor(widget.section).fields)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _field(field),
                ),
              if (_error != null)
                Text(_error!, style: const TextStyle(color: Colors.red)),
            ],
          ),
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: _saving ? null : () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: _saving ? null : _save,
        child: Text(_saving ? 'Saving…' : 'Save'),
      ),
    ],
  );
}
