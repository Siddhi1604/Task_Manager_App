# Task Manager Pro - Flutter

A comprehensive task management application built with Flutter, designed to help you stay organized and boost productivity. Features include task creation, scheduling, prioritization, subtasks, location-based reminders, and more.

![App Screenshot (Optional - Add a link or image if you have one)]()

## Features

*   **Task Management:** Create, edit, delete, and view tasks.
*   **Scheduling:** Set due dates and times for tasks.
*   **Prioritization:** Assign priority levels (Low, Medium, High) with visual indicators.
*   **Status Tracking:** Mark tasks as Pending, In Progress, or Completed.
*   **Subtasks:** Break down larger tasks into smaller, manageable steps.
*   **Tags:** Organize tasks using custom tags.
*   **Filtering & Sorting:** Filter tasks by status, priority, tags, or completion. Search for specific tasks.
*   **Recurring Tasks:** Set up tasks that repeat daily, weekly, monthly, or yearly (Basic pattern support).
*   **Reminders:** 
    *   Time-based reminders before the due date.
    *   Location-based reminders (trigger when entering/leaving a specified area - Requires location permissions).
*   **Calendar View:** Visualize tasks on a monthly calendar.
*   **Statistics:** View basic task completion statistics.
*   **Cross-Platform:** 
    *   Runs on Android, iOS (with native features like SQLite).
    *   Runs on Web (using SharedPreferences for storage).
*   **Theme Support:** Light and Dark mode with Material 3 design.
*   **Voice Input:** Create tasks using voice commands (experimental).

## Architecture

*   **State Management:** Provider
*   **Database (Mobile):** `sqflite` (SQLite)
*   **Storage (Web):** `shared_preferences`
*   **UI:** Flutter Widgets, `flex_color_scheme` for theming.
*   **Notifications:** `flutter_local_notifications`
*   **Location:** `geolocator`, `geocoding`
*   **Services:** Separate services for Notifications, Location, and potentially Voice Input.
*   **Model-View-ViewModel (MVVM) approach (loosely):**
    *   **Models:** (`lib/models/`) Define data structures (e.g., `Task`).
    *   **Views:** (`lib/screens/`, `lib/widgets/`) UI components.
    *   **ViewModels/Providers:** (`lib/providers/`) Manage state and business logic (e.g., `TaskProvider`, `ThemeProvider`).
    *   **Services:** (`lib/services/`) Handle external interactions (Notifications, Location, Database interaction via `DatabaseHelper`).

## Project Structure

```
.task_manager_app/
├── android/            # Android specific files
├── build/              # Build artifacts (ignored by git)
├── ios/                # iOS specific files
├── lib/
│   ├── assets/         # Static assets (images, fonts, etc.)
│   ├── database/       # Database helper class (database_helper.dart)
│   ├── main.dart       # App entry point
│   ├── models/         # Data models (task.dart)
│   ├── providers/      # State management providers (task_provider.dart, theme_provider.dart)
│   ├── screens/        # UI screens (home_screen.dart, task_detail_screen.dart, etc.)
│   ├── services/       # Business logic services (notification_service.dart, location_service.dart, etc.)
│   ├── theme/          # App theme configuration (app_theme.dart)
│   └── widgets/        # Reusable UI widgets (task_list_item.dart, task_form.dart, etc.)
├── linux/              # Linux specific files
├── macos/              # macOS specific files
├── test/               # Unit and widget tests
├── web/                # Web specific files
├── windows/            # Windows specific files
├── .gitignore          # Git ignore rules
├── analysis_options.yaml # Dart analyzer settings
├── pubspec.lock        # Dependency lock file
├── pubspec.yaml        # Project dependencies and metadata
└── README.md           # This file
```

## Getting Started

**Prerequisites:**

*   Flutter SDK: [Install Flutter](https://flutter.dev/docs/get-started/install)
*   Git: [Install Git](https://git-scm.com/)
*   An IDE (like VS Code or Android Studio) with Flutter plugins.

**Setup & Run:**

1.  **Clone the repository:**
    ```bash
    git clone <YOUR_REPOSITORY_URL>
    cd task_manager_app
    ```
2.  **Install dependencies:**
    ```bash
    flutter pub get
    ```
3.  **Configure API Keys (If Applicable):**
    *   If you are using location services that require API keys (like Google Maps Platform for web geocoding), you might need to configure them. Follow the instructions for the specific plugins (`geolocator`, `geocoding`) or services you integrate.
    *   **IMPORTANT:** Do *not* commit your API keys directly into the repository. Use environment variables, a secrets file (added to `.gitignore`), or Flutter's `--dart-define` feature.

4.  **Run the app:**
    *   Select a target device (emulator, physical device, or Chrome for web).
    *   Run the app:
        ```bash
        flutter run
        ```
    *   To run specifically on Chrome:
        ```bash
        flutter run -d chrome
        ```

## Contributing

Contributions are welcome! If you find issues or have suggestions, please open an issue or submit a pull request.

1.  Fork the Project
2.  Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3.  Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4.  Push to the Branch (`git push origin feature/AmazingFeature`)
5.  Open a Pull Request

## License

Distributed under the MIT License. See `LICENSE` for more information. (Note: You'll need to add a `LICENSE` file, typically containing the MIT license text if you choose MIT).

## Contact

Siddhi Rajeshkumar Pandya

---