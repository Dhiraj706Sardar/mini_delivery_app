import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/cart_item.dart';
import '../../../data/datasources/cart_persistence_datasource.dart';
import 'cart_event.dart';
import 'cart_state.dart';

/// BLoC for managing cart-related state and business logic
class CartBloc extends Bloc<CartEvent, CartState> {
  // Cart configuration constants
  static const double _deliveryFeeRate = 2.99;
  static const double _taxRate = 0.08; // 8% tax
  static const double _freeDeliveryThreshold = 25.0;
  static const int _maxQuantityPerItem = 10; // Maximum quantity per item
  static const int _maxTotalItems = 50; // Maximum total items in cart

  final CartPersistenceDataSource _persistenceDataSource;

  CartBloc({
    required CartPersistenceDataSource persistenceDataSource,
  })  : _persistenceDataSource = persistenceDataSource,
        super(const CartInitial()) {
    on<AddToCart>(_onAddToCart);
    on<RemoveFromCart>(_onRemoveFromCart);
    on<UpdateQuantity>(_onUpdateQuantity);
    on<ClearCart>(_onClearCart);
    on<LoadCart>(_onLoadCart);
    on<SaveCart>(_onSaveCart);
  }

  /// Handles the AddToCart event
  Future<void> _onAddToCart(
    AddToCart event,
    Emitter<CartState> emit,
  ) async {
    try {
      // Validate input
      if (!event.menuItem.isValid) {
        emit(const CartError(message: 'Invalid menu item'));
        return;
      }

      if (event.restaurantId.isEmpty) {
        emit(const CartError(message: 'Restaurant ID cannot be empty'));
        return;
      }

      if (event.quantity <= 0) {
        emit(const CartError(message: 'Quantity must be greater than 0'));
        return;
      }

      if (event.quantity > _maxQuantityPerItem) {
        emit(CartError(message: 'Maximum quantity per item is $_maxQuantityPerItem'));
        return;
      }

      final currentState = state;
      List<CartItem> currentItems = [];
      String? currentRestaurantId;

      // Get current items from state
      if (currentState is CartUpdated) {
        currentItems = List.from(currentState.items);
        currentRestaurantId = currentState.currentRestaurantId;
      }

      // Check if adding from different restaurant
      if (currentRestaurantId != null && 
          currentRestaurantId != event.restaurantId && 
          currentItems.isNotEmpty) {
        emit(const CartError(
          message: 'Cannot add items from different restaurants. Please clear your cart first.',
        ));
        return;
      }

      // Check total items limit
      final currentTotalItems = currentItems.fold<int>(
        0, (sum, item) => sum + item.quantity,
      );
      
      if (currentTotalItems + event.quantity > _maxTotalItems) {
        emit(CartError(message: 'Maximum total items in cart is $_maxTotalItems'));
        return;
      }

      // Check if item already exists in cart
      final existingItemIndex = currentItems.indexWhere(
        (item) => item.menuItem.id == event.menuItem.id,
      );

      if (existingItemIndex != -1) {
        // Update existing item quantity with validation
        final existingItem = currentItems[existingItemIndex];
        final newQuantity = existingItem.quantity + event.quantity;
        
        if (newQuantity > _maxQuantityPerItem) {
          emit(CartError(message: 'Maximum quantity per item is $_maxQuantityPerItem'));
          return;
        }
        
        currentItems[existingItemIndex] = existingItem.copyWith(quantity: newQuantity);
      } else {
        // Add new item to cart
        final newCartItem = CartItem(
          menuItem: event.menuItem,
          quantity: event.quantity,
          restaurantId: event.restaurantId,
        );
        currentItems.add(newCartItem);
      }

      // Calculate totals and emit new state
      final updatedState = _calculateTotals(
        currentItems,
        event.restaurantId,
      );
      emit(updatedState);

      // Save to persistence
      await _saveCartToPersistence(currentItems, event.restaurantId);

    } catch (error) {
      emit(CartError(message: 'Failed to add item to cart: ${error.toString()}'));
    }
  }

  /// Handles the RemoveFromCart event
  Future<void> _onRemoveFromCart(
    RemoveFromCart event,
    Emitter<CartState> emit,
  ) async {
    try {
      final currentState = state;
      if (currentState is! CartUpdated) {
        emit(const CartError(message: 'Cart is not in a valid state'));
        return;
      }

      final currentItems = List<CartItem>.from(currentState.items);
      
      // Remove item from cart
      currentItems.removeWhere((item) => item.menuItem.id == event.menuItemId);

      // If cart is empty, reset restaurant ID
      final restaurantId = currentItems.isEmpty ? null : currentState.currentRestaurantId;

      // Calculate totals and emit new state
      final updatedState = _calculateTotals(currentItems, restaurantId);
      emit(updatedState);

      // Save to persistence
      await _saveCartToPersistence(currentItems, restaurantId);

    } catch (error) {
      emit(CartError(message: 'Failed to remove item from cart: ${error.toString()}'));
    }
  }

