# BeFit – High-Performance Wellness & Fitness Ecosystem

[![Flutter](https://img.shields.io/badge/Flutter-3.19+-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.3+-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![Firebase](https://img.shields.io/badge/Firebase-Auth%20%7C%20Firestore%20%7C%20Storage-FFCA28?logo=firebase&logoColor=black)](https://firebase.google.com)
[![Architecture](https://img.shields.io/badge/Architecture-Clean%20Architecture-blue)](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)
[![State management](https://img.shields.io/badge/State%20Management-BLoC%20%2F%20Cubit-02569B)](https://pub.dev/packages/flutter_bloc)

**BeFit** is a sophisticated, production-grade health and fitness application built with Flutter. It demonstrates industry-standard engineering practices, featuring **Clean Architecture**, robust **State Management with BLoC**, and seamless integration with the **Google Fit Ecosystem** and **Gemini AI**.

---

## 🚀 Key Engineering Highlights

- **Clean Architecture Principles**: Strictly separated into `Data`, `Domain`, and `Presentation` layers to ensure maintainability, testability, and scalability.
- **Functional Programming (Dartz)**: Utilizes `Either` types for robust error handling and domain-driven failures.
- **Dependency Injection**: Leverages `GetIt` and `Injectable` for compile-time safe service location and decoupling.
- **Reactive State Management**: Powered by `flutter_bloc` to handle complex UI states and business logic across different features.
- **External Integrations**: High-performance interaction with Google Fit REST APIs, ExerciseDB, and Google Gemini for AI-driven insights.

---

## ✨ Features

### 🍏 Intelligent Nutrition & Diet Management
- **Smart Diet Planner**: Create dynamic meal plans with real-time macro tracking (Protein, Carbs, Fats).
- **Barcode Food Scanner**: Ultra-fast product recognition using `mobile_scanner` for instant nutritional data entry.
- **Nutritional Insights**: Visualization of diet progress via interactive Radar and Progress charts.

### 🏃 Fitness & Health Ecosystem
- **Google Fit Synchronization**: Bi-directional sync for steps, distance, calories, sleep cycles, and weight history.
- **Interactive Body Selector**: A customized UI component for filtering exercises by specific muscle groups.
- **Comprehensive Analytics**: High-performance data visualization using `fl_chart` for long-term health trends.

### 🍱 User Experience & Performance
- **Hidden Drawer Navigation**: A sleek, modern navigation pattern for an uncluttered interface.
- **Dynamic Onboarding**: Multi-stage profile setup with validation and persistence.
- **Smooth Animations**: Integrated Lottie and customized transitions for a premium feel.

---

## 🛠️ Technical Stack

| Category | Technologies |
|----------|--------------|
| **Core** | Flutter (3.19+), Dart (3.3+) |
| **State Management** | Flutter BLoC, Cubit, RxDart |
| **Networking** | Dio (with Interceptors, Retry Policy, Connectivity checks) |
| **Architecture / DI** | Clean Architecture, GetIt, Injectable, Dartz (Functional) |
| **Backend / Auth** | Firebase (Auth, Firestore, Storage), Google Sign-In |
| **Persistence** | Hive (NoSQL), Shared Preferences |
| **APIs** | Google Fit REST, Gemini AI, ExerciseDB (RapidAPI) |
| **UI Excellence** | fl_chart, Google Fonts, ScreenUtil, Lottie, Flutter Body Part Selector |
| **Hardware Tools** | Camera (Barcode), GPS (Activity Tracking), Sensors (Google Fit) |

---

## 🏛️ Project Architecture

The codebase follows the **Clean Architecture** pattern, ensuring a clear separation of concerns:

```text
lib/
├── core/
│   ├── config/         # Environment & App Configuration
│   ├── di/             # Dependency Injection setup (GetIt/Injectable)
│   ├── error/          # Failures & Exceptions mapping
│   ├── network/        # Base Dio client & Network Info
│   ├── routes/         # Centralized Routing (GoRouter)
│   └── usecase/        # Base Usecase definitions
├── src/
│   ├── [feature]/      # Feature-specific organization
│   │   ├── data/       # Models, Data Sources, Repository Implementations
│   │   ├── domain/     # Entities, Repositories Interfaces, UseCases
│   │   └── presentation/ # BLoCs/Cubits, Screens, Widgets
```

---

## 📸 Core UI Showcase

| Home/Health Dashboard | Smart Diet Planner | Muscle Selection |
|:---:|:---:|:---:|
| ![Home](https://via.placeholder.com/300x600?text=Home+UI) | ![Diet](https://via.placeholder.com/300x600?text=Diet+Planner) | ![Workout](https://via.placeholder.com/300x600?text=Body+Selector) |

---

## ⚙️ Setup & Installation

### Prerequisites
- Flutter SDK `^3.19.0`
- Firebase Project configured for Android/iOS
- API Keys for Gemini, Google Maps, and ExerciseDB

### Installation Steps
1. **Clone the repository**:
   ```bash
   git clone https://github.com/Amrut-03/befit-fitness-app
   cd befitapp
   ```
2. **Setup Environment**:
   Create a `.env` file in the root directory:
   ```env
   EXERCISE_DB_API_KEY=your_rapidapi_key
   GOOGLE_SIGN_IN_SERVER_CLIENT_ID=your_client_id
   ```
3. **Install Dependencies**:
   ```bash
   flutter pub get
   ```
4. **Generate Code**: (For DI and Models)
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```
5. **Run the application**:
   ```bash
   flutter run
   ```

---

## 📄 License
This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 📫 Contact
**Your Name** - [LinkedIn](https://www.linkedin.com/in/amrut-khochikar) - [Portfolio](https://github.com/Amrut-03)
Project Link: [https://github.com/Amrut-03/befit-fitness-app](https://github.com/Amrut-03/befit-fitness-app)
