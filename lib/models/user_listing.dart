import 'package:cloud_firestore/cloud_firestore.dart';

/// A merchandise listing a user has added to their profile.
///
/// Mirrors the shape seeded products already use, so a product created in-app
/// and one from `seed/` are indistinguishable. [sellerId] is what ties it to a
/// user; it is a plain string rather than a DocumentReference because the
/// seeded documents store it that way and mixing the two would need a
/// migration plus a second query.
class ProductListing {
  const ProductListing({
    required this.id,
    required this.name,
    required this.price,
    this.description = '',
    this.imageUrl = '',
    this.category = '',
    this.currency = 'USD',
    this.brand = '',
    this.stockQuantity = 0,
    this.isAvailable = true,
    this.rating = 0.0,
    this.reviewsCount = 0,
    this.size = '',
    this.color = '',
    this.sellerId = '',
    this.createdAt,
  });

  final String id;
  final String name;
  final String description;
  final String imageUrl;
  final String category;
  final double price;
  final String currency;
  final String brand;
  final int stockQuantity;
  final bool isAvailable;
  final double rating;
  final int reviewsCount;
  final String size;
  final String color;
  final String sellerId;
  final DateTime? createdAt;

  factory ProductListing.fromFirestore(String id, Map<String, dynamic> data) {
    return ProductListing(
      id: id,
      name: data['name']?.toString() ?? '',
      description: data['description']?.toString() ?? '',
      imageUrl: data['imageUrl']?.toString() ?? '',
      category: data['category']?.toString() ?? '',
      price: (data['price'] as num?)?.toDouble() ?? 0,
      currency: data['currency']?.toString() ?? 'USD',
      brand: data['brand']?.toString() ?? '',
      stockQuantity: (data['stockQuantity'] as num?)?.toInt() ?? 0,
      isAvailable: data['isAvailable'] as bool? ?? true,
      rating: (data['rating'] as num?)?.toDouble() ?? 0,
      reviewsCount: (data['reviewsCount'] as num?)?.toInt() ?? 0,
      size: data['size']?.toString() ?? '',
      color: data['color']?.toString() ?? '',
      sellerId: data['sellerId']?.toString() ?? '',
      createdAt: _toDate(data['createdAt']),
    );
  }

  /// Every field the seeded products carry, so an in-app product is the same
  /// shape as a seeded one and the shop screen needs no special case.
  Map<String, dynamic> toJson() => {
        'name': name,
        'description': description,
        'imageUrl': imageUrl,
        'images': <String>[if (imageUrl.isNotEmpty) imageUrl],
        'category': category,
        'price': price,
        'currency': currency,
        'stockQuantity': stockQuantity,
        'size': size,
        'color': color,
        'brand': brand,
        'rating': rating,
        'reviewsCount': reviewsCount,
        'sellerId': sellerId,
        'isAvailable': isAvailable,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

  static DateTime? _toDate(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }

  /// Returns a copy attributed to [sellerId].
  ///
  /// The uid is set at write time by the service rather than trusted from the
  /// form, so a user cannot list merchandise under someone else's name.
  ProductListing copyWith({String? sellerId}) => ProductListing(
        id: id,
        name: name,
        description: description,
        imageUrl: imageUrl,
        category: category,
        price: price,
        currency: currency,
        brand: brand,
        stockQuantity: stockQuantity,
        isAvailable: isAvailable,
        rating: rating,
        reviewsCount: reviewsCount,
        size: size,
        color: color,
        sellerId: sellerId ?? this.sellerId,
        createdAt: createdAt,
      );

  /// "3 in cart" style label, so the confirmation names the quantity.
  String quantityIn(int quantity) =>
      quantity == 1 ? name : '$quantity x $name';
}

/// An event a user has created, shown on their profile.
///
/// Mirrors the seeded `events` shape, with [organizerId] carrying the owner's
/// uid - again a string, matching the seeded documents.
class EventListing {
  const EventListing({
    required this.id,
    required this.title,
    this.description = '',
    this.imageUrl = '',
    this.category = '',
    this.location = '',
    this.eventDate,
    this.startTime = '',
    this.endTime = '',
    this.organizer = '',
    this.organizerId = '',
    this.ticketPrice = 0,
    this.ticketUrl = '',
    this.status = 'upcoming',
    this.capacity = 0,
    this.attendeesCount = 0,
    this.latitude,
    this.longitude,
  });

  final String id;
  final String title;
  final String description;
  final String imageUrl;
  final String category;
  final String location;
  final DateTime? eventDate;
  final String startTime;
  final String endTime;
  final String organizer;
  final String organizerId;
  final double ticketPrice;
  final String ticketUrl;
  final String status;
  final int capacity;
  final int attendeesCount;

