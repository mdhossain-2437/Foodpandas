import 'package:cloud_functions/cloud_functions.dart';

/// A dish recommended by the AI menu assistant. Name and price come from the
/// server-side catalog, not from the model.
class MenuSuggestion {
  const MenuSuggestion({
    required this.restaurantId,
    required this.itemId,
    required this.name,
    required this.restaurantName,
    required this.price,
    required this.reason,
    required this.isSample,
  });

  final String restaurantId;
  final String itemId;
  final String name;
  final String restaurantName;
  final double price;
  final String reason;

  /// True for preview stalls that never create a real order.
  final bool isSample;

  static MenuSuggestion? tryParse(Object? value) {
    if (value is! Map) return null;
    final restaurantId = value['restaurantId'];
    final itemId = value['itemId'];
    final name = value['name'];
    final price = value['price'];
    if (restaurantId is! String ||
        itemId is! String ||
        name is! String ||
        price is! num) {
      return null;
    }
    return MenuSuggestion(
      restaurantId: restaurantId,
      itemId: itemId,
      name: name,
      restaurantName: value['restaurantName'] as String? ?? '',
      price: price.toDouble(),
      reason: value['reason'] as String? ?? '',
      isSample: value['sample'] == true,
    );
  }
}

class MenuAssistantAnswer {
  const MenuAssistantAnswer({
    required this.summary,
    required this.suggestions,
    this.remainingToday,
  });

  final String summary;
  final List<MenuSuggestion> suggestions;
  final int? remainingToday;
}

abstract interface class AiAssistantService {
  Future<MenuAssistantAnswer> suggestDishes(String query);
}

class FirebaseAiAssistantService implements AiAssistantService {
  FirebaseAiAssistantService({FirebaseFunctions? functions})
    : _configuredFunctions = functions;

  /// Mirrors MAX_QUERY_LENGTH in functions/ai/menu-assistant.js.
  static const maxQueryLength = 300;

  final FirebaseFunctions? _configuredFunctions;
  FirebaseFunctions get _functions =>
      _configuredFunctions ?? FirebaseFunctions.instance;

  @override
  Future<MenuAssistantAnswer> suggestDishes(String query) async {
    try {
      final result = await _functions
          .httpsCallable(
            'menuAssistant',
            options: HttpsCallableOptions(timeout: const Duration(seconds: 70)),
          )
          .call({'query': query});
      final data = result.data;
      final summary = data is Map ? data['summary'] : null;
      final suggestions = data is Map ? data['suggestions'] : null;
      if (summary is! String || suggestions is! List) {
        throw const AiAssistantFailure(
          'The food assistant returned an unexpected answer. Try again.',
        );
      }
      final remaining = (data as Map)['remainingToday'];
      return MenuAssistantAnswer(
        summary: summary,
        suggestions: suggestions
            .map(MenuSuggestion.tryParse)
            .nonNulls
            .toList(growable: false),
        remainingToday: remaining is num ? remaining.toInt() : null,
      );
    } on FirebaseFunctionsException catch (error) {
      throw AiAssistantFailure(_message(error));
    }
  }

  String _message(FirebaseFunctionsException error) => switch (error.code) {
    'deadline-exceeded' =>
      'The food assistant took too long to answer. Try again.',
    'internal' || 'unknown' =>
      'The food assistant is unavailable right now. Try again later.',
    _ =>
      error.message ?? 'The food assistant could not answer (${error.code}).',
  };
}

class AiAssistantFailure implements Exception {
  const AiAssistantFailure(this.message);
  final String message;

  @override
  String toString() => message;
}
