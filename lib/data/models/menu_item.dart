import 'package:equatable/equatable.dart';

class MenuItem extends Equatable {
  final String id;
  final String itemName;
  final String itemDescription;
  final double itemPrice;
  final String imageUrl;
  final String category;

  const MenuItem({
    required this.id,
    required this.itemName,
    required this.itemDescription,
    required this.itemPrice,
    required this.imageUrl,
    required this.category,
  });

  // JSON serialization
  factory MenuItem.fromJson(Map<String, dynamic> json) {
    return MenuItem(
      id: json['itemID']?.toString() ?? '',
      itemName: json['itemName']?.toString() ?? '',
      itemDescription: json['itemDescription']?.toString() ?? '',
      itemPrice: (json['itemPrice'] as num?)?.toDouble() ?? 0.0,
      imageUrl: json['imageUrl']?.toString() ?? '',
      category: json['category']?.toString() ?? 'Main Course', // Default category since API doesn't provide it
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'itemName': itemName,
      'itemDescription': itemDescription,
      'itemPrice': itemPrice,
      'imageUrl': imageUrl,
      'category': category,
    };
  }

  // Validation
  bool get isValid {
    return id.isNotEmpty &&
        itemName.isNotEmpty &&
        itemDescription.isNotEmpty &&
        itemPrice > 0.0 &&
        category.isNotEmpty;
  }

  // Copy with method for immutability
  MenuItem copyWith({
    String? id,
    String? itemName,
    String? itemDescription,
    double? itemPrice,
    String? imageUrl,
    String? category,
  }) {
    return MenuItem(
      id: id ?? this.id,
      itemName: itemName ?? this.itemName,
      itemDescription: itemDescription ?? this.itemDescription,
      itemPrice: itemPrice ?? this.itemPrice,
      imageUrl: imageUrl ?? this.imageUrl,
      category: category ?? this.category,
    );
  }

  @override
  List<Object?> get props => [
        id,
        itemName,
        itemDescription,
        itemPrice,
        imageUrl,
        category,
      ];

  @override
  String toString() {
    return 'MenuItem(id: $id, itemName: $itemName, itemDescription: $itemDescription, itemPrice: $itemPrice, imageUrl: $imageUrl, category: $category)';
  }
}