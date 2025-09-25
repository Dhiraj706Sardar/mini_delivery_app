import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/order/order_bloc.dart';
import '../blocs/order/order_event.dart';
import '../blocs/order/order_state.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/cart_item.dart';
import '../../core/navigation/app_router.dart';
import 'order_confirmation_screen.dart';

/// Screen displayed when order placement fails, with retry options
class OrderFailureScreen extends StatefulWidget {
  final String errorMessage;
  final String? errorCode;
  final bool canRetry;
  final List<CartItem> cartItems;
  final String restaurantId;

  const OrderFailureScreen({
    super.key,
    required this.errorMessage,
    this.errorCode,
    required this.canRetry,
    required this.cartItems,
    required this.restaurantId,
  });

  @override
  State<OrderFailureScreen> createState() => _OrderFailureScreenState();
}

class _OrderFailureScreenState extends State<OrderFailureScreen>
    with TickerProviderStateMixin {
  late AnimationController _errorIconController;
  late AnimationController _contentController;
  late Animation<double> _errorIconAnimation;
  late Animation<double> _contentAnimation;

  @override
  void initState() {
    super.initState();
    
    // Initialize animations
    _errorIconController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _contentController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _errorIconAnimation = CurvedAnimation(
      parent: _errorIconController,
      curve: Curves.elasticOut,
    );
    
    _contentAnimation = CurvedAnimation(
      parent: _contentController,
      curve: Curves.easeInOut,
    );
    
    // Start animations
    _errorIconController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _contentController.forward();
      }
    });
  }

  @override
  void dispose() {
    _errorIconController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Order Failed'),
        backgroundColor: AppTheme.errorColor,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: BlocListener<OrderBloc, OrderState>(
        listener: (context, state) {
          if (state is OrderSuccess) {
            // Navigate to order confirmation screen
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => OrderConfirmationScreen(order: state.order),
              ),
            );
          } else if (state is OrderError) {
            // Show error message
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppTheme.errorColor,
                action: state.canRetry
                    ? SnackBarAction(
                        label: 'Retry',
                        textColor: Colors.white,
                        onPressed: _retryOrder,
                      )
                    : null,
              ),
            );
          }
        },
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      const SizedBox(height: 40),
                      
                      // Error animation and message
                      _buildErrorHeader(),
                      
                      const SizedBox(height: 40),
                      
                      // Error details card
                      FadeTransition(
                        opacity: _contentAnimation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, 0.3),
                            end: Offset.zero,
                          ).animate(_contentAnimation),
                          child: _buildErrorDetailsCard(),
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Cart preservation notice
                      FadeTransition(
                        opacity: _contentAnimation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, 0.3),
                            end: Offset.zero,
                          ).animate(_contentAnimation),
                          child: _buildCartPreservationCard(),
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Troubleshooting tips
                      FadeTransition(
                        opacity: _contentAnimation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, 0.3),
                            end: Offset.zero,
                          ).animate(_contentAnimation),
                          child: _buildTroubleshootingCard(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Bottom action buttons
              FadeTransition(
                opacity: _contentAnimation,
                child: _buildBottomActions(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorHeader() {
    return Column(
      children: [
        // Animated error icon
        ScaleTransition(
          scale: _errorIconAnimation,
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppTheme.errorColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.errorColor.withValues(alpha: 0.3),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: const Icon(
              Icons.error_outline,
              color: Colors.white,
              size: 50,
            ),
          ),
        ),
        
        const SizedBox(height: 24),
        
        // Error message
        FadeTransition(
          opacity: _contentAnimation,
          child: Column(
            children: [
              Text(
                'Order Failed',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 8),
              
              Text(
                'We couldn\'t process your order',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppTheme.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildErrorDetailsCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: AppTheme.errorColor,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Error Details',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Error message
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.errorColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppTheme.errorColor.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber,
                    color: AppTheme.errorColor,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.errorMessage,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Error code if available
            if (widget.errorCode != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(
                    'Error Code: ',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    widget.errorCode!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textPrimary,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ],
            
            // Retry availability
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: widget.canRetry
                    ? AppTheme.secondaryColor.withValues(alpha: 0.1)
                    : AppTheme.textLight.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    widget.canRetry ? Icons.refresh : Icons.block,
                    color: widget.canRetry
                        ? AppTheme.secondaryColor
                        : AppTheme.textSecondary,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.canRetry
                          ? 'You can retry placing this order'
                          : 'This order cannot be retried automatically',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: widget.canRetry
                            ? AppTheme.secondaryColor
                            : AppTheme.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartPreservationCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.shopping_cart,
                  color: AppTheme.primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Your Cart is Safe',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Cart preservation message
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.secondaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: AppTheme.secondaryColor,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Don\'t worry! Your cart items have been preserved. You can retry your order or continue shopping.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Cart summary
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Items in cart:',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
                Text(
                  '${widget.cartItems.fold<int>(0, (sum, item) => sum + item.quantity)} items',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Cart total:',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
                Text(
                  '\$${widget.cartItems.fold<double>(0.0, (sum, item) => sum + item.totalPrice).toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTroubleshootingCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.help_outline,
                  color: AppTheme.primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Troubleshooting Tips',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Troubleshooting tips
            ..._getTroubleshootingTips().map((tip) => _buildTipRow(tip)),
          ],
        ),
      ),
    );
  }

  Widget _buildTipRow(String tip) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(top: 8, right: 12),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Text(
              tip,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActions() {
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
          child: BlocBuilder<OrderBloc, OrderState>(
            builder: (context, orderState) {
              final isProcessing = orderState is OrderProcessing || orderState is OrderValidating;
              
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Retry order button (if retry is possible)
                  if (widget.canRetry) ...[
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: isProcessing ? null : _retryOrder,
                        icon: isProcessing
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.refresh),
                        label: Text(isProcessing ? 'Retrying...' : 'Retry Order'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 2,
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 12),
                  ],
                  
                  // Back to cart button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _backToCart,
                      icon: const Icon(Icons.shopping_cart),
                      label: const Text('Back to Cart'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.primaryColor,
                        side: BorderSide(color: AppTheme.primaryColor),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Continue shopping button
                  SizedBox(
                    width: double.infinity,
                    child: TextButton.icon(
                      onPressed: _continueShopping,
                      icon: const Icon(Icons.restaurant_menu),
                      label: const Text('Continue Shopping'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppTheme.textSecondary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  // Helper methods
  List<String> _getTroubleshootingTips() {
    return [
      'Check your internet connection and try again',
      'Ensure your payment method is valid and has sufficient funds',
      'Verify that the restaurant is still accepting orders',
      'Try placing a smaller order if the cart total is very high',
      'Clear the app cache and restart if the problem persists',
    ];
  }

  // Event handlers
  void _retryOrder() {
    if (!widget.canRetry) return;
    
    context.read<OrderBloc>().add(RetryOrder(
      cartItems: widget.cartItems,
      restaurantId: widget.restaurantId,
      deliveryFee: 2.99,
      taxRate: 0.08,
    ));
  }

  void _backToCart() {
    Navigator.of(context).pop();
  }

  void _continueShopping() {
    Navigator.of(context).pushNamedAndRemoveUntil(
      AppRoutes.restaurants,
      (route) => false,
    );
  }
}