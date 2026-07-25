import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:thai_safe/features/rescue_approval/service/rescue_approval_service.dart';

class ResponderApplicationPage extends StatefulWidget {
  const ResponderApplicationPage({super.key});

  @override
  State<ResponderApplicationPage> createState() =>
      _ResponderApplicationPageState();
}

class _ResponderApplicationPageState extends State<ResponderApplicationPage> {
  final _organization = TextEditingController();
  final _lastFour = TextEditingController();
  final _evidence = <File>[];
  final _picker = ImagePicker();
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _organization.dispose();
    _lastFour.dispose();
    super.dispose();
  }

  Future<void> _addEvidence() async {
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 75,
    );
    if (file != null && mounted) {
      setState(() => _evidence.add(File(file.path)));
    }
  }

  Future<void> _submit() async {
    if (_organization.text.trim().length < 2 ||
        !RegExp(r'^[0-9A-Za-z]{4}$').hasMatch(_lastFour.text.trim()) ||
        _evidence.isEmpty) {
      setState(() {
        _error =
            'Organization, last four ID characters, and at least one '
            'evidence image are required.';
      });
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await RescueApprovalService().createResponderApplication(
        organization: _organization.text.trim(),
        identityNumberLast4: _lastFour.text.trim(),
        evidence: _evidence,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Responder application submitted for review.'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } catch (error) {
      if (mounted) {
        setState(() {
          _submitting = false;
          _error = error.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Volunteer responder application')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Thai Safe responders are verified volunteers, not official '
                'emergency dispatchers. Evidence is protected and visible '
                'only to the applicant and administrators.',
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _organization,
            maxLength: 160,
            decoration: const InputDecoration(
              labelText: 'Organization or volunteer group',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _lastFour,
            maxLength: 4,
            decoration: const InputDecoration(
              labelText: 'Last 4 characters of identity document',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _evidence.length >= 5 ? null : _addEvidence,
            icon: const Icon(Icons.upload_file),
            label: Text('Add protected evidence (${_evidence.length}/5)'),
          ),
          if (_evidence.isNotEmpty)
            SizedBox(
              height: 100,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _evidence.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (_, index) =>
                    Image.file(_evidence[index], width: 100, fit: BoxFit.cover),
              ),
            ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: Colors.red)),
          ],
          const SizedBox(height: 20),
          SizedBox(
            height: 54,
            child: FilledButton(
              onPressed: _submitting ? null : _submit,
              child: Text(_submitting ? 'Submitting…' : 'Submit application'),
            ),
          ),
        ],
      ),
    );
  }
}
