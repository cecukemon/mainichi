/// Settings screen: lets the user paste their Anthropic API key so live
/// worksheet extraction / conversation generation can run in-app (see
/// project-status.md Bugs: "iOS API key delivery is unaddressed").
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../settings_providers.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _controller = TextEditingController();
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(apiKeyProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Anthropic API key', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(
                    'Used on-device to extract worksheets and generate practice. '
                    'Stored in the iOS Keychain, never sent anywhere but api.anthropic.com.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 20),
                  if (state.hasKey) _KeySetCard(keyValue: state.key!) else _KeyEntryForm(
                    controller: _controller,
                    obscure: _obscure,
                    error: _error,
                    onToggleObscure: () => setState(() => _obscure = !_obscure),
                  ),
                  const SizedBox(height: 12),
                  if (state.hasKey)
                    OutlinedButton.icon(
                      onPressed: () async {
                        await ref.read(apiKeyProvider.notifier).clear();
                      },
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Remove key'),
                    )
                  else
                    FilledButton.icon(
                      onPressed: () async {
                        final value = _controller.text.trim();
                        if (value.isEmpty) {
                          setState(() => _error = 'Enter a key first.');
                          return;
                        }
                        setState(() => _error = null);
                        await ref.read(apiKeyProvider.notifier).save(value);
                        _controller.clear();
                      },
                      icon: const Icon(Icons.save_outlined),
                      label: const Text('Save key'),
                    ),
                ],
              ),
            ),
    );
  }
}

class _KeySetCard extends StatelessWidget {
  const _KeySetCard({required this.keyValue});

  final String keyValue;

  /// e.g. `sk-ant-…wxyz` — enough to recognise which key it is without
  /// displaying the secret.
  String get _masked {
    if (keyValue.length <= 8) return '••••';
    return '${keyValue.substring(0, 4)}…${keyValue.substring(keyValue.length - 4)}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Key saved', style: TextStyle(fontWeight: FontWeight.w500, color: Colors.green)),
                Text(_masked, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.green)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _KeyEntryForm extends StatelessWidget {
  const _KeyEntryForm({
    required this.controller,
    required this.obscure,
    required this.error,
    required this.onToggleObscure,
  });

  final TextEditingController controller;
  final bool obscure;
  final String? error;
  final VoidCallback onToggleObscure;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      autocorrect: false,
      enableSuggestions: false,
      decoration: InputDecoration(
        labelText: 'API key',
        hintText: 'sk-ant-...',
        errorText: error,
        border: const OutlineInputBorder(),
        suffixIcon: IconButton(
          icon: Icon(obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
          onPressed: onToggleObscure,
        ),
      ),
    );
  }
}
