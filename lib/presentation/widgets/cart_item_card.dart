import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../data/models/cart_item.dart';
import '../blocs/cart/cart_bloc.dart';
import '../blocs/cart/cart_event.dart';

/// Widget that displays a cart item with image, details, and quantity controls
class CartItemCard extends StatelessWidget {
  final CartItem cartItem;
  final VoidCallback? onRemove;

  const CartItemCard({
    super.key,
    required this.cartItem,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Menu item image
            _buildItemImage(context),
            const SizedBox(width: 12),
            
            // Item details and controls
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Item name and remove button
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          cartItem.menuItem.itemName,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      _buildRemoveButton(context),
                    ],
                  ),
                  
                  const SizedBox(height: 4),
                  
                  // Item description
                  if (cartItem.menuItem.itemDescription.isNotEmpty)
                    Text(
                      cartItem.menuItem.itemDescription,
                      style: theme.textTheme.bodyMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  
                  const SizedBox(height: 8),
                  
                  // Price and quantity controls
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Price information
                      _buildPriceInfo(context),
                      
                      // Quantity controls
                      _buildQuantityControls(context),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the menu item image with placeholder and error handling
  Widget _buildItemImage(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 80,
        height: 80,
        child: cartItem.menuItem.imageUrl.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: cartItem.menuItem.imageUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: Colors.grey[200],
                  child: const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  color: Colors.grey[200],
                  child: const Icon(
                    Icons.restaurant,
                    color: Colors.grey,
                    size: 32,
                  ),
                ),
              )
            : Container(
                color: Colors.grey[200],
                child: const Icon(
                  Icons.restaurant,
                  color: Colors.grey,
                  size: 32,
                ),
              ),
      ),
    );
  }

  /// Builds the remove button
  Widget _buildRemoveButton(BuildContext context) {
    return IconButton(
      onPressed: () {
        _showRemoveConfirmation(context);
      },
      icon: const Icon(Icons.close),
      iconSize: 20,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(
        minWidth: 24,
        minHeight: 24,
      ),
      tooltip: 'Remove item',
    );
  }

  /// Builds the price information display
  Widget _buildPriceInfo(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Unit price
        Text(
          '\$${cartItem.menuItem.itemPrice.toStringAsFixed(2)} each',
          style: theme.textTheme.bodySmall,
        ),
        
        const SizedBox(height: 2),
        
        // Total price for this item
        Text(
          '\$${cartItem.totalPrice.toStringAsFixed(2)}',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.primary,
          ),
        ),
      ],
    );
  }

  /// Builds the quantity controls (decrease, quantity, increase)
  Widget _buildQuantityControls(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Decrease quantity button
          _buildQuantityButton(
            context,
            icon: Icons.remove,
            onPressed: cartItem.quantity > 1
                ? () => _updateQuantity(context, cartItem.quantity - 1)
                : null,
          ),
          
          // Quantity display
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              cartItem.quantity.toString(),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          
          // Increase quantity button
          _buildQuantityButton(
            context,
            icon: Icons.add,
            onPressed: cartItem.quantity < 10 // Max quantity limit
                ? () => _updateQuantity(context, cartItem.quantity + 1)
                : null,
          ),
        ],
      ),
    );
  }

  /// Builds individual quantity control buttons
  Widget _buildQuantityButton(
    BuildContext context, {
    required IconData icon,
    required VoidCallback? onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.all(8),
        child: Icon(
          icon,
          size: 18,
          color: onPressed != null
              ? Theme.of(context).colorScheme.primary
              : Colors.grey,
        ),
      ),
    );
  }

  /// Updates the quantity of the cart item
  void _updateQuantity(BuildContext context, int newQuantity) {
    if (newQuantity <= 0) {
      _showRemoveConfirmation(context);
      return;
    }
    
    context.read<CartBloc>().add(
      UpdateQuantity(
        menuItemId: cartItem.menuItem.id,
        quantity: newQuantity,
      ),
    );
  }

  /// Shows confirmation dialog before removing item
  void _showRemoveConfirmation(BuildContext context) {
    showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Remove Item'),
          content: Text(
            'Are you sure you want to remove "${cartItem.menuItem.itemName}" from your cart?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
                _removeItem(context);
              },
              child: const Text('Remove'),
            ),
          ],
        );
      },
    );
  }

  /// Removes the item from cart
  void _removeItem(BuildContext context) {
    context.read<CartBloc>().add(
      RemoveFromCart(cartItem.menuItem.id),
    );
    
    // Call optional callback
    onRemove?.call();
    
    // Show snackbar confirmation
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${cartItem.menuItem.itemName} removed from cart'),
        duration: const Duration(seconds: 2),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            // Re-add the item to cart
            context.read<CartBloc>().add(
              AddToCart(
                menuItem: cartItem.menuItem,
                restaurantId: cartItem.restaurantId,
                quantity: cartItem.quantity,
              ),
            );
          },
        ),
      ),
    );
  }
}