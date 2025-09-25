import 'package:equatable/equatable.dart';

/// Base class for all menu-related events
abstract class MenuEvent extends Equatable {
  const MenuEvent();

  @override
  List<Object?> get props => [];
}

/// Event to load menu items for a specific restaurant
class LoadMenu extends MenuEvent {
  final String restaurantId;

  const LoadMenu(this.restaurantId);

  @override
  List<Object?> get props => [restaurantId];
}

/// Event to refresh menu items for the current restaurant
class RefreshMenu extends MenuEvent {
  final String restaurantId;

  const RefreshMenu(this.restaurantId);

  @override
  List<Object?> get props => [restaurantId];
}

/// Event to clear the current menu (when navigating away from restaurant)
class ClearMenu extends MenuEvent {
  const ClearMenu();
}