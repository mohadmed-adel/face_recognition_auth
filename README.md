# Face Recognition Authentication

A powerful Flutter package that provides secure, reliable face recognition authentication using TensorFlow Lite and Google ML Kit. Implement face-based authentication in your Flutter apps with real-time face detection, quality assessment, and a clean, customizable UI.

## ✨ Features

### 🔐 **Secure Face Authentication**

- **TensorFlow Lite Integration**: Powered by MobileFaceNet for accurate face recognition
- **Real-time Face Detection**: Google ML Kit integration for robust face detection
- **Quality Assessment**: Intelligent face quality scoring to prevent poor registrations
- **Stable Detection**: Requires consecutive stable frames for reliable authentication
- **Embedding Validation**: Ensures consistency between face embeddings

### 🎨 **Clean & Customizable UI**

- **Face Detection Visualization**: Visual feedback with customizable face detection boxes
- **Real-time Camera Preview**: Live camera feed with face detection overlay
- **Customizable Styling**: Easy to customize colors, sizes, and visual elements
- **Responsive Design**: Works seamlessly across different screen sizes
- **Clean Interface**: Minimal, focused UI for optimal user experience

### 🚀 **Enhanced User Experience**

- **Real-time Face Detection**: Instant feedback when faces are detected
- **Progress Tracking**: Clear status updates during authentication process
- **Error Handling**: Comprehensive error handling and timeout management
- **Cross-platform Support**: Works on both iOS and Android
- **Easy Integration**: Simple API for quick implementation

### 🔧 **Developer Friendly**

- **Simple API**: Easy-to-use controller-based architecture
- **Customizable**: Configurable face detection parameters and UI styling
- **State Management**: Built-in state management with progress callbacks
- **Error Handling**: Comprehensive error handling and timeout management
- **Cross-platform**: Works on both iOS and Android

## 📱 Screenshots

_[Screenshots will be added here showing the face detection UI and authentication flow]_

## 🚀 Getting Started

### Prerequisites

- Flutter 3.0+
- Dart 2.17+
- Camera permissions
- Google ML Kit Face Detection
- TensorFlow Lite

### Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  face_recognition_auth: ^1.0.0
```

### Setup

1. **Add camera permissions** to your `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.CAMERA" />
```

2. **Add camera permissions** to your `ios/Runner/Info.plist`:

```xml
<key>NSCameraUsageDescription</key>
<string>This app needs camera access for face recognition authentication</string>
```

3. **Initialize the package** in your app:

```dart
import 'package:face_recognition_auth/face_recognition_auth.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await setupServices(); // If using the example setup
  runApp(MyApp());
}
```

## 💻 Usage

### Basic Face Registration

```dart
import 'package:face_recognition_auth/face_recognition_auth.dart';

class FaceRegistrationScreen extends StatefulWidget {
  @override
  _FaceRegistrationScreenState createState() => _FaceRegistrationScreenState();
}

class _FaceRegistrationScreenState extends State<FaceRegistrationScreen> {
  final FaceAuthController _controller = FaceAuthController();
  String _status = "Initializing...";

  @override
  void initState() {
    super.initState();
    _startRegistration();
  }

