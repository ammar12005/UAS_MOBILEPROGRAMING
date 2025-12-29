// test/widget_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aplikasi_manajemen_event_dan_tiket_digital/main.dart';

void main() {
  testWidgets('App initialization test', (WidgetTester tester) async {
    // Build aplikasi
    await tester.pumpWidget(const MyApp());
    
    // Tunggu hingga loading selesai
    await tester.pumpAndSettle();

    // Verify bahwa login page muncul atau dashboard muncul
    final hasProgress = find.byType(CircularProgressIndicator).evaluate().isNotEmpty;
    final hasLoginText = find.text('Event Manager Pro').evaluate().isNotEmpty;
    
    expect(
      hasProgress || hasLoginText,
      isTrue,
      reason: 'Should show either CircularProgressIndicator or Event Manager Pro text',
    );
  });

  testWidgets('Login page renders correctly', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: LoginPage()));
    
    // Verify elemen-elemen login page
    expect(find.text('Event Manager Pro'), findsOneWidget);
    expect(find.text('Login'), findsAtLeastNWidgets(1));
    expect(find.text('Register'), findsOneWidget);
    expect(find.byType(TextField), findsWidgets);
  });

  testWidgets('Login form validation', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: LoginPage()));
    
    // Tap login button tanpa isi form
    final loginButton = find.widgetWithText(ElevatedButton, 'Login').first;
    await tester.tap(loginButton);
    await tester.pump();
    
    // Verify validasi muncul
    expect(find.text('Email tidak boleh kosong'), findsOneWidget);
  });

  testWidgets('Toggle between Login and Register', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: LoginPage()));
    
    // Tap register button
    final registerTab = find.widgetWithText(ElevatedButton, 'Register').first;
    await tester.tap(registerTab);
    await tester.pump();
    
    // Verify field nama muncul (hanya ada di register)
    expect(find.text('Nama Lengkap'), findsOneWidget);
    expect(find.text('Konfirmasi Password'), findsOneWidget);
  });

  testWidgets('Password visibility toggle', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: LoginPage()));
    
    // Find password field
    final passwordFields = find.byType(TextField);
    expect(passwordFields, findsWidgets);
    
    // Find visibility icon
    final visibilityIcon = find.byIcon(Icons.visibility_off);
    if (visibilityIcon.evaluate().isNotEmpty) {
      await tester.tap(visibilityIcon.first);
      await tester.pump();
      
      // Verify icon changed
      expect(find.byIcon(Icons.visibility), findsWidgets);
    }
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

      final eventFromJson = Event.fromJson(json);
      expect(eventFromJson.name, event.name);
      expect(eventFromJson.capacity, event.capacity);
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

      final ticketFromJson = Ticket.fromJson(json);
      expect(ticketFromJson.code, ticket.code);
      expect(ticketFromJson.isScanned, ticket.isScanned);
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
      expect(json['name'], 'Test User');
      expect(json['email'], 'test@example.com');

      final userFromJson = User.fromJson(json);
      expect(userFromJson.name, user.name);
      expect(userFromJson.email, user.email);
    });
  });
}