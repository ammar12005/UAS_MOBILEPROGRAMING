// FILE: lib/models.dart
// Berisi semua model class untuk aplikasi Event Manager Pro

/// Model untuk data User/Pengguna
class User {
  final int id;
  final String name, email, password;
  
  User({
    required this.id,
    required this.name,
    required this.email,
    required this.password,
  });
  
  /// Konversi User ke JSON untuk disimpan di storage
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'password': password,
  };
  
  /// Buat User dari JSON yang diambil dari storage
  factory User.fromJson(Map<String, dynamic> json) => User(
    id: json['id'],
    name: json['name'],
    email: json['email'],
    password: json['password'],
  );
}

/// Model untuk data Event
class Event {
  final int id;
  final String name, location, description;
  final DateTime date;
  final int capacity;
  final double price;
  int ticketsSold;
  
  Event({
    required this.id,
    required this.name,
    required this.date,
    required this.location,
    required this.capacity,
    required this.price,
    required this.description,
    this.ticketsSold = 0,
  });
  
  /// Konversi Event ke JSON untuk disimpan di storage
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'date': date.toIso8601String(),
    'location': location,
    'capacity': capacity,
    'price': price,
    'description': description,
    'ticketsSold': ticketsSold,
  };
  
  /// Buat Event dari JSON yang diambil dari storage
  factory Event.fromJson(Map<String, dynamic> json) => Event(
    id: json['id'],
    name: json['name'],
    date: DateTime.parse(json['date']),
    location: json['location'],
    capacity: json['capacity'],
    price: json['price'].toDouble(),
    description: json['description'],
    ticketsSold: json['ticketsSold'] ?? 0,
  );
}

/// Model untuk data Ticket/Tiket
class Ticket {
  final int id, eventId;
  final String code, buyerName, buyerEmail;
  final DateTime purchaseDate;
  bool isScanned;
  DateTime? scannedAt;
  
  Ticket({
    required this.id,
    required this.eventId,
    required this.code,
    required this.buyerName,
    required this.buyerEmail,
    required this.purchaseDate,
    this.isScanned = false,
    this.scannedAt,
  });
  
  /// Konversi Ticket ke JSON untuk disimpan di storage
  Map<String, dynamic> toJson() => {
    'id': id,
    'eventId': eventId,
    'code': code,
    'buyerName': buyerName,
    'buyerEmail': buyerEmail,
    'purchaseDate': purchaseDate.toIso8601String(),
    'isScanned': isScanned,
    'scannedAt': scannedAt?.toIso8601String(),
  };
  
  /// Buat Ticket dari JSON yang diambil dari storage
  factory Ticket.fromJson(Map<String, dynamic> json) => Ticket(
    id: json['id'],
    eventId: json['eventId'],
    code: json['code'],
    buyerName: json['buyerName'],
    buyerEmail: json['buyerEmail'],
    purchaseDate: DateTime.parse(json['purchaseDate']),
    isScanned: json['isScanned'] ?? false,
    scannedAt: json['scannedAt'] != null ? DateTime.parse(json['scannedAt']) : null,
  );
}