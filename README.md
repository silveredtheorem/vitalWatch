# VitalWatch: Emergency SOS Application

VitalWatch is a Flutter-based mobile application designed to provide users with a quick and easy way to send emergency SOS alerts. This prototype includes manual and automatic triggers, live location tracking, and integration with Firebase for backend services.

## Features

- **One-Tap SOS:** A large, visually prominent SOS button on the home screen.
- **Automatic Fall Detection:** Uses the phone's accelerometer to detect a fall followed by an impact, triggering a 15-second countdown before sending a medical alert.
- **Emergency Contacts:** Users can add and manage emergency contacts, who are automatically pinged when any SOS is triggered.
- **Live Location Tracking:** When an SOS is active, the app sends live location updates to a Firestore 'session' document.
- **Interactive Map:** Displays the user's location and nearby authorities (Police, Fire, Medical) on a map after an SOS is sent.
- **Dark Mode UI:** A sleek, modern user interface with a dark theme and professional animations.
- **Local Emulator Support:** Fully configured to run with a local Firebase Emulator suite for easy development and testing.

## Getting Started

This project is configured to run with a local Firebase development environment. Follow these steps to get the app running on your own machine.

### 1. Prerequisites

- **Flutter SDK:** Ensure you have the Flutter SDK installed. ([Installation Guide](https://flutter.dev/docs/get-started/install))
- **Firebase CLI:** You must have the Firebase Command Line Interface installed. ([Installation Guide](https://firebase.google.com/docs/cli#install-cli-windows))
- **Java Development Kit (JDK):** The Firebase Firestore emulator requires Java to be installed on your system.

### 2. Project Setup

1.  **Clone the Repository:**
    ```sh
    git clone <your-repository-url>
    cd untitled
    ```

2.  **Get Flutter Packages:**
    ```sh
    flutter pub get
    ```

3.  **Set Up Firebase Functions:**
    ```sh
    cd functions
    npm install
    npm run build
    cd ..
    ```

### 3. Configuration (Crucial Step)

This project uses environment variables to handle secret API keys and local network configuration. You must create two files that are NOT checked into source control.

**A. Configure Your API Keys:**

-   Create a new file in the `functions/` directory named `.env`.
-   Add your Google Maps API key to this file like so:
    ```
    GOOGLE_MAPS_API_KEY=AIzaSy...your...key...here
    ```
-   In the `android/app/src/main/AndroidManifest.xml` file, replace the placeholder `YOUR_API_KEY_HERE` with the same Google Maps API key.

**B. Configure Your Local Network:**

-   Find your computer's local IPv4 address (e.g., by running `ip a` on Linux or `ipconfig` on Windows).
-   Open the `lib/config.dart` file.
-   Replace the default `127.0.0.1` value with your computer's local IP address.

    *This step is necessary so that the app running on a real phone can connect to the emulators running on your computer.*

### 4. Running the Application

1.  **Start the Firebase Emulators:**
    In your project's root directory, run:
    ```sh
    firebase emulators:start
    ```

2.  **Run the Flutter App:**
    Connect a real Android device and run:
    ```sh
    flutter run
    ```

## How It Works: A Quick Architectural Overview

-   **Frontend:** The app is built with Flutter and features a clean architecture, separating UI (screens), business logic (state management in `main.dart`), and data models.
-   **Backend:** Firebase Cloud Functions (`functions/src/index.ts`) handle all backend logic, such as finding nearby places and creating ping logs.
-   **Database:** Firestore is used as the database for storing SOS logs, emergency contacts, and live location tracking sessions.
-   **Local Development:** The entire system is designed to run locally using the Firebase Emulator Suite, which simulates the cloud environment on your machine.
