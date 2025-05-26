# Prenova - Prenatal Pulse 🤱

A comprehensive prenatal care application built with Flutter, designed to support expectant mothers throughout their pregnancy journey with health monitoring, AI-powered assistance, and medical document management.

## ✨ Features

- **🤖 AI Chatbot** - Intelligent assistant for pregnancy-related queries
- **📊 Vital Signs Monitoring** - Track and record important health metrics
- **👶 Fetal Health Monitoring** - Monitor baby's development and health
- **🦵 Kick Tracker** - Track and log baby movements
- **⏱️ Contraction Timer** - Time and monitor contractions
- **🥗 Diet Recommendations** - Personalized nutrition guidance
- **📋 Medical Document Management** - Generate and store medical reports
- **👩‍⚕️ Doctor Consultation** - Connect with healthcare providers
- **📅 Appointment Scheduling** - Manage medical appointments

## 🚀 Getting Started

### Prerequisites

- **Flutter SDK** (>=3.0.0)
- **Dart SDK** (>=3.0.0)
- **Android Studio** or **VS Code** with Flutter extensions
- **Git**

### Installation

1. **Clone the repository**

   ```bash
   git clone https://github.com/your-username/Prenova-Prenatal-Pulse.git
   cd Prenova-Prenatal-Pulse
   ```

2. **Navigate to the client directory**

  ```bash
  cd client
  ```

3.**Install Dependencies**

```bash
flutter pub get  
```

4.**Run the application**

```bash
flutter run  
```

### Platform-Specific Setup

**Android**

- Ensure Android SDK is installed
- Connect an Android device or start an emulator
- Run: flutter run

**iOS (macOS only)**

- Install Xcode from the App Store
- Run: flutter run

**Web**

- Run: flutter run -d chrome
- Desktop (Windows/Linux/macOS)
- Run: flutter run -d windows (or linux/macos)

**🎨 Architecture**
The project follows a feature-based architecture with clean separation of concerns:

- Core: Shared utilities, themes, and constants
- Features: Individual app features (auth, monitoring, etc.)
- Presentation: UI components and pages
- Domain: Business logic and entities
- Data: Data sources and repositories

### Made with ❤️ for expectant mothers everywhere