import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:onnxruntime/onnxruntime.dart';
import 'package:image/image.dart' as img;

class MathCanvas extends StatefulWidget {
  const MathCanvas({super.key});

  @override
  State<MathCanvas> createState() => _MathCanvasState();
}

class _MathCanvasState extends State<MathCanvas> {
  List<List<Offset>> strokes = [];
  List<Offset> currentStroke = [];
  late String _version;
  OrtSession? _encoderSession;
  OrtSession? _decoderSession;
  Map<String, dynamic>? _tokenizerConfig;
  Map<String, dynamic>? _specialTokensMap;
  Map<String, int>? _tokenToId;
  Map<int, String>? _idToToken;
  String recognizedText = '';
  bool isRecognizing = false;

  @override
  void initState() {
    super.initState();
    _version = OrtEnv.version;
    initializeModel();
  }

  Future<void> initializeModel() async {
    try {
      final sessionOptions = OrtSessionOptions();

      // Load encoder model
      final encoderBytes = await rootBundle.load('assets/encoder_model.onnx');
      _encoderSession = OrtSession.fromBuffer(
          encoderBytes.buffer.asUint8List(), sessionOptions);

      // Load decoder model
      final decoderBytes = await rootBundle.load('assets/decoder_model.onnx');
      _decoderSession = OrtSession.fromBuffer(
          decoderBytes.buffer.asUint8List(), sessionOptions);

      // Load tokenizer configuration
      await loadTokenizerConfig();

      print('Models loaded successfully');
      print('Encoder Input Names: ${_encoderSession!.inputNames}');
      print('Encoder Output Names: ${_encoderSession!.outputNames}');
      print('Decoder Input Names: ${_decoderSession!.inputNames}');
      print('Decoder Output Names: ${_decoderSession!.outputNames}');
    } catch (e) {
      print('Error initializing models: $e');
    }
  }

