import 'package:intl/intl.dart';

// ==================== EVENT MODEL ====================

class Event {
  final int id;
  final String name;
  final DateTime date;
  final String location;
  final int capacity;
  final double price;
  final String description;
  final int ticketsSold;
  final String? imageUrl;
  final String? category;

  Event({
    required this.id,
    required this.name,
    required this.date,
    required this.location,
    required this.capacity,
    required this.price,
    required this.description,
    this.ticketsSold = 0,
    this.imageUrl,
    this.category,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'date': date.toIso8601String(),
        'location': location,
        'capacity': capacity,
        'price': price,
        'description': description,
        'ticketsSold': ticketsSold,
        'imageUrl': imageUrl,
        'category': category,
      };

  factory Event.fromJson(Map<String, dynamic> json) => Event(
        id: json['id'],
        name: json['name'],
        date: DateTime.parse(json['date']),
        location: json['location'],
        capacity: json['capacity'],
        price: json['price'].toDouble(),
        description: json['description'],
        ticketsSold: json['ticketsSold'] ?? 0,
        imageUrl: json['imageUrl'],
        category: json['category'],
      );

  // Helper methods
  String get formattedDate => DateFormat('dd MMM yyyy, HH:mm').format(date);
  String get formattedPrice => 'Rp ${NumberFormat('#,###').format(price)}';
  int get availableTickets => capacity - ticketsSold;
  bool get isSoldOut => availableTickets <= 0;
  bool get isUpcoming => date.isAfter(DateTime.now());
  double get ticketsSoldPercentage => (ticketsSold / capacity) * 100;

  Event copyWith({
    int? id,
    String? name,
    DateTime? date,
    String? location,
    int? capacity,
    double? price,
    String? description,
    int? ticketsSold,
    String? imageUrl,
    String? category,
  }) {
    return Event(
      id: id ?? this.id,
      name: name ?? this.name,
      date: date ?? this.date,
      location: location ?? this.location,
      capacity: capacity ?? this.capacity,
      price: price ?? this.price,
      description: description ?? this.description,
      ticketsSold: ticketsSold ?? this.ticketsSold,
      imageUrl: imageUrl ?? this.imageUrl,
      category: category ?? this.category,
    );
  }
}

// ==================== TICKET MODEL ====================

class Ticket {
  final int id;
  final int eventId;
  final String code;
  final String buyerName;
  final String buyerEmail;
  final DateTime purchaseDate;
  final bool isScanned;
  final DateTime? scannedAt;
  final String? buyerPhone;
  final int? quantity;

  Ticket({
    required this.id,
    required this.eventId,
    required this.code,
    required this.buyerName,
    required this.buyerEmail,
    required this.purchaseDate,
    this.isScanned = false,
    this.scannedAt,
    this.buyerPhone,
    this.quantity,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'eventId': eventId,
        'code': code,
        'buyerName': buyerName,
        'buyerEmail': buyerEmail,
        'purchaseDate': purchaseDate.toIso8601String(),
        'isScanned': isScanned,
        'scannedAt': scannedAt?.toIso8601String(),
        'buyerPhone': buyerPhone,
        'quantity': quantity,
      };

  factory Ticket.fromJson(Map<String, dynamic> json) => Ticket(
        id: json['id'],
        eventId: json['eventId'],
        code: json['code'],
        buyerName: json['buyerName'],
        buyerEmail: json['buyerEmail'],
        purchaseDate: DateTime.parse(json['purchaseDate']),
        isScanned: json['isScanned'] ?? false,
        scannedAt: json['scannedAt'] != null
            ? DateTime.parse(json['scannedAt'])
            : null,
        buyerPhone: json['buyerPhone'],
        quantity: json['quantity'],
      );

  // Helper methods
  String get formattedPurchaseDate =>
      DateFormat('dd MMM yyyy, HH:mm').format(purchaseDate);
  String get formattedScannedAt => scannedAt != null
      ? DateFormat('dd MMM yyyy, HH:mm').format(scannedAt!)
      : '-';
  String get status => isScanned ? 'Sudah digunakan' : 'Aktif';

  Ticket copyWith({
    int? id,
    int? eventId,
    String? code,
    String? buyerName,
    String? buyerEmail,
    DateTime? purchaseDate,
    bool? isScanned,
    DateTime? scannedAt,
    String? buyerPhone,
    int? quantity,
  }) {
    return Ticket(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      code: code ?? this.code,
      buyerName: buyerName ?? this.buyerName,
      buyerEmail: buyerEmail ?? this.buyerEmail,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      isScanned: isScanned ?? this.isScanned,
      scannedAt: scannedAt ?? this.scannedAt,
      buyerPhone: buyerPhone ?? this.buyerPhone,
      quantity: quantity ?? this.quantity,
    );
  }
}

// ==================== USER MODEL ====================

class User {
  final int id;
  final String name;
  final String email;
  final String password;
  final String? phone;
  final String? profileImage;
  final String role;
  final DateTime? createdAt;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.password,
    this.phone,
    this.profileImage,
    this.role = 'user',
    this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'password': password,
        'phone': phone,
        'profileImage': profileImage,
        'role': role,
        'createdAt': createdAt?.toIso8601String(),
      };

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['id'],
        name: json['name'],
        email: json['email'],
        password: json['password'],
        phone: json['phone'],
        profileImage: json['profileImage'],
        role: json['role'] ?? 'user',
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'])
            : null,
      );

  // Helper methods
  bool get isOrganizer => role == 'organizer' || role == 'admin';
  bool get isAdmin => role == 'admin';

  User copyWith({
    int? id,
    String? name,
    String? email,
    String? password,
    String? phone,
    String? profileImage,
    String? role,
    DateTime? createdAt,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      password: password ?? this.password,
      phone: phone ?? this.phone,
      profileImage: profileImage ?? this.profileImage,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}