import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/repositories/restaurant_repository.dart';
import '../../../core/errors/failures.dart';
import '../../../data/models/menu_item.dart';
import 'menu_event.dart';
import 'menu_state.dart';

/// BLoC for managing menu-related state and business logic
class MenuBloc extends Bloc<MenuEvent, MenuState> {
  final RestaurantRepository _restaurantRepository;

  MenuBloc({
    required RestaurantRepository restaurantRepository,
  })  : _restaurantRepository = restaurantRepository,
        super(const MenuInitial()) {
    on<LoadMenu>(_onLoadMenu);
    on<RefreshMenu>(_onRefreshMenu);
    on<ClearMenu>(_onClearMenu);
  }

  /// Handles the LoadMenu event
  Future<void> _onLoadMenu(
    LoadMenu event,
    Emitter<MenuState> emit,
  ) async {
    if (event.restaurantId.isEmpty) {
      emit(const MenuError('Restaurant ID cannot be empty'));
      return;
    }

    emit(MenuLoading(event.restaurantId));

    try {
      final menuItems = await _restaurantRepository.getMenuItems(event.restaurantId);
      final categorizedItems = _categorizeMenuItems(menuItems);
      
      emit(MenuLoaded(
        restaurantId: event.restaurantId,
        menuItems: menuItems,
        categorizedItems: categorizedItems,
      ));
    } catch (error) {
      final errorMessage = _getErrorMessage(error);
      emit(MenuError(errorMessage, restaurantId: event.restaurantId));
    }
  }

  /// Handles the RefreshMenu event
  Future<void> _onRefreshMenu(
    RefreshMenu event,
    Emitter<MenuState> emit,
  ) async {
    if (event.restaurantId.isEmpty) {
      emit(const MenuError('Restaurant ID cannot be empty'));
      return;
    }

    emit(MenuLoading(event.restaurantId));

    try {
      final menuItems = await _restaurantRepository.getMenuItems(event.restaurantId);
      final categorizedItems = _categorizeMenuItems(menuItems);
      
      emit(MenuLoaded(
        restaurantId: event.restaurantId,
        menuItems: menuItems,
        categorizedItems: categorizedItems,
      ));
    } catch (error) {
      final errorMessage = _getErrorMessage(error);
      emit(MenuError(errorMessage, restaurantId: event.restaurantId));
    }
  }

  /// Handles the ClearMenu event
  void _onClearMenu(
    ClearMenu event,
    Emitter<MenuState> emit,
  ) {
    emit(const MenuInitial());
  }

  /// Categorizes menu items by their category
  Map<String, List<MenuItem>> _categorizeMenuItems(List<MenuItem> menuItems) {
    final Map<String, List<MenuItem>> categorized = {};
    
    for (final item in menuItems) {
      final category = item.category.isEmpty ? 'Other' : item.category;
      
      if (categorized.containsKey(category)) {
        categorized[category]!.add(item);
      } else {
        categorized[category] = [item];
      }
    }
    
    // Sort items within each category by name
    for (final category in categorized.keys) {
      categorized[category]!.sort((a, b) => a.itemName.compareTo(b.itemName));
    }
    
    return categorized;
  }

  /// Converts various error types to user-friendly error messages
  String _getErrorMessage(dynamic error) {
    if (error is NetworkFailure) {
      return 'No internet connection. Please check your network and try again.';
    } else if (error is ServerFailure) {
      return 'Server error occurred. Please try again later.';
    } else if (error is UnknownFailure) {
      return error.message.isNotEmpty 
          ? error.message 
          : 'An unexpected error occurred. Please try again.';
    } else {
      return 'An unexpected error occurred. Please try again.';
    }
  }
}