  Future<void> loadTokenizerConfig() async {
    try {
      // Load configuration files
      final tokenizer = await rootBundle.loadString('assets/tokenizer.json');
      final specialTokens =
          await rootBundle.loadString('assets/special_tokens_map.json');

      _tokenizerConfig = json.decode(tokenizer);
      _specialTokensMap = json.decode(specialTokens);

      // Get the vocabulary from the correct location
      if (_tokenizerConfig!.containsKey('model') &&
          _tokenizerConfig!['model'].containsKey('vocab')) {
        _tokenToId = Map<String, int>.from(_tokenizerConfig!['model']['vocab']);
      } else {
        throw Exception('Could not find vocabulary in tokenizer config');
      }

      // Create reverse mapping
      _idToToken = _tokenToId!.map((k, v) => MapEntry(v, k));

      // Print debug info
      print('Loaded vocabulary size: ${_tokenToId!.length}');

      // Verify each special token
      for (var entry in _specialTokensMap!.entries) {
        final tokenContent =
            (entry.value as Map<String, dynamic>)['content'] as String;
        final tokenId = _tokenToId![tokenContent];
        print(
            'Special token ${entry.key}: content="$tokenContent", ID=$tokenId');
      }
    } catch (e, stackTrace) {
      print('Error loading tokenizer config: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  String decodeTokens(List<int> tokens) {
    // Get special token contents
    final bosContent = (_specialTokensMap?['bos_token']
        as Map<String, dynamic>)['content'] as String?;
    final eosContent = (_specialTokensMap?['eos_token']
        as Map<String, dynamic>)['content'] as String?;
    final padContent = (_specialTokensMap?['pad_token']
        as Map<String, dynamic>)['content'] as String?;

    final filteredTokens = tokens.where((id) {
      final token = _idToToken?[id];
      return token != bosContent && token != eosContent && token != padContent;
    });

    return filteredTokens.map((id) => _idToToken?[id] ?? '').join('');
  }

  Future<void> recognizeMath() async {
    if (_encoderSession == null || _decoderSession == null || strokes.isEmpty) {
      return;
    }

    setState(() {
      isRecognizing = true;
      recognizedText = 'Recognizing...';
    });

    try {
      // Convert strokes to image
      final image = await strokesToImage();

      // Process the image
      final processedTensor = await preprocessImage(image);

      // Run encoder inference
      final encoderOutput = await runEncoder(processedTensor);

      // Run decoder for text generation
      final result = await generateText(encoderOutput);

      setState(() {
        recognizedText = result;
      });
    } catch (e, stackTrace) {
      print('Recognition error: $e');
      print('Stack trace: $stackTrace');
      setState(() {
        recognizedText = 'Recognition failed: $e';
      });
    } finally {
      setState(() {
        isRecognizing = false;
      });
    }
  }

  Future<Float32List> preprocessImage(ui.Image image) async {
    final ByteData? byteData =
        await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) throw Exception('Failed to get image data');

    final pixels = byteData.buffer.asUint8List();
    final decodedImage = img.decodePng(pixels);
    if (decodedImage == null) throw Exception('Failed to decode image');

    var processedImage = img.copyResize(decodedImage, width: 384, height: 384);

    // Convert to RGB if needed
    if (processedImage.numChannels != 3) {
      // processedImage = img.convertImage(processedImage, numChannels: 3);
    }

    final tensorData = Float32List(1 * 3 * 384 * 384);
    int index = 0;
    for (int c = 0; c < 3; c++) {
      for (int h = 0; h < 384; h++) {
        for (int w = 0; w < 384; w++) {
          final pixel = processedImage.getPixel(w, h);
          double value;
          if (c == 0) {
            value = pixel.r / 255.0;
          } else if (c == 1)
            value = pixel.g / 255.0;
          else
            value = pixel.b / 255.0;
          value = (value - 0.5) / 0.5;
          tensorData[index++] = value;
        }
      }
    }

    return tensorData;
  }

  Future<Map<String, dynamic>> runEncoder(Float32List imageData) async {
    final inputTensor =
        OrtValueTensor.createTensorWithDataList(imageData, [1, 3, 384, 384]);

    try {
      final runOptions = OrtRunOptions();
      final inputs = {'pixel_values': inputTensor};
      final outputs = _encoderSession!.run(runOptions, inputs);

      if (outputs.isEmpty) throw Exception('No output from encoder');

      // Get the actual dimensions from the encoder output
      final hiddenStates = outputs[0]!.value as List<List<List<double>>>;
      print(
          'Encoder output dimensions: ${hiddenStates.length}x${hiddenStates[0].length}x${hiddenStates[0][0].length}');

      return {
        'last_hidden_state': hiddenStates,
      };
    } finally {
      inputTensor.release();
    }
  }

  Future<String> generateText(Map<String, dynamic> encoderOutputs) async {
    final bosTokenMap =
        _specialTokensMap?['bos_token'] as Map<String, dynamic>?;
    if (bosTokenMap == null) {
      throw Exception('BOS token not found in special tokens map');
    }

    final bosTokenContent = bosTokenMap['content'] as String?;
    if (bosTokenContent == null) {
      throw Exception('BOS token content not found');
    }

    final startId = _tokenToId?[bosTokenContent];
    if (startId == null) {
      throw Exception('Start token ID not found for token: $bosTokenContent');
    }

    List<int> generatedIds = [startId];
    const maxLength = 200;

    try {
      final encoderHiddenStates =
          encoderOutputs['last_hidden_state'] as List<List<List<double>>>;

      // Create a resized version of the hidden states to match the expected dimensions
      final List<List<List<double>>> resizedHiddenStates = [];

      // Assuming we want to keep the first dimension (batch) and second dimension (sequence length)
      // but need to adjust the third dimension (feature size) to 384
      for (var batch in encoderHiddenStates) {
        final List<List<double>> resizedBatch = [];
        for (var seq in batch) {
          // Resize the feature vector from 578 to 384
          // Method 1: Truncation
          final resizedFeatures = seq.take(384).toList();
          // Method 2: Average pooling (alternative approach)
          // final resizedFeatures = resizeFeatureVector(seq, 384);

          while (resizedFeatures.length < 384) {
            resizedFeatures.add(0.0); // Pad with zeros if necessary
          }

          resizedBatch.add(resizedFeatures);
        }
        resizedHiddenStates.add(resizedBatch);
      }

      while (generatedIds.length < maxLength) {
        final inputIds = Int64List.fromList(generatedIds);
        final inputTensor = OrtValueTensor.createTensorWithDataList(
            inputIds, [1, generatedIds.length]);

        final flattenedStates = resizedHiddenStates
            .expand((row) => row.expand((col) => col))
            .toList();

        final encoderTensor = OrtValueTensor.createTensorWithDataList(
            Float32List.fromList(flattenedStates), [
          1,
          resizedHiddenStates[0].length,
          384
        ]); // Using fixed dimension of 384

        final inputs = {
          'input_ids': inputTensor,
          'encoder_hidden_states': encoderTensor,
        };

        final outputs = _decoderSession!.run(OrtRunOptions(), inputs);
        final logits = outputs[0]!.value as List<List<List<double>>>;

        final nextTokenId = getNextToken(logits[0][generatedIds.length - 1]);

        final eosTokenMap =
            _specialTokensMap?['eos_token'] as Map<String, dynamic>?;
        final eosTokenContent = eosTokenMap?['content'] as String?;
        if (eosTokenContent != null &&
            nextTokenId == _tokenToId?[eosTokenContent]) {
          break;
        }

        generatedIds.add(nextTokenId);

        inputTensor.release();
        encoderTensor.release();
      }

      return decodeTokens(generatedIds);
    } catch (e, stackTrace) {
      print('Generation error: $e');
      print('Stack trace: $stackTrace');
      return 'Generation failed';
    }
  }

// Helper function for average pooling if needed
  List<double> resizeFeatureVector(List<double> original, int newSize) {
    if (original.length == newSize) return original;

    final List<double> resized = List.filled(newSize, 0.0);
    final double ratio = original.length / newSize;

    for (int i = 0; i < newSize; i++) {
      final double start = i * ratio;
      final double end = start + ratio;

      double sum = 0.0;
      int count = 0;

      for (int j = start.floor(); j < end.ceil() && j < original.length; j++) {
        sum += original[j];
        count++;
      }

      resized[i] = count > 0 ? sum / count : 0.0;
    }

    return resized;
  }

  int getNextToken(List<double> logits) {
    // Simple argmax implementation
    int maxIndex = 0;
    double maxValue = logits[0];

    for (int i = 1; i < logits.length; i++) {
      if (logits[i] > maxValue) {
        maxValue = logits[i];
        maxIndex = i;
      }
    }

    return maxIndex;
  }

  Future<ui.Image> strokesToImage() async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // Set white background
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawRect(const Rect.fromLTWH(0, 0, 384, 384), paint);

    // Draw strokes in black
    paint
      ..color = Colors.black
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Scale strokes to fit 384x384
    const scaleX = 384 / 640;
    const scaleY = 384 / 480;

    for (var stroke in strokes) {
      if (stroke.length < 2) continue;

      final path = Path();
      path.moveTo(stroke[0].dx * scaleX, stroke[0].dy * scaleY);

      for (int i = 1; i < stroke.length; i++) {
        path.lineTo(stroke[i].dx * scaleX, stroke[i].dy * scaleY);
      }

      canvas.drawPath(path, paint);
    }

    final picture = recorder.endRecording();
    return picture.toImage(384, 384);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Math Recognition'),
      ),
      body: Column(
        children: [
          Text(
            'ONNX Runtime Version: $_version',
            style: const TextStyle(fontSize: 16),
          ),
          Expanded(
            flex: 3,
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
              ),
              child: GestureDetector(
                onPanStart: (details) {
                  setState(() {
                    currentStroke = [details.localPosition];
                  });
                },
                onPanUpdate: (details) {
                  setState(() {
                    currentStroke.add(details.localPosition);
                  });
                },
                onPanEnd: (_) {
                  setState(() {
                    if (currentStroke.length > 1) {
                      strokes.add(List.from(currentStroke));
                    }
                    currentStroke = [];
                  });
                },
                child: CustomPaint(
                  painter: StrokePainter(
                    strokes: strokes,
                    currentStroke: currentStroke,
                  ),
                  size: Size.infinite,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'Recognized Text: $recognizedText',
              style: const TextStyle(fontSize: 18),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: isRecognizing ? null : recognizeMath,
                child: const Text('Recognize'),
              ),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    strokes = [];
                    recognizedText = '';
                  });
                },
                child: const Text('Clear'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _encoderSession?.release();
    _decoderSession?.release();
    super.dispose();
  }
}

class StrokePainter extends CustomPainter {
  final List<List<Offset>> strokes;
  final List<Offset> currentStroke;

  const StrokePainter({
    required this.strokes,
    required this.currentStroke,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    for (var stroke in strokes) {
      if (stroke.length < 2) continue;
      final path = Path()..addPolygon(stroke, false);
      canvas.drawPath(path, paint);
    }

    if (currentStroke.length > 1) {
      final path = Path()..addPolygon(currentStroke, false);
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(StrokePainter oldDelegate) => true;
}
