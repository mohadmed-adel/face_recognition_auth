# Contributing to Face Recognition Auth

Thank you for your interest in contributing to the face_recognition_auth package! This document provides guidelines and information for contributors.

## Table of Contents

- [Getting Started](#getting-started)
- [Development Setup](#development-setup)
- [Code Style](#code-style)
- [Testing](#testing)
- [Pull Request Process](#pull-request-process)
- [Reporting Bugs](#reporting-bugs)
- [Feature Requests](#feature-requests)

## Getting Started

Before contributing, please:

1. **Read the README** to understand the package
2. **Check existing issues** to avoid duplicates
3. **Join discussions** in GitHub Discussions
4. **Familiarize yourself** with the codebase

## Development Setup

### Prerequisites

- Flutter 3.0+
- Dart 2.17+
- Android Studio / VS Code
- Git

### Local Development

1. **Fork the repository**
   ```bash
   git clone https://github.com/YOUR_USERNAME/face_recognition_auth.git
   cd face_recognition_auth
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Run tests**
   ```bash
   flutter test
   ```

4. **Check code quality**
   ```bash
   flutter analyze
   ```

5. **Run the example app**
   ```bash
   cd example
   flutter run
   ```

## Code Style

### Dart/Flutter Standards

- Follow the [Dart Style Guide](https://dart.dev/guides/language/effective-dart/style)
- Use `flutter analyze` to check for issues
- Follow the existing code patterns in the project

### File Naming

- Use `snake_case` for file names: `face_auth_controller.dart`
- Use `PascalCase` for class names: `FaceAuthController`
- Use `camelCase` for variables and methods: `faceAuthController`

### Code Organization

```
lib/
├── src/
│   ├── db/           # Database related code
│   ├── services/     # Core services
│   ├── models/       # Data models
│   ├── ui/           # UI components
│   └── isolate/      # Isolate workers
```

### Documentation

- Add comments for complex logic
- Document public APIs
- Update README for new features
- Include code examples

## Testing

### Writing Tests

- Create tests for new features
- Test both success and failure scenarios
- Mock external dependencies
- Test edge cases

### Test Structure

```dart
group('FaceAuthController', () {
  test('should initialize successfully', () async {
    // Test implementation
  });

  test('should handle initialization errors', () async {
    // Test error handling
  });
});
```

### Running Tests

```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/face_auth_controller_test.dart

# Run with coverage
flutter test --coverage
```

## Pull Request Process

### Before Submitting

1. **Ensure tests pass**
   ```bash
   flutter test
   flutter analyze
   ```

2. **Update documentation**
   - Update README if needed
   - Add code examples
   - Update CHANGELOG.md

3. **Check formatting**
   ```bash
   dart format .
   ```

### PR Guidelines

1. **Create a descriptive title**
   - Use present tense: "Add face quality assessment"
   - Be specific about the change

2. **Write a detailed description**
   ```markdown
   ## Description
   Brief description of the changes

   ## Changes Made
   - List specific changes
   - Include any breaking changes

   ## Testing
   - How you tested the changes
   - Screenshots if UI changes

   ## Checklist
   - [ ] Tests pass
   - [ ] Code follows style guidelines
   - [ ] Documentation updated
   - [ ] No breaking changes
   ```

3. **Keep PRs focused**
   - One feature per PR
   - Keep changes small and reviewable
   - Split large changes into multiple PRs

### Review Process

- All PRs require review
- Address review comments promptly
- Update PR based on feedback
- Maintainers will merge when approved

## Reporting Bugs

### Bug Report Template

```markdown
## Bug Description
Brief description of the issue

## Steps to Reproduce
1. Step 1
2. Step 2
3. Step 3

## Expected Behavior
What should happen

## Actual Behavior
What actually happens

## Environment
- Flutter version: X.X.X
- Dart version: X.X.X
- Platform: iOS/Android
- Device: Device model

## Additional Information
- Screenshots if applicable
- Error logs
- Related issues
```

## Feature Requests

### Feature Request Template

```markdown
## Feature Description
Brief description of the feature

## Use Case
How would this feature be used?

## Benefits
What benefits would this provide?

## Implementation Ideas
Any thoughts on implementation?

## Alternatives Considered
Other approaches you've considered
```

## Code of Conduct

### Our Standards

- Be respectful and inclusive
- Use welcoming and inclusive language
- Be collaborative and constructive
- Focus on what is best for the community

### Unacceptable Behavior

- Harassment or discrimination
- Trolling or insulting comments
- Publishing others' private information
- Any conduct inappropriate in a professional setting

## Recognition

Contributors will be recognized in:

- **CONTRIBUTORS.md** file
- **README.md** contributors section
- **Release notes** for significant contributions
- **GitHub repository** contributors list

## Getting Help

If you need help:

- **GitHub Issues**: For bugs and feature requests
- **GitHub Discussions**: For questions and general discussion
- **Documentation**: Check README and inline docs
- **Community**: Join Flutter community channels

## License

By contributing, you agree that your contributions will be licensed under the MIT License.

---

**Thank you for contributing to the Flutter community!** 🚀

Your contributions help make face recognition authentication accessible to developers worldwide.
