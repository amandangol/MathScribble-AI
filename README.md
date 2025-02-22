# MathScribble AI ✨

MathScribble AI is an innovative Flutter application that transforms handwritten mathematical expressions into digital solutions using advanced AI recognition models. The app combines specialized handwriting recognition with powerful mathematical computation capabilities.

## Key Features 🌟

- **Smart Drawing Tools**: Multiple grid types (square, coordinate, isometric) with customizable colors and stroke widths
- **Real-time Recognition**: Instant conversion of handwritten mathematical expressions to digital format
- **Step-by-Step Solutions**: Detailed explanations and mathematical rules for each solution step
- **History & Progress Tracking**: Comprehensive history of solved problems with progress monitoring

  <img src="https://github.com/user-attachments/assets/975b1024-aa79-44f4-beb6-053fdd9d2c68" alt="Home"  height="500">


## Model Architecture 🧠

### Hybrid Recognition Approach

We implement a hybrid approach using two specialized services:

1. **Handwriting Recognition Service**
   - Primary: Custom Handwriting API
   - Optimized for mathematical symbol recognition
   - Handles complex mathematical notation and symbols
   - Real-time stroke processing and path analysis
   - Support for LaTeX conversion and standardization

2. **Mathematical Computation Service**
   - Primary: Gemini 2.0 Flash
   - Advanced problem-solving capabilities
   - Step-by-step solution generation
   - Mathematical rule explanation
   - API key rotation for scalability

### Why This Architecture?

1. **Specialized Expertise**
   - Handwriting API focuses on accurate symbol recognition
   - Gemini handles complex mathematical reasoning along with symbol recognition
   - Better results than using a single model for both tasks

2. **Scalability**
   - API key rotation system for handling high traffic
   - Cooldown periods prevent rate limiting
   - Efficient error handling and recovery

3. **Reliability**
   - Fallback mechanisms between services
   - Robust error handling
   - Consistent performance under load

## Technical Implementation 💻

### Service Layer

```dart
class MixedHandwritingService extends AbstractMathService {
  late HandwritingApiService _handwritingService;
  late GeminiApiService _geminiService;
}
```

- Coordinates between recognition and solving services
- Handles initialization and error management
- Maintains state consistency

### Recognition Pipeline

1. Stroke Collection
2. Path Processing
3. Symbol Recognition
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

2. Create an environment configuration file (`lib/config/env_config.dart`):
   ```dart
   class EnvConfig {
     static const String handwritingApiToken = 'YOUR_HANDWRITING_API_TOKEN';
     static const List<String> geminiApiKeys = ['KEY1', 'KEY2', 'KEY3'];
   }
   ```

3. Install dependencies:
   ```bash
   flutter pub get
   ```

4. Run the app:
   ```bash
   flutter run
   ```

### Configuration

- Adjust API key rotation settings in `GeminiApiService`
- Configure cooldown periods for rate limiting
- Customize recognition parameters in `HandwritingApiService`

## Innovation Assessment 🎯

1. **Hybrid Architecture**
   - Specialized services for optimal performance
   - Efficient resource utilization
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