  Future<void> _startRegistration() async {
    await _controller.initialize();

    _controller.register(
      samples: 4,
      onProgress: (state) {
        setState(() {
          switch (state) {
            case FaceAuthState.cameraOpened:
              _status = "Camera Ready";
              break;
            case FaceAuthState.detectingFace:
              _status = "Looking for Face";
              break;
            case FaceAuthState.collectingSamples:
              _status = "Registering Face Data";
              break;
            case FaceAuthState.success:
              _status = "Registration Complete!";
              break;
            case FaceAuthState.failed:
              _status = "Registration Failed";
              break;
          }
        });
      },
      onDone: (user) {
        if (user != null) {
          print("User registered: ${user.id}");
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          FaceAuthView(controller: _controller),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              color: Colors.black54,
              padding: EdgeInsets.all(16),
              child: Text(
                _status,
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
```

### Face Authentication

```dart
class FaceLoginScreen extends StatefulWidget {
  @override
  _FaceLoginScreenState createState() => _FaceLoginScreenState();
}

class _FaceLoginScreenState extends State<FaceLoginScreen> {
  final FaceAuthController _controller = FaceAuthController();

  @override
  void initState() {
    super.initState();
    _startLogin();
  }

  Future<void> _startLogin() async {
    await _controller.initialize();

    _controller.login(
      onProgress: (state) {
        // Handle progress updates
      },
      onDone: (user) {
        if (user != null) {
          print("Login successful: ${user.id}");
          // Navigate to main app
        } else {
          print("Login failed");
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FaceAuthView(controller: _controller),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
```

### Custom Configuration

```dart
// Customize quality thresholds
_controller.register(
  samples: 6, // More samples for higher accuracy
  onProgress: (state) {
    // Custom progress handling
  },
  onDone: (user) {
    // Custom completion handling
  },
);
```

## 🎯 Advanced Features

### Face Detection Features

The package provides robust face detection capabilities:

- **Real-time Detection**: Instant face detection using Google ML Kit
- **Multiple Face Support**: Can detect and track multiple faces
- **Bounding Box Visualization**: Visual feedback with customizable face boxes
- **Camera Integration**: Seamless integration with device cameras

### UI Customization

```dart
// Customize face detection box styling
class CustomFaceBoxPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue // Custom color
      ..strokeWidth = 4     // Custom stroke width
      ..style = PaintingStyle.stroke;

    // Custom drawing logic
  }
}
```

### State Management

```dart
enum FaceAuthState {
  cameraOpened,
  detectingFace,
  collectingSamples,
  matching,
  success,
  failed,
  timeout,
}
```

## 📊 Performance

- **Fast Detection**: Real-time face detection with Google ML Kit
- **Efficient Processing**: TensorFlow Lite for optimized inference
- **Memory Optimized**: Smart memory management and resource disposal
- **Battery Friendly**: Optimized camera usage and processing

## 🔒 Security

- **Local Processing**: All face recognition happens locally on device
- **No Cloud Dependencies**: Face data never leaves the device
- **Secure Storage**: Encrypted local database for face embeddings
- **Privacy Focused**: No external API calls or data transmission

## 🛠️ API Reference

### FaceAuthController

Main controller for face authentication operations.

```dart
class FaceAuthController extends ChangeNotifier {
  Future<void> initialize();
  Future<void> register({int samples, Function onProgress, Function onDone});
  Future<void> login({Function onProgress, Function onDone});
  void dispose();
}
```

### FaceAuthView

UI component for displaying the camera feed and face detection.

```dart
class FaceAuthView extends StatelessWidget {
  final FaceAuthController controller;
  // ... other properties
}
```

### FaceAuthState

Enum representing different states of the authentication process.

```dart
enum FaceAuthState {
  cameraOpened,
  detectingFace,
  collectingSamples,
  matching,
  success,
  failed,
  timeout,
}
```

## 🤝 Contributing

We welcome contributions! Please feel free to submit a Pull Request. For major changes, please open an issue first to discuss what you would like to change.

### Development Setup

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 👥 Contributors

### Core Contributors

<table>
  <tr>
    <td align="center">
      <a href="https://github.com/mohadmed-adel">
        <img src="https://avatars.githubusercontent.com/mohadmed-adel" width="100px;" alt="Mohamed Adel"/>
        <br />
        <sub><b>Mohamed Adel</b></sub>
      </a>
      <br />
     <sub>Core Developer</sub>
      <br />
      <sub>Flutter & Android Expert</sub>
    </td>
    <td align="center">
      <a href="https://github.com/mahmoud0saad">
        <img src="https://avatars.githubusercontent.com/mahmoud0saad" width="100px;" alt="Mahmoud Saad"/>
        <br />
        <sub><b>Mahmoud Saad</b></sub>
      </a>
      <br />
      <sub>Core Developer</sub>
      <br />
      <sub>Flutter & Android Expert</sub>
    </td>
  </tr>
</table>

### Team Expertise

**Mohamed Adel** - Lead Developer & ML Specialist

- TensorFlow Lite integration and optimization
- Face recognition algorithms and ML models
- Package architecture and core implementation
- Documentation and technical writing

**Mahmoud Saad** - Core Developer & Flutter Expert

- Flutter development and cross-platform solutions
- Android native development and camera integration
- UI/UX implementation and state management
- Performance optimization and testing

### Contributing

We welcome contributions! Please see our [Contributing Guidelines](CONTRIBUTING.md) for details.

## 🙏 Acknowledgments

- **Google ML Kit** for face detection capabilities
- **TensorFlow Lite** for efficient face recognition
- **Flutter Team** for the amazing framework

## 📞 Support

- **Issues**: [GitHub Issues](https://github.com/mohadmed-adel/face_recognition_auth/issues)
- **Discussions**: [GitHub Discussions](https://github.com/mohadmed-adel/face_recognition_auth/discussions)
- **Repository**: [GitHub Repository](https://github.com/mohadmed-adel/face_recognition_auth)

## 🔄 Changelog

See [CHANGELOG.md](CHANGELOG.md) for a list of changes and version history.

---

**Made with ❤️ for the Flutter community**

Transform your app's authentication with reliable face recognition that's easy to implement and customize!

## 📦 Repository

This package is available on [pub.dev](https://pub.dev/packages/face_recognition_auth) and the source code is hosted on [GitHub](https://github.com/mohadmed-adel/face_recognition_auth).

### 📋 Requirements

- Flutter 3.0+
- Dart 2.17+
- Android API level 21+
- iOS 11.0+
