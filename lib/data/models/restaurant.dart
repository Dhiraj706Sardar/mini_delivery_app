import 'package:equatable/equatable.dart';

class Restaurant extends Equatable {
  final String id;
  final String name;
  final double rating;
  final String address;
  final String cuisineType;
  final String imageUrl;
  final String description;

  const Restaurant({
    required this.id,
    required this.name,
    required this.rating,
    required this.address,
    required this.cuisineType,
    required this.imageUrl,
    required this.description,
  });

  // JSON serialization
  factory Restaurant.fromJson(Map<String, dynamic> json) {
    return Restaurant(
      id: json['restaurantID']?.toString() ?? '',
      name: json['restaurantName']?.toString() ?? '',
      rating:
          (json['rating'] as num?)?.toDouble() ??
          4.0, // Default rating since API doesn't provide it
      address: json['address']?.toString() ?? '',
      cuisineType: json['type']?.toString() ?? '',
      imageUrl:
          json['imageUrl']?.toString() ??
          "https://t3.ftcdn.net/jpg/03/24/73/92/360_F_324739203_keeq8udvv0P2h1MLYJ0GLSlTBagoXS48.jpg", // Default image when API doesn't provide it
      description:
          json['description']?.toString() ??
          '', // Default empty since API doesn't provide it
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'rating': rating,
      'address': address,
      'cuisineType': cuisineType,
      'imageUrl': imageUrl,
      'description': description,
    };
  }

  // Validation
  bool get isValid {
    return id.isNotEmpty &&
        name.isNotEmpty &&
        rating >= 0.0 &&
        rating <= 5.0 &&
        address.isNotEmpty &&
        cuisineType.isNotEmpty;
  }

  // Copy with method for immutability
  Restaurant copyWith({
    String? id,
    String? name,
    double? rating,
    String? address,
    String? cuisineType,
    String? imageUrl,
    String? description,
  }) {
    return Restaurant(
      id: id ?? this.id,
      name: name ?? this.name,
      rating: rating ?? this.rating,
      address: address ?? this.address,
      cuisineType: cuisineType ?? this.cuisineType,
      imageUrl: imageUrl ?? this.imageUrl,
      description: description ?? this.description,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    rating,
    address,
    cuisineType,
    imageUrl,
    description,
  ];

  @override
  String toString() {
    return 'Restaurant(id: $id, name: $name, rating: $rating, address: $address, cuisineType: $cuisineType, imageUrl: $imageUrl, description: $description)';
  }
}
