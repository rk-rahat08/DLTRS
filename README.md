# DLTRS

DLTRS is a Flutter productivity app for organizing daily life in one place. It combines task management, notes, habits, calendar planning, focus sessions, and productivity insights with Supabase-backed authentication and cloud data storage.

## Overview

DLTRS is built as a mobile-first app with:

- email, phone, and Google sign-in support
- verified-user authentication flow
- task scheduling with reminders and priorities
- habit logging and weekly progress summaries
- personal notes linked to a user account
- calendar-based task viewing
- focus mode with daily stats
- productivity tracking with shareable PDF and screenshot reports
- profile management with image upload support

## Tech Stack

- Flutter
- Dart
- `flutter_bloc` for state management
- `go_router` for navigation
- Supabase for auth, database, and storage
- `get_it` for dependency injection
- `flutter_local_notifications` for reminders
- `shared_preferences` for local theme and focus-session state

## Main Features

### Authentication

- Sign up with profile details
- Sign in with email/password
- Sign in with phone number lookup
- Google OAuth sign-in
- Email verification flow
- Password reset

### Tasks

- Create, update, complete, cancel, and delete tasks
- Assign low, medium, or high priority
- Set one-time, daily, or weekly recurrence
- Detect nearby time conflicts
- Schedule local reminders for upcoming tasks
- View task stats and recent activity from the dashboard

### Notes

- Create and edit personal notes
- Store notes per authenticated user
- Keep notes synced through Supabase

### Habits

- Track water intake, exercise, sleep hours, and study hours
- Save one entry per habit type per day
- Review weekly summaries and completion score

### Focus & Productivity

- Run timed focus sessions
- Track completed sessions, total focus time, and broken sessions
- View productivity score based on task completion state
- Share productivity summaries as PDF or screenshot

## Project Structure

```text
lib/
  app/                  App bootstrap, routing, theme
  core/                 Constants, shared widgets, services
  features/
    auth/               Authentication and profile flow
    dashboard/          Main overview screen
    tasks/              Task entities, repository, cubit, UI
    notes/              Notes entities, repository, UI
    habits/             Habit tracking logic and UI
    calendar/           Calendar-based task view
    focus_mode/         Focus timer and stats
    productivity/       Reports and productivity analytics
supabase/
  schema.sql            Database schema, RLS policies, storage bucket setup
```

## Getting Started

### Prerequisites

- Flutter SDK
- Dart SDK
- Android Studio or Xcode for device/emulator setup
- A Supabase project

### 1. Install dependencies

```bash
flutter pub get
```

### 2. Create the environment file

Create a `.env` file in the project root:

```env
SUPABASE_URL=your_supabase_project_url
SUPABASE_ANON_KEY=your_supabase_anon_key
```

Without these values, the app can still launch, but Supabase-powered features will not work correctly.

### 3. Set up Supabase

Run the SQL in [supabase/schema.sql](/C:/Users/User/Desktop/DLTRS/supabase/schema.sql) inside your Supabase SQL editor. This creates:

- `users`
- `tasks`
- `notes`
- `habits`
- row-level security policies
- the `profiles` storage bucket for user images

### 4. Platform auth configuration

If you plan to use Google sign-in or mobile auth callbacks, make sure your Supabase auth provider settings and platform redirect configuration match the app setup.

The app uses this OAuth callback for Flutter mobile:

```text
io.supabase.flutter://callback
```

### 5. Run the app

```bash
flutter run
```

## Notifications

DLTRS includes local task reminders and focus-mode notifications. On Android, reminder behavior also uses native platform code under `android/app/src/main/kotlin/com/dltrs/dltrs/` for scheduling alarms and handling boot restore behavior.

## Useful Commands

```bash
flutter pub get
flutter analyze
flutter test
flutter run
```

## Notes for Development

- Theme preference is stored locally with `SharedPreferences`
- Focus session stats are stored locally per day
- Task, note, habit, and profile data are stored in Supabase
- Profile images are uploaded to the Supabase `profiles` storage bucket

## Status

This repository is currently set up as a private Flutter app project and is not published as a package.
