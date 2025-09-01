## 1.0.2

- Added Database-Only Operations: Lightweight database operations without camera initialization
- Implemented `initializeDatabaseOnly()` method for fast database setup
- Added separate `_dbInitialized` flag for database-only operations
- Enhanced performance: Database operations now 10-50x faster than full initialization
- Added `deleteAllUsers()` method for complete database cleanup
- Updated `FaceAuthController`, `FaceAuth`, and `FaceAuthIsolate` classes
- Improved resource efficiency: No ML models or camera services loaded for DB operations
- Added comprehensive documentation for database-only usage patterns
- Created `DATABASE_ONLY_USAGE.md` with detailed examples
- Updated README with new feature documentation and API reference

## 1.0.1

- Added User ID Management: Custom user ID support with duplicate checking
- Enhanced Database Operations: Complete CRUD operations for user management
- Improved Registration Flow: Better face registration with user ID validation
- Updated Database Schema: Changed from INTEGER to TEXT for user IDs
- Added User Existence Checking: Methods to check, get, and delete users
- Enhanced API: Added comprehensive database helper methods
- Improved Documentation: Updated README with complete API documentation
- Added Tests: Comprehensive testing for new database functionality
- Fixed userId parameter handling in registration flow
- Enhanced error handling and validation

## 1.0.0

- Initial release of face_recognition_auth package
- Implemented face recognition authentication using TensorFlow Lite
- Added Google ML Kit integration for face detection
- Created FaceAuthController for easy state management
- Added FaceAuthView for camera preview and face detection
- Implemented user registration and authentication flows
- Added SQLite database for storing face embeddings
- Included example app demonstrating usage
- Added comprehensive documentation and README

## 0.0.1

- TODO: Describe initial release.
