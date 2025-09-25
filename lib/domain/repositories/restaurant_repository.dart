import '../../data/models/restaurant.dart';
import '../../data/models/menu_item.dart';

/// Abstract repository interface for restaurant-related operations
/// 
/// This interface defines the contract for restaurant data access,
/// following the repository pattern to abstract data sources and
/// enable easy testing and dependency injection.
abstract class RestaurantRepository {
  /// Fetches a list of all available restaurants
  /// 
  /// Returns a [Future] that completes with a [List<Restaurant>]
  /// Throws [NetworkFailure] if there's a network connectivity issue
  /// Throws [ServerFailure] if the server returns an error response
  /// Throws [UnknownFailure] for any other unexpected errors
  Future<List<Restaurant>> getRestaurants();

  /// Fetches menu items for a specific restaurant
  /// 
  /// [restaurantId] - The unique identifier of the restaurant
  /// Returns a [Future] that completes with a [List<MenuItem>]
  /// Throws [NetworkFailure] if there's a network connectivity issue
  /// Throws [ServerFailure] if the server returns an error response
  /// Throws [UnknownFailure] for any other unexpected errors
  Future<List<MenuItem>> getMenuItems(String restaurantId);

  /// Fetches a specific restaurant by its ID
  /// 
  /// [restaurantId] - The unique identifier of the restaurant
  /// Returns a [Future] that completes with a [Restaurant] object
  /// Throws [NetworkFailure] if there's a network connectivity issue
  /// Throws [ServerFailure] if the server returns an error response
  /// Throws [UnknownFailure] for any other unexpected errors
  Future<Restaurant> getRestaurantById(String restaurantId);
}