import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/cart/cart_bloc.dart';
import '../blocs/cart/cart_state.dart';
import '../blocs/cart/cart_event.dart';
import '../blocs/order/order_bloc.dart';
import '../blocs/order/order_event.dart';
import '../blocs/order/order_state.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/cart_item.dart';
import '../../core/navigation/app_router.dart';

/// Screen for order checkout with order summary and confirmation
class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  @override
  void initState() {
    super.initState();
    // Load cart when screen is first created
    context.read<CartBloc>().add(const LoadCart());
    
    // Validate cart for checkout
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _validateCheckoutAccess();
    });
  }

  void _validateCheckoutAccess() async {
    // Simple validation - can be enhanced later if needed
    final cartState = context.read<CartBloc>().state;
    if (cartState is! CartUpdated || cartState.isEmpty) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: BlocListener<OrderBloc, OrderState>(
        listener: (context, state) {
          if (state is OrderSuccess) {
            // Navigate to order confirmation screen
            Navigator.of(context).pushReplacementNamed(
              AppRoutes.orderConfirmation,
              arguments: OrderConfirmationArguments(order: state.order),
            );
          } else if (state is OrderError) {
            // Navigate to order failure screen
            final cartState = context.read<CartBloc>().state;
            if (cartState is CartUpdated && cartState.hasItems) {
              Navigator.of(context).pushNamed(
                AppRoutes.orderFailure,
                arguments: OrderFailureArguments(
                  errorMessage: state.message,
                  errorCode: state.errorCode,
                  canRetry: state.canRetry,
                  cartItems: cartState.items,
                  restaurantId: cartState.currentRestaurantId!,
                ),
              );
            } else {
              // Fallback to snackbar if cart state is not available
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: AppTheme.errorColor,
                ),
              );
            }
          }
        },
        child: BlocBuilder<CartBloc, CartState>(
          builder: (context, cartState) {
            return BlocBuilder<OrderBloc, OrderState>(
              builder: (context, orderState) {
                return _buildBody(cartState, orderState);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildBody(CartState cartState, OrderState orderState) {
    if (cartState is CartLoading) {
      return _buildLoadingState('Loading your cart...');
    } else if (cartState is CartUpdated) {
      if (cartState.isEmpty) {
        return _buildEmptyCartState();
      } else {
        return _buildCheckoutContent(cartState, orderState);
      }
    } else if (cartState is CartError) {
      return _buildErrorState(cartState.message, _retryLoadCart);
    } else {
      return _buildLoadingState('Preparing checkout...');
    }
  }

  Widget _buildCheckoutContent(CartUpdated cartState, OrderState orderState) {
    
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Order Items Section
                _buildOrderItemsSection(cartState),
                
                const SizedBox(height: 24),
                
                // Delivery Information Section
                _buildDeliveryInfoSection(),
                
                const SizedBox(height: 24),
                
                // Payment Method Section
                _buildPaymentMethodSection(),
                
                const SizedBox(height: 24),
                
                // Order Summary Section
                _buildOrderSummarySection(cartState),
              ],
            ),
          ),
        ),
        
        // Place Order Button
        _buildPlaceOrderButton(cartState, orderState),
      ],
    );
  }

  Widget _buildOrderItemsSection(CartUpdated cartState) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.restaurant_menu, color: AppTheme.primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Order Items',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // List of cart items
            ...cartState.items.map((item) => _buildOrderItemRow(item)),
            
            const Divider(height: 24),
            
            // Total items count
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Items',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textSecondary,
                  ),
                ),
                Text(
                  '${cartState.totalItems}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderItemRow(CartItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          // Item image
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              item.menuItem.imageUrl,
              width: 50,
              height: 50,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.fastfood,
                    color: AppTheme.textLight,
                    size: 24,
                  ),
                );
              },
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Item details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.menuItem.itemName,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Qty: ${item.quantity}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          
          // Item total price
          Text(
            '\$${item.totalPrice.toStringAsFixed(2)}',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryInfoSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.location_on, color: AppTheme.primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Delivery Information',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Delivery address (mock data)
            _buildInfoRow(
              'Address',
              '123 Main Street, Apt 4B\nNew York, NY 10001',
            ),
            
            const SizedBox(height: 12),
            
            // Delivery time estimate
            _buildInfoRow(
              'Estimated Delivery',
              '25-35 minutes',
            ),
            
            const SizedBox(height: 12),
            
            // Delivery instructions
            _buildInfoRow(
              'Instructions',
              'Leave at door, ring bell',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.payment, color: AppTheme.primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Payment Method',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Payment method (mock data)
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.credit_card,
                    color: AppTheme.primaryColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Credit Card',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '**** **** **** 1234',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () {
                    // In a real app, this would open payment method selection
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Payment method selection not implemented in demo'),
                      ),
                    );
                  },
                  child: const Text('Change'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderSummarySection(CartUpdated cartState) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.receipt, color: AppTheme.primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Order Summary',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Subtotal
            _buildSummaryRow(
              'Subtotal',
              '\$${cartState.subtotal.toStringAsFixed(2)}',
            ),
            
            // Delivery fee
            _buildSummaryRow(
              'Delivery Fee',
              cartState.deliveryFee > 0
                  ? '\$${cartState.deliveryFee.toStringAsFixed(2)}'
                  : 'FREE',
              valueColor: cartState.deliveryFee == 0
                  ? AppTheme.secondaryColor
                  : null,
            ),
            
            // Tax
            _buildSummaryRow(
              'Tax & Fees',
              '\$${cartState.tax.toStringAsFixed(2)}',
            ),
            
            const Divider(height: 24, thickness: 1),
            
            // Total
            _buildSummaryRow(
              'Total',
              '\$${cartState.total.toStringAsFixed(2)}',
              isTotal: true,
            ),
            
            // Free delivery message
            if (cartState.deliveryFee == 0 && cartState.subtotal >= 25.0)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.secondaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.local_shipping,
                        size: 20,
                        color: AppTheme.secondaryColor,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'You saved \$2.99 on delivery!',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.secondaryColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(
    String label,
    String value, {
    bool isTotal = false,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.textSecondary,
              fontWeight: isTotal ? FontWeight.w600 : FontWeight.normal,
              fontSize: isTotal ? 16 : 14,
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: valueColor ??
                  (isTotal ? AppTheme.textPrimary : AppTheme.textSecondary),
              fontWeight: isTotal ? FontWeight.w700 : FontWeight.w500,
              fontSize: isTotal ? 18 : 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceOrderButton(CartUpdated cartState, OrderState orderState) {
    final isProcessing = orderState is OrderProcessing || orderState is OrderValidating;
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Order processing status
              if (isProcessing)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _getProcessingMessage(orderState),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              
              // Place order button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: (!isProcessing && cartState.hasItems) 
                      ? () => _placeOrder(cartState) 
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 2,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (isProcessing) ...[
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      Text(
                        isProcessing ? 'Processing...' : 'Place Order',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (!isProcessing) ...[
                        const SizedBox(width: 8),
                        Text(
                          '\$${cartState.total.toStringAsFixed(2)}',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: AppTheme.primaryColor),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyCartState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_cart_outlined,
              size: 80,
              color: AppTheme.textLight,
            ),
            const SizedBox(height: 24),
            Text(
              'Your cart is empty',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Add some items to your cart before checkout.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => Navigator.of(context).pushReplacementNamed(AppRoutes.restaurants),
              icon: const Icon(Icons.restaurant_menu),
              label: const Text('Browse Restaurants'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String message, VoidCallback onRetry) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: AppTheme.errorColor),
            const SizedBox(height: 16),
            Text(
              'Something went wrong',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getProcessingMessage(OrderState orderState) {
    if (orderState is OrderValidating) {
      return 'Validating your order...';
    } else if (orderState is OrderProcessing) {
      return orderState.message ?? 'Processing your order...';
    }
    return 'Processing...';
  }

  // Event handlers
  void _placeOrder(CartUpdated cartState) {
    if (cartState.currentRestaurantId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to place order: Invalid restaurant selection'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    context.read<OrderBloc>().add(PlaceOrder(
      cartItems: cartState.items,
      restaurantId: cartState.currentRestaurantId!,
      deliveryFee: cartState.deliveryFee,
      taxRate: 0.08, // 8% tax rate
    ));
  }

  void _retryOrder() {
    final cartState = context.read<CartBloc>().state;
    if (cartState is CartUpdated && cartState.hasItems) {
      _placeOrder(cartState);
    }
  }

  void _retryLoadCart() {
    context.read<CartBloc>().add(const LoadCart());
  }
}