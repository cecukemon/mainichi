/// Settings screen: API key slots for the live services — Anthropic (worksheet
/// extraction, conversation generation) and Google Cloud (TTS for the
/// listening exercise, STT later). Both Keychain-backed via [ApiKeyStore].
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../settings_providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          _KeySection(
            title: 'Anthropic API key',
            description:
                'Used on-device to extract worksheets and generate practice. '
                'Stored in the iOS Keychain, never sent anywhere but '
                'api.anthropic.com.',
            hint: 'sk-ant-...',
            slot: _KeySlot.anthropic,
          ),
          SizedBox(height: 28),
          _KeySection(
            title: 'Google Cloud API key',
            description:
                'Used for listening audio (Text-to-Speech). Stored in the iOS '
                'Keychain, never sent anywhere but texttospeech.googleapis.com.',
            hint: 'AIza...',
            slot: _KeySlot.google,
          ),
        ],
      ),
    );
  }
}

enum _KeySlot { anthropic, google }

class _KeySection extends ConsumerStatefulWidget {
  const _KeySection({
    required this.title,
    required this.description,
    required this.hint,
    required this.slot,
  });

  final String title;
  final String description;
  final String hint;
  final _KeySlot slot;

  @override
  ConsumerState<_KeySection> createState() => _KeySectionState();
}

class _KeySectionState extends ConsumerState<_KeySection> {
  final _controller = TextEditingController();
  bool _obscure = true;
  String? _error;

  StateNotifierProvider<ApiKeyNotifier, ApiKeyState> get _provider =>
      switch (widget.slot) {
        _KeySlot.anthropic => apiKeyProvider,
        _KeySlot.google => googleApiKeyProvider,
      };

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(_provider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(widget.title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 4),
        Text(widget.description, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 20),
        if (state.isLoading)
          const Center(
              child: Padding(
            padding: EdgeInsets.all(8),
            child: CircularProgressIndicator(),
          ))
        else if (state.hasKey)
          _KeySetCard(keyValue: state.key!)
        else
          TextField(
            controller: _controller,
            obscureText: _obscure,
            autocorrect: false,
            enableSuggestions: false,
            decoration: InputDecoration(
              labelText: 'API key',
              hintText: widget.hint,
              errorText: _error,
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: Icon(_obscure
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
          ),
        if (!state.isLoading) ...[
          const SizedBox(height: 12),
          if (state.hasKey)
            OutlinedButton.icon(
              onPressed: () async {
                await ref.read(_provider.notifier).clear();
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
                await ref.read(_provider.notifier).save(value);
                _controller.clear();
              },
              icon: const Icon(Icons.save_outlined),
              label: const Text('Save key'),
            ),
        ],
      ],
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
                const Text('Key saved',
                    style: TextStyle(
                        fontWeight: FontWeight.w500, color: Colors.green)),
                Text(_masked,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: Colors.green)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
