import '../models/cart_item.dart';
import 'cart_persistence_datasource.dart';

/// Mock implementation of CartPersistenceDataSource for development/testing
class MockCartPersistenceDataSource implements CartPersistenceDataSource {
  List<CartItem> _cartItems = [];
  String? _currentRestaurantId;

  @override
  Future<List<CartItem>> loadCartItems() async {
    return List.from(_cartItems);
  }

  @override
  Future<void> saveCartItems(List<CartItem> items) async {
    _cartItems = List.from(items);
  }

  @override
  Future<void> clearCart() async {
    _cartItems.clear();
    _currentRestaurantId = null;
  }

  @override
  Future<String?> getCurrentRestaurantId() async {
    return _currentRestaurantId;
  }

  @override
  Future<void> saveCurrentRestaurantId(String? restaurantId) async {
    _currentRestaurantId = restaurantId;
  }
}