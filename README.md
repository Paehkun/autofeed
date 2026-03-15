# AutoFeed: Smart IoT Fish Feeding System 🐟

[![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=for-the-badge&logo=Flutter&logoColor=white)](https://flutter.dev/)
[![Firebase](https://img.shields.io/badge/firebase-%23039BE5.svg?style=for-the-badge&logo=firebase)](https://firebase.google.com/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=for-the-badge)](https://opensource.org/licenses/MIT)
[![Award](https://img.shields.io/badge/Award-Silver%20RISE%202025-silver?style=for-the-badge)](https://example.com)

**AutoFeed** is a robust mobile application developed using **Flutter**, designed to provide real-time monitoring and automated control for fish feeding systems. By bridging **IoT hardware** and **Firebase cloud services**, it offers a seamless solution for modern aquarium and fish farm management.

---

## 🌟 Key Features

- 📊 **Real-time Monitoring** – Track food storage levels and system health in real-time.
- 🎮 **Remote Manual Feed** – Trigger the feeding mechanism (Servo/Motor) instantly with a single tap.
- 🔔 **Intelligent Alerts** – Stay updated with critical notifications via **Firebase Cloud Messaging (FCM)**.
- 🔐 **Secure Access** – Identity management and data protection powered by **Firebase Authentication**.
- 🏗️ **Professional Architecture** – Built using **Clean Architecture** for high scalability and testability.

---

## 🛠️ Technology Stack

| Category | Technology |
| :--- | :--- |
| **Mobile Framework** | Flutter |
| **Backend / Cloud** | Firebase (Auth, RTDB, FCM) |
| **State Management** | BLoC & Provider |
| **Hardware** | ESP32 / ESP8266 & IoT Sensors |
| **Design Pattern** | Clean Architecture (Domain-Driven Design) |

---

## 🏆 Awards & Recognition
- **Silver Award** – *Research and Innovation Symposium & Exposition (RISE 2025)*.

---

## 📐 System Architecture

The project follows the **Clean Architecture** principles to ensure a strict separation of concerns:

- **Presentation Layer**: UI logic and state management using BLoC.
- **Domain Layer**: Business rules, entities, and use cases (the "Heart" of the app).
- **Data Layer**: Repository implementations and data sources (Firebase integration).

---

## ⚙️ Installation & Setup

> [!IMPORTANT]
> Sensitive configuration files (like `.env` and `firebase_options.dart`) are excluded for security.

### 1. Configure Environment Variables
Create a `.env` file in the root folder:
```env
FIREBASE_API_KEY=your_api_key
FIREBASE_APP_ID=your_app_id
FIREBASE_MESSAGING_SENDER_ID=your_id
FIREBASE_PROJECT_ID=your_project_id
FIREBASE_DATABASE_URL=your_db_url

### 2. Initialize Firebase
Ensure you have the FlutterFire CLI installed:

```Bash

flutterfire configure

### 3. Build & Run
```Bash

flutter pub get
flutter run

📁 Repository Structure
Plaintext

lib/
├── core/          # Shared utilities, themes, and navigation
├── data/          # Firebase API, models, and repository implementations
├── domain/        # Pure business logic (Entities & Use Cases)
├── presentation/  # UI components (Screens, Widgets, BLoCs)
└── main.dart      # Bootstrap & entry point
