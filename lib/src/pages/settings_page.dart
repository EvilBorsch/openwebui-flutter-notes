import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/settings_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _form = GlobalKey<FormState>();
  late TextEditingController _baseUrl;
  late TextEditingController _token;
  late TextEditingController _model;
  late TextEditingController _collectionId;
  bool _dark = false;

  @override
  void initState() {
    super.initState();
    final s = context.read<SettingsService>();
    _baseUrl = TextEditingController(text: s.baseUrl);
    _token = TextEditingController(text: s.token);
    _model = TextEditingController(text: s.model);
    _collectionId = TextEditingController(text: s.collectionId);
    _dark = s.isDark;
  }

  @override
  void dispose() {
    _baseUrl.dispose();
    _token.dispose();
    _model.dispose();
    _collectionId.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _baseUrl,
              decoration: const InputDecoration(
                labelText: 'Open WebUI Base URL',
              ),
              validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _token,
              decoration: const InputDecoration(labelText: 'Bearer Token'),
              obscureText: true,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _model,
              decoration: const InputDecoration(
                labelText: 'LLM Model (optional)',
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _collectionId,
              decoration: const InputDecoration(
                labelText: 'Knowledge Collection ID (notes)',
              ),
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              title: const Text('Dark mode'),
              value: _dark,
              onChanged: (v) => setState(() => _dark = v),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () async {
                if (!_form.currentState!.validate()) return;
                await context.read<SettingsService>().update(
                  baseUrl: _baseUrl.text,
                  token: _token.text,
                  model: _model.text,
                  collectionId: _collectionId.text,
                  isDark: _dark,
                );
                if (!context.mounted) return;
                Navigator.of(context).pop();
              },
              icon: const Icon(Icons.save),
              label: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
