import 'package:flutter/material.dart';

import '../services/ai_assistant_service.dart';
import '../services/auth_service.dart';

const _ink = Color(0xFF30251E);
const _muted = Color(0xFF81766E);
const _orange = Color(0xFFF47B20);
const _border = Color(0xFFF0E8DF);

const _examplePrompts = [
  'Something sour and soupy',
  'Sweet merienda under ₱100',
  'Grilled pork with rice',
  'Pang-almusal na tinapay',
];

/// Lets signed-in customers describe a craving and get dishes from the menus.
class AiAssistantPage extends StatefulWidget {
  const AiAssistantPage({
    super.key,
    required this.service,
    required this.user,
    required this.onSignIn,
    required this.onVerifyEmail,
    required this.onAddToCart,
    required this.onOpenCart,
  });

  final AiAssistantService? service;
  final AuthUser? user;
  final VoidCallback onSignIn;
  final VoidCallback onVerifyEmail;

  /// Returns false when the dish can no longer be found on the menu.
  final Future<bool> Function(MenuSuggestion suggestion) onAddToCart;
  final VoidCallback onOpenCart;

  @override
  State<AiAssistantPage> createState() => _AiAssistantPageState();
}

class _AiAssistantPageState extends State<AiAssistantPage> {
  final _query = TextEditingController();
  final _added = <String>{};
  MenuAssistantAnswer? _answer;
  String? _error;
  bool _loading = false;

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  Future<void> _ask() async {
    final query = _query.text.trim();
    final service = widget.service;
    if (query.length < 2) {
      setState(() => _error = 'Tell the assistant what you are craving.');
      return;
    }
    if (service == null) {
      setState(
        () => _error = 'Firebase must be configured to use the food assistant.',
      );
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final answer = await service.suggestDishes(query);
      if (!mounted) return;
      setState(() {
        _answer = answer;
        _added.clear();
      });
    } on AiAssistantFailure catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _add(MenuSuggestion suggestion) async {
    final added = await widget.onAddToCart(suggestion);
    if (!mounted) return;
    if (added) {
      setState(
        () => _added.add('${suggestion.restaurantId}/${suggestion.itemId}'),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This dish is no longer on the menu.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    key: const Key('assistant-page'),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 860),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 32, 22, 50),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.auto_awesome_rounded, color: _orange, size: 30),
                  SizedBox(width: 10),
                  Text(
                    'Food assistant',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: _ink,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Describe a craving, budget or mood and get dishes from the menus on Food-Pandas.',
              ),
              const SizedBox(height: 20),
              ..._body(),
              const SizedBox(height: 24),
              const Text(
                'AI suggestions can be wrong. Check the menu, price and allergens before ordering.',
                key: Key('assistant-disclaimer'),
                style: TextStyle(color: _muted, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  List<Widget> _body() {
    final user = widget.user;
    if (user == null) {
      return [
        _Notice(
          message: 'Sign in to ask the food assistant.',
          action: FilledButton(
            key: const Key('assistant-sign-in'),
            onPressed: widget.onSignIn,
            child: const Text('Sign in'),
          ),
        ),
      ];
    }
    if (!user.emailVerified) {
      return [
        _Notice(
          message: 'Verify your email to use the food assistant.',
          action: FilledButton(
            key: const Key('assistant-verify-email'),
            onPressed: widget.onVerifyEmail,
            child: const Text('Verify email'),
          ),
        ),
      ];
    }
    final answer = _answer;
    return [
      TextField(
        key: const Key('assistant-query'),
        controller: _query,
        maxLength: FirebaseAiAssistantService.maxQueryLength,
        minLines: 1,
        maxLines: 3,
        textInputAction: TextInputAction.search,
        onSubmitted: (_) => _ask(),
        decoration: const InputDecoration(
          hintText: 'e.g. Something sour and soupy under ₱200',
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(),
        ),
      ),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final prompt in _examplePrompts)
            ActionChip(
              label: Text(prompt),
              onPressed: _loading
                  ? null
                  : () {
                      _query.text = prompt;
                      _ask();
                    },
            ),
        ],
      ),
      const SizedBox(height: 16),
      FilledButton.icon(
        key: const Key('assistant-ask'),
        onPressed: _loading ? null : _ask,
        icon: const Icon(Icons.auto_awesome_rounded),
        label: Text(_loading ? 'Thinking…' : 'Ask the assistant'),
      ),
      if (_loading) ...[
        const SizedBox(height: 16),
        const LinearProgressIndicator(),
      ],
      if (_error != null) ...[
        const SizedBox(height: 16),
        Text(
          _error!,
          key: const Key('assistant-error'),
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
      ],
      if (answer != null) ...[
        const SizedBox(height: 24),
        Text(
          answer.summary,
          key: const Key('assistant-summary'),
          style: const TextStyle(color: _ink, fontSize: 16, height: 1.4),
        ),
        const SizedBox(height: 12),
        for (final suggestion in answer.suggestions)
          _SuggestionCard(
            suggestion: suggestion,
            added: _added.contains(
              '${suggestion.restaurantId}/${suggestion.itemId}',
            ),
            onAdd: () => _add(suggestion),
            onOpenCart: widget.onOpenCart,
          ),
        if (answer.remainingToday != null)
          Text(
            '${answer.remainingToday} assistant requests left today.',
            style: const TextStyle(color: _muted, fontSize: 12),
          ),
      ],
    ];
  }
}

class _Notice extends StatelessWidget {
  const _Notice({required this.message, required this.action});
  final String message;
  final Widget action;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: _border),
    ),
    child: Row(
      children: [
        Expanded(
          child: Text(
            message,
            style: const TextStyle(color: _ink, fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(width: 12),
        action,
      ],
    ),
  );
}

class _SuggestionCard extends StatelessWidget {
  const _SuggestionCard({
    required this.suggestion,
    required this.added,
    required this.onAdd,
    required this.onOpenCart,
  });

  final MenuSuggestion suggestion;
  final bool added;
  final VoidCallback onAdd;
  final VoidCallback onOpenCart;

  @override
  Widget build(BuildContext context) {
    final id = '${suggestion.restaurantId}-${suggestion.itemId}';
    return Container(
      key: Key('assistant-suggestion-$id'),
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      suggestion.name,
                      style: const TextStyle(
                        color: _ink,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    if (suggestion.isSample)
                      const Chip(
                        label: Text('Sample menu'),
                        visualDensity: VisualDensity.compact,
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${suggestion.restaurantName} · ₱${suggestion.price.toStringAsFixed(0)}',
                  style: const TextStyle(color: _muted, fontSize: 13),
                ),
                if (suggestion.reason.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(suggestion.reason, style: const TextStyle(color: _ink)),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          added
              ? TextButton.icon(
                  key: Key('assistant-view-cart-$id'),
                  onPressed: onOpenCart,
                  icon: const Icon(Icons.check_rounded),
                  label: const Text('View cart'),
                )
              : OutlinedButton.icon(
                  key: Key('assistant-add-$id'),
                  onPressed: onAdd,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Add'),
                ),
        ],
      ),
    );
  }
}
