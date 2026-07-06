# CRM Sales App — Flutter

Real Estate CRM mobile app for sales executives built with Flutter.

## Tech Stack
- Flutter
- Dart
- REST API integration

## Setup

```powershell
cd sales-flutter
flutter pub get
flutter run
```

## API Configuration

Located in `lib/config/app_config.dart`

- Android Emulator: `http://10.0.2.2:5000/api`
- Physical Device: Change `ApiClient.baseUrl` to your computer's LAN IP

## Features

- Login
- Dashboard
- Leads management
- Customers
- Follow-ups
- Invoices
- Payments
- Commissions

## Branch Strategy

```
main    ← production
dev     ← integration/testing
istiak  ← lead dev working branch
```