  /// Handles the UpdateQuantity event
  Future<void> _onUpdateQuantity(
    UpdateQuantity event,
    Emitter<CartState> emit,
  ) async {
    try {
      final currentState = state;
      if (currentState is! CartUpdated) {
        emit(const CartError(message: 'Cart is not in a valid state'));
        return;
      }

      if (event.quantity <= 0) {
        // If quantity is 0 or negative, remove the item
        add(RemoveFromCart(event.menuItemId));
        return;
      }

      if (event.quantity > _maxQuantityPerItem) {
        emit(CartError(message: 'Maximum quantity per item is $_maxQuantityPerItem'));
        return;
      }

      final currentItems = List<CartItem>.from(currentState.items);
      
      // Find and update the item
      final itemIndex = currentItems.indexWhere(
        (item) => item.menuItem.id == event.menuItemId,
      );

      if (itemIndex == -1) {
        emit(const CartError(message: 'Item not found in cart'));
        return;
      }

      // Check total items limit
      final otherItemsTotal = currentItems
          .where((item) => item.menuItem.id != event.menuItemId)
          .fold<int>(0, (sum, item) => sum + item.quantity);
      
      if (otherItemsTotal + event.quantity > _maxTotalItems) {
        emit(CartError(message: 'Maximum total items in cart is $_maxTotalItems'));
        return;
      }

      currentItems[itemIndex] = currentItems[itemIndex].copyWith(
        quantity: event.quantity,
      );

      // Calculate totals and emit new state
      final updatedState = _calculateTotals(
        currentItems,
        currentState.currentRestaurantId,
      );
      emit(updatedState);

      // Save to persistence
      await _saveCartToPersistence(currentItems, currentState.currentRestaurantId);

    } catch (error) {
      emit(CartError(message: 'Failed to update item quantity: ${error.toString()}'));
    }
  }

  /// Handles the ClearCart event
  Future<void> _onClearCart(
    ClearCart event,
    Emitter<CartState> emit,
  ) async {
    try {
      emit(_calculateTotals([], null));
      
      // Clear persistence
      await _persistenceDataSource.clearCart();
    } catch (error) {
      emit(CartError(message: 'Failed to clear cart: ${error.toString()}'));
    }
  }

  /// Handles the LoadCart event
  Future<void> _onLoadCart(
    LoadCart event,
    Emitter<CartState> emit,
  ) async {
    emit(const CartLoading());
    
    try {
      // Load cart items from persistence
      final cartItems = await _persistenceDataSource.loadCartItems();
      final restaurantId = await _persistenceDataSource.getCurrentRestaurantId();
      
      // Validate loaded items
      final validItems = _validateAndCleanCartItems(cartItems);
      
      // If items are from different restaurants, clear the cart
      if (_hasMultipleRestaurants(validItems)) {
        await _persistenceDataSource.clearCart();
        emit(_calculateTotals([], null));
        return;
      }
      
      // Calculate totals and emit state
      final updatedState = _calculateTotals(validItems, restaurantId);
      emit(updatedState);
      
    } catch (error) {
      // If loading fails, start with empty cart
      emit(_calculateTotals([], null));
    }
  }

  /// Handles the SaveCart event
  Future<void> _onSaveCart(
    SaveCart event,
    Emitter<CartState> emit,
  ) async {
    try {
      final currentState = state;
      if (currentState is CartUpdated) {
        await _saveCartToPersistence(
          currentState.items,
          currentState.currentRestaurantId,
        );
      }
    } catch (error) {
      emit(CartError(message: 'Failed to save cart: ${error.toString()}'));
    }
  }

  /// Calculates cart totals and returns updated state
  CartUpdated _calculateTotals(List<CartItem> items, String? restaurantId) {
    // Calculate subtotal
    final subtotal = items.fold<double>(
      0.0,
      (sum, item) => sum + item.totalPrice,
    );

    // Calculate delivery fee
    final deliveryFee = subtotal >= _freeDeliveryThreshold ? 0.0 : _deliveryFeeRate;

    // Calculate tax
    final tax = subtotal * _taxRate;

    // Calculate total
    final total = subtotal + deliveryFee + tax;

    // Calculate total items count
    final totalItems = items.fold<int>(
      0,
      (sum, item) => sum + item.quantity,
    );

    return CartUpdated(
      items: items,
      subtotal: subtotal,
      deliveryFee: deliveryFee,
      tax: tax,
      total: total,
      totalItems: totalItems,
      currentRestaurantId: restaurantId,
    );
  }

  /// Saves cart items and restaurant ID to persistence
  Future<void> _saveCartToPersistence(
    List<CartItem> items,
    String? restaurantId,
  ) async {
    try {
      await _persistenceDataSource.saveCartItems(items);
      await _persistenceDataSource.saveCurrentRestaurantId(restaurantId);
    } catch (error) {
      // Log error but don't throw - persistence failure shouldn't break the app
      // In a real app, you might want to use a logging service here
    }
  }

  /// Validates and cleans cart items, removing invalid ones
  List<CartItem> _validateAndCleanCartItems(List<CartItem> items) {
    return items.where((item) {
      // Check if item is valid
      if (!item.isValid) return false;
      
      // Check quantity limits
      if (item.quantity <= 0 || item.quantity > _maxQuantityPerItem) return false;
      
      return true;
    }).toList();
  }

  /// Checks if cart items are from multiple restaurants
  bool _hasMultipleRestaurants(List<CartItem> items) {
    if (items.isEmpty) return false;
    
    final firstRestaurantId = items.first.restaurantId;
    return items.any((item) => item.restaurantId != firstRestaurantId);
  }
}