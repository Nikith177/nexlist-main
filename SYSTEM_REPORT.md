# Nexlist System Architecture Report

## Overview
Nexlist is a web-first campus marketplace built with Flutter. It is designed to allow college students to buy, sell, rent items, offer services, and make requests exclusively within their campus. Connections between buyers and sellers are offloaded to WhatsApp, keeping the platform fast, focused, and lightweight.

## Tech Stack
- **Framework**: Flutter Web (Dart SDK 3.11.1)
- **Routing**: `go_router`
- **Backend & Database**: Firebase Core, Cloud Firestore, Firebase Storage
- **Authentication**: Firebase Auth (Google Provider for Web)
- **Local Storage**: `shared_preferences`
- **UI/UX Utilities**: `cached_network_image`, `cupertino_icons`, `flutter_image_compress`, `share_plus` (for WhatsApp sharing)

## Folder Structure
The codebase follows a feature-centric architecture under `lib/`:
- `lib/core/` - Global setups (constants, network, router, services, state, theme, utils)
- `lib/features/` - Dedicated modules containing isolated domain flow (auth, creation_form, home, listing, listing_feed, notifications, post_listing, profile, rentals, requests, saved, services)
- `lib/shared/` - Shared global UI models, utils, and widgets
- `lib/config/` - Marketplace and app-level constants (`marketplace_config.dart`)
- `web/` - Raw HTML for the landing page entrance barrier

## Screens
The primary screens discovered in `lib/features/**/presentation/`:
- **Auth**: `AuthGate`, `SplashScreen`, `LoginScreen`
- **Core Nav Shell**: `HomeScreen`, `ServicesScreen`, `RequestsScreen`, `ProfileScreen`
- **Post**: `PostListingScreen`
- **Details**: `ListingDetailScreen`
- **Profile Sub-screens**: `MyListingsScreen`, `MyRequestsScreen`, `MyServicesScreen`, `EditProfileScreen`, `AboutScreen`, `SupportFormScreen`
- **Other Modals/Screens**: `NotificationsScreen`, `SavedScreen`, `RentalsScreen`

## Navigation Flow
Routing is heavily controlled by `app_router.dart` and Firebase Auth state:
- **Routes**:
  - `/` -> `AuthGate`
  - `/login` -> Handles login UI (HTML landing redirects here)
  - `/home`, `/services`, `/requests`, `/profile` are maintained in a `StatefulShellRoute.indexedStack` (Bottom Nav layout)
  - `/post` -> Standalone `PostListingScreen`
  - `/listing/:id` -> `ListingDetailScreen` (Deep-linkable)
  - `/edit-profile`, `/support-form`, `/my-requests`, etc.
- **Redirection Rules**: Unauthorized users are blocked from `/home` or `/listing` and securely pushed back to `/login`. Authorized users attempting `/login` are pushed to `/home`.

## Auth System
- **Method**: Google Sign-In via `firebase_auth`.
- **Restrictions**: Tied to an `AuthUserBootstrap` check. Accounts must verify presence against valid campus emails (domain checks).
- **Post-Login Process**: Includes a verification gate (`PhoneGateUtils`) before full marketplace access is granted to make sure students have provided proper contact paths.

## State Management
- **Type**: Standard localized Flutter State Management. There are no heavy-duty global packages (like Riverpod or Bloc) present in `pubspec.yaml`. 
- **Mechanism**: The app heavily utilizes `StatefulWidget`, raw Future/Stream builders directly mounted to Firestore data, and native `ChangeNotifier` overrides (e.g., `GoRouterRefreshStream`).

## Database
Data resides strictly in **Cloud Firestore** structured under the following collections:

### Collections & Key Fields:
- **`users`** (Doc ID: `Firebase Auth UID`)
  - `name`, `email`, `phone`, `campus_id`, `isAdmin`
  - Sub-collection: `saved_items` (contains documents mapping to bookmarked listings)
- **`listings`** (Doc ID: Auto-generated)
  - `title`, `price` (double), `description` (string)
  - `sellerId` (refers to `users`), `user_name` (contact name)
  - `type` ('sell', 'rent', 'service', 'request')
  - `location_type` (e.g., 'hostel', 'campus', 'anywhere'), `location_tag`, `location_detail`
  - `imageUrls` (Array of Firebase Storage URLs), `imageUrl`
  - `createdAt` (server timestamp), `status` ('available')
  - Conditional: `category`, `condition`, `rental_price_unit`, `pricing_type`
- **`support_requests`** (Doc ID: Auto-generated)
  - Collects help requests submitted from `SupportFormScreen`.

## Features
*Based strictly on what exists in Dart files without assuming roadmap logic:*
- **Browse Feed**: Read-only listing feed on the Home screen.
- **Category Filters**: Filter chips for category-based searches and type scopes (sell, rent).
- **Draft / Post Item**: Multi-type marketplace creation via `PostListingScreen`.
- **Hostel & Campus Targeting**: Specific location tagging capabilities.
- **Saved Items**: Bookmark logic linking listings directly to user accounts.
- **Support Ticketing**: Dedicated in-app contact form for reporting issues.
- **Share & Contact via WhatsApp**: Interaction hooks generating automated messages using `share_plus` to jumpstart negotiations outside the app (`MarketplaceConfig`).

## User Flow
*Real implemented flow:*
1. **Visitor** views web-only landing page (in `web/index.html`).
2. **Visitor** clicks "Enter Nexlist" -> navigates to the Flutter engine at `/login`.
3. **User** signs in via Google OAuth.
4. **User** is gated by an identity/profile assurance check if their profile lacks absolute essentials.
5. **User** arrives at `/home` to browse feed.
6. **User** clicks on a listing -> Navigates to `/listing/:id`.
7. **User** taps contact -> System generates predefined message headers using `MarketplaceConfig` and pops open a `url_launcher` link straight to WhatsApp.

## Limitations
*Based entirely on codebase gaps and deliberate logic decisions:*
- **No Native In-App Chat**: The platform completely defers all realtime communication to external paths.
- **No Payment Processors**: Transactions are assumed to happen entirely in-person or offline.
- **Isolated to Web Execution**: Non-web auth (e.g. `google_sign_in` plugin flows for native mobile apps) is explicitly commented out or sidestepped to maintain the `kIsWeb` focus.
- **Absence of Native Deep Links Configurations**: Because the app relies strictly on web hosting for logic and is marked `publish_to: none`, native Apple/Android applinks are non-existent.
