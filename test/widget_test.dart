// FILE: test/widget_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aplikasi_manajemen_event_dan_tiket_digital/main.dart';
import 'package:aplikasi_manajemen_event_dan_tiket_digital/models.dart';
import 'package:aplikasi_manajemen_event_dan_tiket_digital/pages/login_page.dart';

void main() {
  testWidgets('App initialization test', (WidgetTester tester) async {
    // Build aplikasi
    await tester.pumpWidget(const MyApp());
    
    // Tunggu hingga loading selesai
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // Verify bahwa ada CircularProgressIndicator atau text Event Manager Pro
    final hasProgress = find.byType(CircularProgressIndicator).evaluate().isNotEmpty;
    final hasEventText = find.text('Event Manager Pro').evaluate().isNotEmpty;
    
    expect(
      hasProgress || hasEventText,
      isTrue,
      reason: 'Should show either CircularProgressIndicator or Event Manager Pro text',
    );
  });

  testWidgets('Login page renders correctly', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: LoginPage()));
    
    // Verify elemen-elemen login page
    expect(find.text('Selamat Datang!'), findsOneWidget);
    expect(find.text('Login ke Event Manager Pro'), findsOneWidget);
    expect(find.text('Belum punya akun?'), findsOneWidget);
    expect(find.text('Daftar'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(2)); // Email dan Password
  });

  testWidgets('Login form validation', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: LoginPage()));
    
    // Tap login button tanpa isi form
    final loginButton = find.widgetWithText(ElevatedButton, 'Login');
    await tester.tap(loginButton);
    await tester.pump();
    
    // Verify validasi muncul
    expect(find.text('Email harus diisi'), findsOneWidget);
    expect(find.text('Password harus diisi'), findsOneWidget);
  });

  testWidgets('Password visibility toggle', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: LoginPage()));
    
    // Find visibility icon (default hidden)
    final visibilityIcon = find.byIcon(Icons.visibility);
    expect(visibilityIcon, findsOneWidget);
    
    // Tap to show password
    await tester.tap(visibilityIcon);
    await tester.pump();
    
    // Verify icon changed to visibility_off
    expect(find.byIcon(Icons.visibility_off), findsOneWidget);
  });

  group('Event Model Tests', () {
    test('Event model JSON serialization', () {
      final event = Event(
        id: 1,
        name: 'Test Event',
        date: DateTime(2025, 1, 1),
        location: 'Test Location',
        capacity: 100,
        price: 50000,
        description: 'Test Description',
        ticketsSold: 10,
      );

      final json = event.toJson();
      expect(json['name'], 'Test Event');
      expect(json['capacity'], 100);
      expect(json['ticketsSold'], 10);
      expect(json['price'], 50000);

      final eventFromJson = Event.fromJson(json);
      expect(eventFromJson.name, event.name);
      expect(eventFromJson.capacity, event.capacity);
      expect(eventFromJson.ticketsSold, event.ticketsSold);
    });

    test('Event model with default ticketsSold', () {
      final event = Event(
        id: 1,
        name: 'Test Event',
        date: DateTime(2025, 1, 1),
        location: 'Test Location',
        capacity: 100,
        price: 50000,
        description: 'Test Description',
      );

      expect(event.ticketsSold, 0); // Default value
    });
  });

  group('Ticket Model Tests', () {
    test('Ticket model JSON serialization', () {
      final ticket = Ticket(
        id: 1,
        eventId: 1,
        code: 'TKT-ABC123',
        buyerName: 'John Doe',
        buyerEmail: 'john@example.com',
        purchaseDate: DateTime(2025, 1, 1),
        isScanned: false,
      );

      final json = ticket.toJson();
      expect(json['code'], 'TKT-ABC123');
      expect(json['buyerName'], 'John Doe');
      expect(json['isScanned'], false);
      expect(json['scannedAt'], null);

      final ticketFromJson = Ticket.fromJson(json);
      expect(ticketFromJson.code, ticket.code);
      expect(ticketFromJson.isScanned, ticket.isScanned);
      expect(ticketFromJson.scannedAt, null);
    });

    test('Ticket model with scanned status', () {
      final scannedAt = DateTime(2025, 1, 2);
      final ticket = Ticket(
        id: 1,
        eventId: 1,
        code: 'TKT-XYZ456',
        buyerName: 'Jane Doe',
        buyerEmail: 'jane@example.com',
        purchaseDate: DateTime(2025, 1, 1),
        isScanned: true,
        scannedAt: scannedAt,
      );

      expect(ticket.isScanned, true);
      expect(ticket.scannedAt, scannedAt);

      final json = ticket.toJson();
      final ticketFromJson = Ticket.fromJson(json);
      expect(ticketFromJson.isScanned, true);
      expect(ticketFromJson.scannedAt, isNotNull);
    });
  });

  group('User Model Tests', () {
    test('User model JSON serialization', () {
      final user = User(
        id: 1,
        name: 'Test User',
        email: 'test@example.com',
        password: 'password123',
      );

      final json = user.toJson();
      expect(json['id'], 1);
      expect(json['name'], 'Test User');
      expect(json['email'], 'test@example.com');
      expect(json['password'], 'password123');

      final userFromJson = User.fromJson(json);
      expect(userFromJson.id, user.id);
      expect(userFromJson.name, user.name);
      expect(userFromJson.email, user.email);
      expect(userFromJson.password, user.password);
    });

    test('User model creates correctly', () {
      final user = User(
        id: 123,
        name: 'John Doe',
        email: 'john@test.com',
        password: 'secure123',
      );

      expect(user.id, 123);
      expect(user.name, 'John Doe');
      expect(user.email, 'john@test.com');
      expect(user.password, 'secure123');
    });
  });
}