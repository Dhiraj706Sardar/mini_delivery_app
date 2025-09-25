import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/menu_item.dart';
import '../../core/theme/app_theme.dart';
import '../blocs/cart/cart_bloc.dart';
import '../blocs/cart/cart_event.dart';
import '../blocs/cart/cart_state.dart';
import 'enhanced_image.dart';

/// A card widget that displays a menu item with add to cart functionality
class MenuItemCard extends StatefulWidget {
  final MenuItem menuItem;
  final String restaurantId;
  final VoidCallback? onAddToCart;

  const MenuItemCard({
    super.key,
    required this.menuItem,
    required this.restaurantId,
    this.onAddToCart,
  });

  @override
  State<MenuItemCard> createState() => _MenuItemCardState();
}

class _MenuItemCardState extends State<MenuItemCard> {
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppTheme.spaceMd,
        vertical: AppTheme.spaceXs,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spaceMd),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Menu item image
            ClipRRect(
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              child: EnhancedImage(
                imageUrl: widget.menuItem.imageUrl,
                width: 80,
                height: 80,
                fit: BoxFit.cover,
              ),
            ),
            
            const SizedBox(width: AppTheme.spaceMd),
            
            // Menu item details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.menuItem.itemName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  const SizedBox(height: AppTheme.spaceXs),
                  
                  if (widget.menuItem.itemDescription.isNotEmpty)
                    Text(
                      widget.menuItem.itemDescription,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  
                  const SizedBox(height: AppTheme.spaceSm),
                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '₹${widget.menuItem.itemPrice.toStringAsFixed(2)}',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      
                      BlocBuilder<CartBloc, CartState>(
                        builder: (context, state) {
                          int quantity = 0;
                          if (state is CartUpdated) {
                            try {
                              final cartItem = state.items.firstWhere(
                                (item) => item.menuItem.id == widget.menuItem.id,
                              );
                              quantity = cartItem.quantity;
                            } catch (e) {
                              quantity = 0;
                            }
                          }
                          
                          return _buildQuantityControls(quantity);
                        },
                      ),
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

  Widget _buildQuantityControls(int quantity) {
    if (quantity == 0) {
      return ElevatedButton(
        onPressed: _addToCart,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spaceMd,
            vertical: AppTheme.spaceXs,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          ),
        ),
        child: const Text('Add'),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.primaryColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: _removeFromCart,
            icon: const Icon(Icons.remove, color: Colors.white, size: 18),
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            padding: EdgeInsets.zero,
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceXs),
            child: Text(
              quantity.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          IconButton(
            onPressed: _addToCart,
            icon: const Icon(Icons.add, color: Colors.white, size: 18),
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  void _addToCart() {
    context.read<CartBloc>().add(
      AddToCart(
        menuItem: widget.menuItem,
        restaurantId: widget.restaurantId,
      ),
    );
    widget.onAddToCart?.call();
  }

  void _removeFromCart() {
    context.read<CartBloc>().add(
      RemoveFromCart(widget.menuItem.id),
    );
  }
}