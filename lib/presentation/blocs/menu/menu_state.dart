import 'package:equatable/equatable.dart';
import '../../../data/models/menu_item.dart';

/// Base class for all menu-related states
abstract class MenuState extends Equatable {
  const MenuState();

  @override
  List<Object?> get props => [];
  
}

/// Initial state when the bloc is first created
class MenuInitial extends MenuState {
  const MenuInitial();
}

/// State when menu items are being loaded
class MenuLoading extends MenuState {
  final String restaurantId;

  const MenuLoading(this.restaurantId);

  @override
  List<Object?> get props => [restaurantId];
}

/// State when menu items have been successfully loaded
class MenuLoaded extends MenuState {
  final String restaurantId;
  final List<MenuItem> menuItems;
  final Map<String, List<MenuItem>> categorizedItems;

  const MenuLoaded({
    required this.restaurantId,
    required this.menuItems,
    required this.categorizedItems,
  });

  @override
  List<Object?> get props => [restaurantId, menuItems, categorizedItems];

  /// Create a copy of this state with updated values
  MenuLoaded copyWith({
    String? restaurantId,
    List<MenuItem>? menuItems,
    Map<String, List<MenuItem>>? categorizedItems,
  }) {
    return MenuLoaded(
      restaurantId: restaurantId ?? this.restaurantId,
      menuItems: menuItems ?? this.menuItems,
      categorizedItems: categorizedItems ?? this.categorizedItems,
    );
  }

  /// Get all unique categories from menu items
  List<String> get categories => categorizedItems.keys.toList()..sort();

  /// Check if menu has any items
  bool get hasItems => menuItems.isNotEmpty;

  /// Get items for a specific category
  List<MenuItem> getItemsForCategory(String category) {
    return categorizedItems[category] ?? [];
  }
}

/// State when an error occurs while loading menu items
class MenuError extends MenuState {
  final String message;
  final String? restaurantId;

  const MenuError(this.message, {this.restaurantId});

  @override
  List<Object?> get props => [message, restaurantId];
}