# Geo Entities App - Landmark Manager

## 1. App Summary
This is a Flutter-based Android application designed to manage and visualize geographic landmark records in Bangladesh. The app communicates with a remote REST API to perform full CRUD (Create, Read, Update, Delete) operations. It features an interactive Google Map with a custom "Night Mode" theme, a scrollable list of records, and a robust form for adding and editing landmarks with image support and GPS location detection.

## 2. Feature List
* **Interactive Map View:** Displays landmarks on a Google Map centered on Bangladesh (23.6850°N, 90.3563°E) using a custom **Night Mode** style for differentiation.
* **CRUD Operations:**
    * **Create:** Add new landmarks with a title, coordinates, and an image.
    * **Read:** View all landmarks on the map or in a list.
    * **Update:** Edit existing landmark details and images.
    * **Delete:** Remove records permanently from the server.
* **GPS Integration:** Automatically detects the user's current GPS location when adding a new entry. Includes a safety timeout to handle slow emulator GPS responses.
* **Location Picker:** Allows users to manually select a specific location on a full-screen map if they prefer not to use GPS.
* **Image Handling:** Supports selecting images from the gallery, automatically resizing them to 800x600 resolution before uploading, and strictly enforcing JPEG content types for server compatibility.
* **Smart Navigation:** Prevents accidental app closures ("Black Screen" issues) by intelligently managing navigation stacks after form submissions.

## 3. Setup Instructions
To build and run this application locally, follow these steps:

### Prerequisites
* Flutter SDK installed (version 3.0.0 or higher).
* VS Code or Android Studio.
* An Android Emulator or Physical Device.

### Installation
1.  **Clone the Repository:**
    ```bash
    git clone https://github.com/saany007/CSE489-Mid.git
    cd lab_exam
    ```

2.  **Install Dependencies:**
    Run the following command in your terminal to fetch all required packages (http, google_maps_flutter, location, etc.):
    ```bash
    flutter pub get
    ```

3.  **Asset Configuration:**
    Ensure the `assets/map_style.json` file exists in the project root. This file is required for the map's Night Mode theme.

4.  **Run the App:**
    Connect your device or start your emulator, then run:
    ```bash
    flutter run
    ```
    *Note: If using an emulator, ensure it has Google Play Services enabled for Google Maps to render correctly.*

## 4. Known Limitations
* **Emulator GPS Latency:** On some emulators, the initial GPS lock can be slow. The app handles this with a 4-second timeout that prompts the user to enter data manually if the signal is delayed.
* **Network Dependency:** The app requires an active internet connection to fetch and save data. Offline caching (Room DB) is not currently implemented.
* **Server Strictness:** The backend API is highly strict regarding image formats. The app strictly converts uploads to `image/jpeg` to ensure compatibility, but uploading non-image files may result in server errors.