  /// Resolved coordinates for [location], or null when the venue has not been
  /// geocoded yet.
  ///
  /// Added after the original 17 fields, so these are the first genuinely
  /// optional ones on the model. The seeded events all have a `location` and
  /// none of them had coordinates; `EventGeocodingService` fills them in on
  /// demand. Both are nullable together - a document with only one of the pair
  /// is treated as unresolved rather than plotted at 0,0 in the Gulf of Guinea.
  final double? latitude;
  final double? longitude;

  /// True when this event has coordinates a map can centre on.
  bool get hasCoordinates => latitude != null && longitude != null;

  /// True when the venue is one that cannot be plotted.
  ///
  /// Online events ("Online / Discord") are in the seed data with a real
  /// [location] string, so a non-empty location is not evidence that there is
  /// anywhere to point at.
  bool get isOnline => _onlinePattern.hasMatch(location.trim());

  static final RegExp _onlinePattern = RegExp(
    r'^\s*(online|virtual|remote|discord|zoom|twitch|stream)\b',
    caseSensitive: false,
  );

  factory EventListing.fromFirestore(String id, Map<String, dynamic> data) {
    return EventListing(
      id: id,
      title: data['title']?.toString() ?? '',
      description: data['description']?.toString() ?? '',
      imageUrl: data['imageUrl']?.toString() ?? '',
      category: data['category']?.toString() ?? '',
      location: data['location']?.toString() ?? '',
      eventDate: _toDate(data['eventDate']),
      startTime: data['startTime']?.toString() ?? '',
      endTime: data['endTime']?.toString() ?? '',
      organizer: data['organizer']?.toString() ?? '',
      organizerId: data['organizerId']?.toString() ?? '',
      ticketPrice: (data['ticketPrice'] as num?)?.toDouble() ?? 0,
      ticketUrl: data['ticketUrl']?.toString() ?? '',
      status: data['status']?.toString() ?? 'upcoming',
      capacity: (data['capacity'] as num?)?.toInt() ?? 0,
      attendeesCount: (data['attendeesCount'] as num?)?.toInt() ?? 0,
      latitude: (data['latitude'] as num?)?.toDouble(),
      longitude: (data['longitude'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'title': title,
        'description': description,
        'imageUrl': imageUrl,
        'category': category,
        'location': location,
        'eventDate': eventDate == null ? FieldValue.serverTimestamp() : Timestamp.fromDate(eventDate!),
        'startTime': startTime,
        'endTime': endTime,
        'organizer': organizer,
        'organizerId': organizerId,
        'ticketPrice': ticketPrice,
        'ticketUrl': ticketUrl,
        'status': status,
        'capacity': capacity,
        'attendeesCount': attendeesCount,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

  /// [toJson] plus the resolved coordinates.
  ///
  /// Separate from [toJson] on purpose: writing a location is not the same as
  /// asserting a coordinate, and a caller that geocoding failed for must not
  /// write two nulls over a pair that is already good. Only ever call this
  /// once both values are known.
  Map<String, dynamic> toJsonWithCoordinates() => {
        ...toJson(),
        'latitude': latitude,
        'longitude': longitude,
      };

  /// Returns a copy with resolved coordinates attached.
  ///
  /// Separate from [copyWith] because [copyWith] exists to attribute an event
  /// to its organiser at write time, and widening it to cover every field would
  /// invite a call site to quietly change a date or a price. This one only ever
  /// moves the coordinate pair.
  EventListing copyWithResolvedCoordinates({
    required double? latitude,
    required double? longitude,
  }) =>
      EventListing(
        id: id,
        title: title,
        description: description,
        imageUrl: imageUrl,
        category: category,
        location: location,
        eventDate: eventDate,
        startTime: startTime,
        endTime: endTime,
        organizer: organizer,
        organizerId: organizerId,
        ticketPrice: ticketPrice,
        ticketUrl: ticketUrl,
        status: status,
        capacity: capacity,
        attendeesCount: attendeesCount,
        latitude: latitude,
        longitude: longitude,
      );

  static DateTime? _toDate(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }

  /// Returns a copy attributed to [organizerId], set by the service at write
  /// time so an event cannot be published under someone else's name.
  EventListing copyWith({String? organizerId}) => EventListing(
        id: id,
        title: title,
        description: description,
        imageUrl: imageUrl,
        category: category,
        location: location,
        eventDate: eventDate,
        startTime: startTime,
        endTime: endTime,
        organizer: organizer,
        organizerId: organizerId ?? this.organizerId,
        ticketPrice: ticketPrice,
        ticketUrl: ticketUrl,
        status: status,
        capacity: capacity,
        attendeesCount: attendeesCount,
        latitude: latitude,
        longitude: longitude,
      );
}
