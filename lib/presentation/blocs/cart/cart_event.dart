import 'package:equatable/equatable.dart';
import '../../../data/models/menu_item.dart';

/// Base class for all cart-related events
abstract class CartEvent extends Equatable {
  const CartEvent();

  @override
  List<Object?> get props => [];
}

/// Event to add an item to the cart
class AddToCart extends CartEvent {
  final MenuItem menuItem;
  final String restaurantId;
  final int quantity;

  const AddToCart({
    required this.menuItem,
    required this.restaurantId,
    this.quantity = 1,
  });

  @override
  List<Object?> get props => [menuItem, restaurantId, quantity];
}

/// Event to remove an item from the cart completely
class RemoveFromCart extends CartEvent {
  final String menuItemId;

  const RemoveFromCart(this.menuItemId);

  @override
  List<Object?> get props => [menuItemId];
}

/// Event to update the quantity of an item in the cart
class UpdateQuantity extends CartEvent {
  final String menuItemId;
  final int quantity;

  const UpdateQuantity({
    required this.menuItemId,
    required this.quantity,
  });

  @override
  List<Object?> get props => [menuItemId, quantity];
}

/// Event to clear all items from the cart
class ClearCart extends CartEvent {
  const ClearCart();
}

/// Event to load cart from persistent storage
class LoadCart extends CartEvent {
  const LoadCart();
}

/// Event to save cart to persistent storage
class SaveCart extends CartEvent {
  const SaveCart();
}