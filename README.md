# MathScribble AI 📐✨

MathScribble AI is an innovative Flutter application that transforms handwritten mathematical expressions into digital solutions using advanced AI recognition models. The app combines specialized handwriting recognition with powerful mathematical computation capabilities.

## Key Features 🌟

- **Smart Drawing Tools**: Multiple grid types (square, coordinate, isometric) with customizable colors and stroke widths
- **Real-time Recognition**: Instant conversion of handwritten mathematical expressions to digital format
- **Step-by-Step Solutions**: Detailed explanations and mathematical rules for each solution step
- **History & Progress Tracking**: Comprehensive history of solved problems with progress monitoring

<img src="https://github.com/user-attachments/assets/9c22e757-b992-47dd-a759-980e9fa7774d" alt="Home"  height="500"> <img src="https://github.com/user-attachments/assets/fb9edc33-8f03-49b8-8b6d-e3ed32ba114e" alt="Model"  height="500"> <img src="https://github.com/user-attachments/assets/c9030986-28e4-4f10-a565-6c3f1b51f523" alt="Canvas"  height="500"> <img src="https://github.com/user-attachments/assets/7c02f062-1cba-4f0e-a954-d44d59146cf7" alt="History"  height="500">

## Model Architecture 🧠

### Recognition and Solution Approaches

1. **Option 1: Gemini 2.0 Flash**
   - **Capabilities**: Both recognition and solving
   - Recognition through image analysis
   - Advanced problem-solving with step-by-step solutions
   - Comprehensive explanations of mathematical rules
   - API key rotation for scalability

2. **Option 2: Hybrid Approach**
   - **Recognition**: Handwriting API (specialized for math symbols)
   - **Solving**: Gemini 2.0 Flash
   - More focused recognition but potentially slower due to service switching

### Why Two Options?

1. **Flexibility**
   - Gemini provides an all-in-one solution
   - Handwriting API offers specialized recognition when needed
   - Users can choose based on their needs

2. **Scalability**
   - API key rotation system for Gemini
   - Load balancing between services
   - Fallback options available

3. **Reliability**
   - Multiple recognition paths
   - Robust error handling
   - Service redundancy

## Technical Implementation 💻

### Service Layer

```dart
class MixedHandwritingService extends AbstractMathService {
  late HandwritingApiService _handwritingService;
  late GeminiApiService _geminiService;
}
```

- Coordinates between services
- Handles initialization and error management
- Maintains state consistency

### Recognition Pipeline

1. Stroke Collection
2. Path Processing
3. Symbol Recognition (via chosen service)
4. LaTeX Conversion
5. Expression Standardization

### Solution Generation

1. Expression Parsing
2. Mathematical Analysis
3. Step Generation
4. Rule Identification
5. Result Verification

## Setup Instructions 🚀

### Prerequisites

- Flutter SDK (Latest stable version)
- Dart SDK (Latest stable version)
- Android Studio / VS Code with Flutter extensions
- API Keys (Handwriting API and Gemini)

### Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/your-username/mathscribble-ai.git
   cd mathscribble-ai
   ```

2. Set up environment variables:
   
   Create a `.env` file in the root directory:
   ```env
   # Multiple Gemini API keys for rotation (comma-separated)
   GEMINI_API_KEYS=key1,key2,key3,key4

   # Handwriting API token
   HANDWRITING_API_TOKEN=your_handwriting_api_token
   ```

3. Create environment configuration file (`lib/config/env_config.dart`):
   ```dart
   import 'package:flutter_dotenv/flutter_dotenv.dart';

   class EnvConfig {
     static List<String> get geminiApiKeys {
       final keys = dotenv.env['GEMINI_API_KEYS']?.split(',') ?? [];
       return keys.map((key) => key.trim()).toList();
     }

     static String get handwritingApiToken {
       return dotenv.env['HANDWRITING_API_TOKEN'] ?? '';
     }
   }
   ```

4. Add to .gitignore:
   ```
   .env
   ```

5. Install dependencies:
   ```bash
   flutter pub get
   ```

6. Run the app:
   ```bash
   flutter run
   ```

### Configuration

- Adjust API key rotation settings in `GeminiApiService`
- Configure cooldown periods for rate limiting
- Customize recognition parameters in `HandwritingApiService`

## Innovation Assessment 🎯

1. **Flexible Architecture**
   - Multiple recognition options
   - Service switching capability
   - Robust error handling

2. **Scalability Features**
   - API key rotation system
   - Cooldown management
   - Load distribution

3. **User Experience**
   - Real-time recognition
   - Intuitive drawing tools
   - Comprehensive solution explanations

4. **Technical Innovation**
   - Custom path processing
   - Advanced symbol recognition
   - Intelligent error recovery

## Future Enhancements 🔮

1. **Offline Mode**
   - Local model integration
   - Cached solutions
   - Sync mechanism

2. **Advanced Features**
   - Multi-language support
   - Graph plotting
   - Problem generation

3. **Performance Optimization**
   - Enhanced caching
   - Batch processing
   - Memory optimization

## Contributing 🤝

We welcome contributions! Please read our contributing guidelines and submit pull requests for any enhancements.

## License 📄

This project is licensed under the MIT License - see the LICENSE file for details.
