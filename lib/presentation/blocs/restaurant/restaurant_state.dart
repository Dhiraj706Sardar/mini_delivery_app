import 'package:equatable/equatable.dart';
import '../../../data/models/restaurant.dart';

/// Base class for all restaurant-related states
abstract class RestaurantState extends Equatable {
  const RestaurantState();

  @override
  List<Object?> get props => [];
}

/// Initial state when the bloc is first created
class RestaurantInitial extends RestaurantState {
  const RestaurantInitial();
}

/// State when restaurants are being loaded
class RestaurantLoading extends RestaurantState {
  const RestaurantLoading();
}

/// State when restaurants have been successfully loaded
class RestaurantLoaded extends RestaurantState {
  final List<Restaurant> restaurants;
  final Restaurant? selectedRestaurant;

  const RestaurantLoaded({
    required this.restaurants,
    this.selectedRestaurant,
  });

  @override
  List<Object?> get props => [restaurants, selectedRestaurant];

  /// Create a copy of this state with updated values
  RestaurantLoaded copyWith({
    List<Restaurant>? restaurants,
    Restaurant? selectedRestaurant,
  }) {
    return RestaurantLoaded(
      restaurants: restaurants ?? this.restaurants,
      selectedRestaurant: selectedRestaurant ?? this.selectedRestaurant,
    );
  }
}

/// State when an error occurs while loading restaurants
class RestaurantError extends RestaurantState {
  final String message;

  const RestaurantError(this.message);

  @override
  List<Object?> get props => [message];
}