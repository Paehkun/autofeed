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
| **Hardware** | ESP32 & IoT Sensors |
| **Design Pattern** | Clean Architecture (Domain-Driven Design) |

---

## 🏆 Awards & Recognition
- **Silver Award** – *Research and Innovation Symposium & Exposition (RISE 2025)*.

---

## 📐 System Architecture

The project follows the **Clean Architecture** principles to ensure a strict separation of concerns:

- **Presentation Layer**: UI logic and state management.
- **Domain Layer**: Business rules, entities, and use cases (the "Heart" of the app).
- **Data Layer**: Repository implementations and data sources (Firebase integration).

---

## ⚙️ Installation & Setup

> [!IMPORTANT]
> Sensitive configuration files (like `.env` and `firebase_options.dart`) are excluded for security.


1. **Clone the repository:**
   ```bash
   git clone [https://github.com/Paehkun/auto_test.git](https://github.com/Paehkun/auto_test.git)

2. **Navigate to the project folder:**

   ```bash

    cd auto_test

3. **Configure Environment Variables: Create a .env file in the root folder and add your Firebase credentials:**
   ```bash

    FIREBASE_API_KEY=your_api_key
    FIREBASE_APP_ID=your_app_id
    FIREBASE_MESSAGING_SENDER_ID=your_id
    FIREBASE_PROJECT_ID=your_project_id
    FIREBASE_DATABASE_URL=your_db_url

4. **Initialize Firebase: Ensure you have the FlutterFire CLI installed:**

   ```bash

    flutterfire configure

5. **Install dependencies:**

   ```bash

    flutter pub get

6. **Build & Run:**

   ```bash

    flutter run

## 📁 Repository Structure
```Plaintext

lib/
├── core/          # Shared utilities, themes, and navigation
├── data/          # Firebase API, models, and repository implementations
├── domain/        # Pure business logic (Entities & Use Cases)
├── presentation/  # UI components (Screens & Widgets)
└── main.dart      # Bootstrap & entry point
