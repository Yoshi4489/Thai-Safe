import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:thai_safe/core/config/remote_config_service.dart';
import 'package:thai_safe/core/services/firebase_storage_service.dart';
import 'package:thai_safe/core/services/safety_functions_repository.dart';

class ReportIncidentPage extends StatefulWidget {
  const ReportIncidentPage({
    super.key,
    required this.incidentId,
    required this.currentLocation,
  });

  final String incidentId;
  final LatLng currentLocation;

  @override
  State<ReportIncidentPage> createState() => _ReportIncidentPageState();
}

class _ReportIncidentPageState extends State<ReportIncidentPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _summaryController = TextEditingController();
  final _detailsController = TextEditingController();
  final _picker = ImagePicker();
  final _functions = SafetyFunctionsRepository();
  final _storage = FirebaseStorageService();

  static const _categories = {
    'fire': 'Fire',
    'flood': 'Flood',
    'collapse': 'Building collapse / earthquake',
    'chemical': 'Chemical hazard',
    'violence': 'Violence / security',
    'medical': 'Medical',
    'other': 'Other',
  };

  String _category = 'other';
  String _urgency = 'urgent';
  File? _image;
  bool _isSaving = false;
  String? _error;

  @override
  void dispose() {
    _titleController.dispose();
    _summaryController.dispose();
    _detailsController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final file = await _picker.pickImage(
      source: source,
      imageQuality: 70,
      maxWidth: 1920,
    );
    if (file != null && mounted) setState(() => _image = File(file.path));
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _isSaving) return;
    setState(() {
      _isSaving = true;
      _error = null;
    });
    try {
      final mediaPaths = <String>[];
      if (_image != null) {
        mediaPaths.add(
          await _storage.uploadIncidentImage(
            incidentId: widget.incidentId,
            file: _image!,
          ),
        );
      }
      await _functions.enrichIncident(
        incidentId: widget.incidentId,
        title: _titleController.text,
        category: _category,
        urgency: _urgency,
        summary: _summaryController.text,
        details: {'description': _detailsController.text.trim()},
        mediaPaths: mediaPaths,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Optional incident details saved.'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final enabled = RemoteConfigService.instance.enrichmentEnabled;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add optional details'),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : () => Navigator.pop(context),
            child: const Text('Skip'),
          ),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Card(
                color: Colors.green.shade50,
                child: const ListTile(
                  leading: Icon(Icons.check_circle, color: Colors.green),
                  title: Text('Your quick SOS was sent'),
                  subtitle: Text(
                    'These details are optional and can help the assigned '
                    'volunteer responder understand the situation.',
                  ),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _category,
                decoration: const InputDecoration(
                  labelText: 'Incident category',
                  border: OutlineInputBorder(),
                ),
                items: _categories.entries
                    .map(
                      (entry) => DropdownMenuItem(
                        value: entry.key,
                        child: Text(entry.value),
                      ),
                    )
                    .toList(),
                onChanged: (value) =>
                    setState(() => _category = value ?? 'other'),
              ),
              const SizedBox(height: 16),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'standard', label: Text('Standard')),
                  ButtonSegment(value: 'urgent', label: Text('Urgent')),
                  ButtonSegment(value: 'critical', label: Text('Critical')),
                ],
                selected: {_urgency},
                onSelectionChanged: (values) {
                  setState(() => _urgency = values.first);
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _titleController,
                maxLength: 120,
                decoration: const InputDecoration(
                  labelText: 'Short title',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Enter a short title or choose Skip.'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _summaryController,
                maxLength: 500,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Public summary',
                  helperText:
                      'Do not include names, phone numbers, or medical details.',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _detailsController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Private responder details',
                  helperText:
                      'Visible only to you and the actively assigned responder.',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: () => showModalBottomSheet<void>(
                  context: context,
                  builder: (sheetContext) => SafeArea(
                    child: Wrap(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.camera_alt),
                          title: const Text('Take photo'),
                          onTap: () {
                            Navigator.pop(sheetContext);
                            _pickImage(ImageSource.camera);
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.photo_library),
                          title: const Text('Choose photo'),
                          onTap: () {
                            Navigator.pop(sheetContext);
                            _pickImage(ImageSource.gallery);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                child: Container(
                  height: 140,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: _image == null
                      ? const Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.add_a_photo_outlined),
                            SizedBox(height: 8),
                            Text('Add protected photo (optional)'),
                          ],
                        )
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            _image!,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: const TextStyle(color: Colors.red)),
              ],
              const SizedBox(height: 24),
              SizedBox(
                height: 56,
                child: FilledButton.icon(
                  onPressed: enabled && !_isSaving ? _save : null,
                  icon: _isSaving
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.save),
                  label: Text(
                    enabled ? 'Save details' : 'Details temporarily disabled',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
