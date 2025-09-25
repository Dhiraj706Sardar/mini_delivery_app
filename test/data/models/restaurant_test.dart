import 'package:flutter_test/flutter_test.dart';
import 'package:deliery_app/data/models/restaurant.dart';

void main() {
  group('Restaurant Model', () {
    const testRestaurant = Restaurant(
      id: '1',
      name: 'Test Restaurant',
      rating: 4.5,
      address: '123 Test Street',
      cuisineType: 'Italian',
      imageUrl: 'https://example.com/image.jpg',
      description: 'A great test restaurant',
    );

    const testJson = {
      'id': '1',
      'name': 'Test Restaurant',
      'rating': 4.5,
      'address': '123 Test Street',
      'cuisineType': 'Italian',
      'imageUrl': 'https://example.com/image.jpg',
      'description': 'A great test restaurant',
    };

    group('JSON Serialization', () {
      test('should create Restaurant from valid JSON', () {
        // Act
        final restaurant = Restaurant.fromJson(testJson);

        // Assert
        expect(restaurant.id, '1');
        expect(restaurant.name, 'Test Restaurant');
        expect(restaurant.rating, 4.5);
        expect(restaurant.address, '123 Test Street');
        expect(restaurant.cuisineType, 'Italian');
        expect(restaurant.imageUrl, 'https://example.com/image.jpg');
        expect(restaurant.description, 'A great test restaurant');
      });

      test('should handle null values in JSON gracefully', () {
        // Arrange
        const nullJson = {
          'id': null,
          'name': null,
          'rating': null,
          'address': null,
          'cuisineType': null,
          'imageUrl': null,
          'description': null,
        };

        // Act
        final restaurant = Restaurant.fromJson(nullJson);

        // Assert
        expect(restaurant.id, '');
        expect(restaurant.name, '');
        expect(restaurant.rating, 0.0);
        expect(restaurant.address, '');
        expect(restaurant.cuisineType, '');
        expect(restaurant.imageUrl, '');
        expect(restaurant.description, '');
      });

      test('should convert Restaurant to JSON correctly', () {
        // Act
        final json = testRestaurant.toJson();

        // Assert
        expect(json, testJson);
      });

      test('should handle integer rating in JSON', () {
        // Arrange
        const jsonWithIntRating = {
          'id': '1',
          'name': 'Test Restaurant',
          'rating': 4,
          'address': '123 Test Street',
          'cuisineType': 'Italian',
          'imageUrl': 'https://example.com/image.jpg',
          'description': 'A great test restaurant',
        };

        // Act
        final restaurant = Restaurant.fromJson(jsonWithIntRating);

        // Assert
        expect(restaurant.rating, 4.0);
      });
    });

    group('Validation', () {
      test('should return true for valid restaurant', () {
        // Assert
        expect(testRestaurant.isValid, true);
      });

      test('should return false for restaurant with empty id', () {
        // Arrange
        final invalidRestaurant = testRestaurant.copyWith(id: '');

        // Assert
        expect(invalidRestaurant.isValid, false);
      });

      test('should return false for restaurant with empty name', () {
        // Arrange
        final invalidRestaurant = testRestaurant.copyWith(name: '');

        // Assert
        expect(invalidRestaurant.isValid, false);
      });

      test('should return false for restaurant with invalid rating', () {
        // Arrange
        final invalidRestaurant1 = testRestaurant.copyWith(rating: -1.0);
        final invalidRestaurant2 = testRestaurant.copyWith(rating: 6.0);

        // Assert
        expect(invalidRestaurant1.isValid, false);
        expect(invalidRestaurant2.isValid, false);
      });

      test('should return false for restaurant with empty address', () {
        // Arrange
        final invalidRestaurant = testRestaurant.copyWith(address: '');

        // Assert
        expect(invalidRestaurant.isValid, false);
      });

      test('should return false for restaurant with empty cuisine type', () {
        // Arrange
        final invalidRestaurant = testRestaurant.copyWith(cuisineType: '');

        // Assert
        expect(invalidRestaurant.isValid, false);
      });
    });

    group('Equality', () {
      test('should be equal when all properties are the same', () {
        // Arrange
        const restaurant1 = Restaurant(
          id: '1',
          name: 'Test Restaurant',
          rating: 4.5,
          address: '123 Test Street',
          cuisineType: 'Italian',
          imageUrl: 'https://example.com/image.jpg',
          description: 'A great test restaurant',
        );

        const restaurant2 = Restaurant(
          id: '1',
          name: 'Test Restaurant',
          rating: 4.5,
          address: '123 Test Street',
          cuisineType: 'Italian',
          imageUrl: 'https://example.com/image.jpg',
          description: 'A great test restaurant',
        );

        // Assert
        expect(restaurant1, restaurant2);
        expect(restaurant1.hashCode, restaurant2.hashCode);
      });

      test('should not be equal when properties differ', () {
        // Arrange
        final restaurant2 = testRestaurant.copyWith(name: 'Different Restaurant');

        // Assert
        expect(testRestaurant, isNot(restaurant2));
      });
    });

    group('CopyWith', () {
      test('should create new instance with updated properties', () {
        // Act
        final updatedRestaurant = testRestaurant.copyWith(
          name: 'Updated Restaurant',
          rating: 5.0,
        );

        // Assert
        expect(updatedRestaurant.name, 'Updated Restaurant');
        expect(updatedRestaurant.rating, 5.0);
        expect(updatedRestaurant.id, testRestaurant.id);
        expect(updatedRestaurant.address, testRestaurant.address);
      });

      test('should keep original values when no parameters provided', () {
        // Act
        final copiedRestaurant = testRestaurant.copyWith();

        // Assert
        expect(copiedRestaurant, testRestaurant);
      });
    });

    group('ToString', () {
      test('should return formatted string representation', () {
        // Act
        final stringRepresentation = testRestaurant.toString();

        // Assert
        expect(stringRepresentation, contains('Restaurant('));
        expect(stringRepresentation, contains('id: 1'));
        expect(stringRepresentation, contains('name: Test Restaurant'));
        expect(stringRepresentation, contains('rating: 4.5'));
      });
    });
  });
}