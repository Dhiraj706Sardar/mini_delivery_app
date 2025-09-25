import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/repositories/restaurant_repository.dart';
import '../../../core/errors/failures.dart';
import '../../../data/models/restaurant.dart';
import 'restaurant_event.dart';
import 'restaurant_state.dart';

/// BLoC for managing restaurant-related state and business logic
class RestaurantBloc extends Bloc<RestaurantEvent, RestaurantState> {
  final RestaurantRepository _restaurantRepository;

  RestaurantBloc({
    required RestaurantRepository restaurantRepository,
  })  : _restaurantRepository = restaurantRepository,
        super(const RestaurantInitial()) {
    on<LoadRestaurants>(_onLoadRestaurants);
    on<SelectRestaurant>(_onSelectRestaurant);
    on<RefreshRestaurants>(_onRefreshRestaurants);
  }

  /// Handles the LoadRestaurants event
  Future<void> _onLoadRestaurants(
    LoadRestaurants event,
    Emitter<RestaurantState> emit,
  ) async {
    emit(const RestaurantLoading());

    try {
      final restaurants = await _restaurantRepository.getRestaurants();
      emit(RestaurantLoaded(restaurants: restaurants));
    } catch (error) {
      final errorMessage = _getErrorMessage(error);
      emit(RestaurantError(errorMessage));
    }
  }

  /// Handles the SelectRestaurant event
  Future<void> _onSelectRestaurant(
    SelectRestaurant event,
    Emitter<RestaurantState> emit,
  ) async {
    final currentState = state;
    
    if (currentState is RestaurantLoaded) {
      try {
        // Find the selected restaurant from the current list
        final selectedRestaurant = currentState.restaurants.firstWhere(
          (restaurant) => restaurant.id == event.restaurantId,
        );
        
        emit(currentState.copyWith(selectedRestaurant: selectedRestaurant));
      } catch (error) {
        // If restaurant not found in current list, try to fetch it
        try {
          final selectedRestaurant = await _restaurantRepository.getRestaurantById(event.restaurantId);
          emit(currentState.copyWith(selectedRestaurant: selectedRestaurant));
        } catch (fetchError) {
          final errorMessage = _getErrorMessage(fetchError);
          emit(RestaurantError(errorMessage));
        }
      }
    } else {
      // If restaurants are not loaded yet, load them first and then select
      add(const LoadRestaurants());
      // The selection will need to be handled after restaurants are loaded
      // This could be improved with a more sophisticated state management approach
    }
  }

  /// Handles the RefreshRestaurants event
  Future<void> _onRefreshRestaurants(
    RefreshRestaurants event,
    Emitter<RestaurantState> emit,
  ) async {
    final currentState = state;
    Restaurant? selectedRestaurant;
    
    // Preserve selected restaurant if available
    if (currentState is RestaurantLoaded) {
      selectedRestaurant = currentState.selectedRestaurant;
    }

    emit(const RestaurantLoading());

    try {
      final restaurants = await _restaurantRepository.getRestaurants();
      
      // Try to maintain the selected restaurant if it still exists
      if (selectedRestaurant != null) {
        try {
          final updatedSelectedRestaurant = restaurants.firstWhere(
            (restaurant) => restaurant.id == selectedRestaurant!.id,
          );
          emit(RestaurantLoaded(
            restaurants: restaurants,
            selectedRestaurant: updatedSelectedRestaurant,
          ));
        } catch (_) {
          // Selected restaurant no longer exists, clear selection
          emit(RestaurantLoaded(restaurants: restaurants));
        }
      } else {
        emit(RestaurantLoaded(restaurants: restaurants));
      }
    } catch (error) {
      final errorMessage = _getErrorMessage(error);
      emit(RestaurantError(errorMessage));
    }
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