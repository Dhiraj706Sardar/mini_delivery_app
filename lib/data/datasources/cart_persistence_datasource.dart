import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/cart_item.dart';

/// Data source for persisting cart data locally
abstract class CartPersistenceDataSource {
  Future<List<CartItem>> loadCartItems();
  Future<void> saveCartItems(List<CartItem> items);
  Future<void> clearCart();
  Future<String?> getCurrentRestaurantId();
  Future<void> saveCurrentRestaurantId(String? restaurantId);
}

/// Implementation of cart persistence using SharedPreferences
class CartPersistenceDataSourceImpl implements CartPersistenceDataSource {
  static const String _cartItemsKey = 'cart_items';
  static const String _currentRestaurantIdKey = 'current_restaurant_id';

  final SharedPreferences _prefs;

  CartPersistenceDataSourceImpl({
    required SharedPreferences prefs,
  }) : _prefs = prefs;

  @override
  Future<List<CartItem>> loadCartItems() async {
    try {
      final cartItemsJson = _prefs.getString(_cartItemsKey);
      
      if (cartItemsJson == null || cartItemsJson.isEmpty) {
        return [];
      }

      final List<dynamic> cartItemsList = json.decode(cartItemsJson);
      
      return cartItemsList
          .map((item) => CartItem.fromJson(item as Map<String, dynamic>))
          .where((item) => item.isValid) // Filter out invalid items
          .toList();
    } catch (error) {
      // If there's an error loading cart items, return empty list
      // and clear the corrupted data
      await clearCart();
      return [];
    }
  }

  @override
  Future<void> saveCartItems(List<CartItem> items) async {
    try {
      // Filter out invalid items before saving
      final validItems = items.where((item) => item.isValid).toList();
      
      final cartItemsJson = json.encode(
        validItems.map((item) => item.toJson()).toList(),
      );
      
      await _prefs.setString(_cartItemsKey, cartItemsJson);
    } catch (error) {
      // If there's an error saving, clear the cart to prevent corruption
      await clearCart();
      rethrow;
    }
  }

  @override
  Future<void> clearCart() async {
    try {
      await _prefs.remove(_cartItemsKey);
      await _prefs.remove(_currentRestaurantIdKey);
    } catch (error) {
      // Even if clearing fails, we should not throw an error
      // as this could prevent the app from functioning
    }
  }

  @override
  Future<String?> getCurrentRestaurantId() async {
    try {
      return _prefs.getString(_currentRestaurantIdKey);
    } catch (error) {
      return null;
    }
  }

  @override
  Future<void> saveCurrentRestaurantId(String? restaurantId) async {
    try {
      if (restaurantId == null) {
        await _prefs.remove(_currentRestaurantIdKey);
      } else {
        await _prefs.setString(_currentRestaurantIdKey, restaurantId);
      }
    } catch (error) {
      // If saving restaurant ID fails, we can continue without it
      // as it's not critical for cart functionality
    }
  }
}