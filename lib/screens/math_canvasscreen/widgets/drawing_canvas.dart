import 'package:flutter/material.dart';
import 'package:mathscribble_ai/screens/math_canvasscreen/services/math_recognition_factory.dart';
import '../../../utils/snackbar_utils.dart';
import '../../dashboardscreen/model/recognition_model.dart';
import '../model/math_history_model.dart';
import '../model/math_solution_model.dart';
import '../services/abstract_math_service.dart';
import 'painters/drawing_painter.dart';
import 'painters/guidelines_painter.dart';
import '../../../utils/custom_loading_overlay.dart';
import 'result_area.dart';

class DrawingCanvas extends StatefulWidget {
  final Function(MathHistoryItem) onHistoryItemAdded;
  RecognitionModel selectedModel;

  DrawingCanvas({
    super.key,
    required this.onHistoryItemAdded,
    required this.selectedModel,
  });

  @override
  State<DrawingCanvas> createState() => _DrawingCanvasState();
}

class _DrawingCanvasState extends State<DrawingCanvas>
    with TickerProviderStateMixin {
  List<DrawingPoint?> points = [];
  String recognizedTeX = '';
  bool isLoading = false;
  Color currentColor = const Color(0xFF3F51B5);
  double currentStrokeWidth = 2.0;
  String currentTool = 'pen';
  List<List<DrawingPoint?>> undoHistory = [];
  List<List<DrawingPoint?>> redoHistory = [];
  MathSolution? solvedResult;
  String loadingType = '';
  bool isToolsVisible = false;
  late final AbstractMathService _mathService;

  late AnimationController _toolsController;
  late Animation<double> _toolsScaleAnimation;

  final double eraserSizeMultiplier = 8.0;

  final List<Color> colorOptions = [
    const Color(0xFF3F51B5),
    const Color(0xFF1A237E),
    Colors.black,
    const Color(0xFF4CAF50),
    const Color(0xFFF44336),
  ];

  String currentGridType = 'none';
  final List<String> gridOptions = [
    'none',
    'square',
    'coordinate',
    'isometric'
  ];

  @override
  void initState() {
    super.initState();
    _initializeService();
    _initializeAnimations();
  }

  Future<void> _initializeService() async {
    _mathService = MathRecognitionFactory.createService(widget.selectedModel);
    await _mathService.initialize();
  }

  @override
  void didUpdateWidget(DrawingCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedModel != widget.selectedModel) {
      _initializeService();
    }
  }

  void _initializeAnimations() {
    _toolsController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _toolsScaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _toolsController,
      curve: Curves.easeOutBack,
    ));
  }

  @override
  void dispose() {
    _toolsController.dispose();
    super.dispose();
  }

  void _toggleTools() {
    setState(() {
      isToolsVisible = !isToolsVisible;
      if (isToolsVisible) {
        _toolsController.forward();
      } else {
        _toolsController.reverse();
      }
    });
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Color(0xFF3F51B5)),
        onPressed: () => Navigator.pop(context),
      ),
      centerTitle: false,
      title: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.selectedModel.emoji,
            style: const TextStyle(fontSize: 20),
          ),
          const SizedBox(width: 8),
          Text(
            widget.selectedModel.name,
            style: const TextStyle(
              fontFamily: 'Outfit',
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A237E),
            ),
          ),
        ],
      ),
      actions: [
        _buildHeaderButton(
          icon: Icons.undo,
          onPressed: undoHistory.isEmpty ? null : undo,
          tooltip: 'Undo',
        ),
        _buildHeaderButton(
          icon: Icons.redo,
          onPressed: redoHistory.isEmpty ? null : redo,
          tooltip: 'Redo',
        ),
        _buildHeaderButton(
          icon: Icons.delete_outline,
          onPressed: clearCanvas,
          tooltip: 'Clear',
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F3FF),
      appBar: _buildAppBar(),
      body: Stack(
        children: [
          // Main drawing container
          _buildDrawingContainer(),

          // Loading overlay
          if (isLoading) CustomLoadingOverlay(loadingType: loadingType),

          // Tools Panel
          if (isToolsVisible)
            Positioned(
              bottom: recognizedTeX.isNotEmpty ? 200 : 100,
              right: 16,
              child: ScaleTransition(
                scale: _toolsScaleAnimation,
                child: _buildToolsPanel(),
              ),
            ),

          // FAB
          Positioned(
            bottom: recognizedTeX.isNotEmpty ? 200 : 100,
            right: 16,
            child: FloatingActionButton(
              onPressed: _toggleTools,
              backgroundColor: const Color(0xFF3F51B5),
              child: Icon(
                isToolsVisible ? Icons.close : Icons.brush,
                color: Colors.white,
              ),
            ),
          ),

          // Bottom Result Area
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildBottomControls(),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawingContainer() {
    return Container(
      margin: const EdgeInsets.fromLTRB(6, 8, 6, 100),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3F51B5).withOpacity(0.08),
            spreadRadius: 0,
            blurRadius: 20,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Stack(
        children: [
          // Grid type indicator
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF3F51B5).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.grid_on,
                    size: 16,
                    color: Color(0xFF3F51B5),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    currentGridType.toUpperCase(),
                    style: const TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 14,
                      color: Color(0xFF3F51B5),
                    ),
                  ),
                ],
              ),
            ),
          ),

          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              children: [
                // Grid background
                if (currentGridType != 'none')
                  CustomPaint(
                    painter: GuidelinesPainter(
                      gridType: currentGridType,
                      primaryColor: const Color(0xFF3F51B5).withOpacity(0.1),
                      secondaryColor: const Color(0xFF3F51B5).withOpacity(0.05),
                    ),
                    child: Container(),
                  ),

                // Drawing area
                GestureDetector(
                  onPanStart: onPanStart,
                  onPanUpdate: onPanUpdate,
                  onPanEnd: onPanEnd,
                  child: CustomPaint(
                    painter: DrawingPainter(
                      points: points,
                      color: currentColor,
                      strokeWidth: currentStrokeWidth,
                    ),
                    child: Container(),
                  ),
                ),

                // Empty state overlay
                if (points.isEmpty)
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.edit_outlined,
                          size: 48,
                          color: const Color(0xFF3F51B5).withOpacity(0.3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Start writing your expression',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 16,
                            color: const Color(0xFF3F51B5).withOpacity(0.5),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolsPanel() {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildToolButtons(),
            const Divider(height: 24),
            _buildColorPalette(),
            const Divider(height: 24),
            _buildStrokeWidth(),
            const Divider(height: 24),
            _buildGridOptions(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderButton({
    required IconData icon,
    required VoidCallback? onPressed,
    required String tooltip,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Tooltip(
        message: tooltip,
        child: IconButton(
          icon: Icon(icon),
          onPressed: onPressed,
          color: const Color(0xFF3F51B5),
          style: IconButton.styleFrom(
            backgroundColor: onPressed == null
                ? Colors.grey.withOpacity(0.1)
                : const Color(0xFF3F51B5).withOpacity(0.1),
          ),
        ),
      ),
    );
  }

  Widget _buildToolButtons() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildToolButton(
          icon: Icons.edit,
          tool: 'pen',
          tooltip: 'Pen',
        ),
        const SizedBox(width: 8),
        _buildToolButton(
          icon: Icons.auto_fix_high,
          tool: 'eraser',
          tooltip: 'Eraser',
        ),
      ],
    );
  }

  Widget _buildColorPalette() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: colorOptions.map((color) {
        return GestureDetector(
          onTap: () => setState(() => currentColor = color),
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: currentColor == color
                    ? const Color(0xFF3F51B5)
                    : Colors.transparent,
                width: 2,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildStrokeWidth() {
    return SizedBox(
      width: 200,
      child: Slider(
        value: currentStrokeWidth,
        min: 1.0,
        max: 10.0,
        divisions: 9,
        onChanged: (value) => setState(() => currentStrokeWidth = value),
      ),
    );
  }

  Widget _buildGridOptions() {
    return Column(
      children: [
        for (String type in gridOptions)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: GestureDetector(
              onTap: () => setState(() => currentGridType = type),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: currentGridType == type
                      ? const Color(0xFF3F51B5)
                      : const Color(0xFF3F51B5).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  type.toUpperCase(),
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 12,
                    color: currentGridType == type
                        ? Colors.white
                        : const Color(0xFF3F51B5),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildBottomControls() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3F51B5).withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (recognizedTeX.isNotEmpty)
              ResultArea(
                expression: recognizedTeX,
                solution: solvedResult,
                onSolve: () => solveExpression(recognizedTeX),
                onClear: () => setState(() {
                  recognizedTeX = '';
                  solvedResult = null;
                }),
              ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: recognizeHandwriting,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3F51B5),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Recognize Expression',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolButton({
    required IconData icon,
    required String tool,
    required String tooltip,
  }) {
    final bool isSelected = currentTool == tool;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Tooltip(
        message: tooltip,
        child: IconButton(
          icon: Icon(icon),
          color: isSelected ? const Color(0xFF3F51B5) : Colors.grey,
          style: IconButton.styleFrom(
            backgroundColor: isSelected
                ? const Color(0xFF3F51B5).withOpacity(0.1)
                : Colors.transparent,
          ),
          onPressed: () => setState(() => currentTool = tool),
        ),
      ),
    );
  }

  void onPanStart(DragStartDetails details) {
    if (currentTool != 'pan') {
      setState(() {
        undoHistory.add(List.from(points));
        redoHistory.clear();
        points.add(
          DrawingPoint(
            point: details.localPosition,
            color: currentTool == 'eraser' ? Colors.white : currentColor,
            strokeWidth: currentTool == 'eraser'
                ? currentStrokeWidth * eraserSizeMultiplier
                : currentStrokeWidth,
          ),
        );
      });
    }
  }

  void onPanUpdate(DragUpdateDetails details) {
    if (currentTool != 'pan') {
      setState(() {
        points.add(
          DrawingPoint(
            point: details.localPosition,
            color: currentTool == 'eraser' ? Colors.white : currentColor,
            strokeWidth: currentTool == 'eraser'
                ? currentStrokeWidth * eraserSizeMultiplier
                : currentStrokeWidth,
          ),
        );
      });
    }
  }

  void onPanEnd(DragEndDetails details) {
    if (currentTool != 'pan') {
      setState(() {
        points.add(null);
      });
    }
  }

  void undo() {
    if (undoHistory.isEmpty) return;
    setState(() {
      redoHistory.add(List.from(points));
      points = List.from(undoHistory.last);
      undoHistory.removeLast();
    });
  }

  void redo() {
    if (redoHistory.isEmpty) return;
    setState(() {
      undoHistory.add(List.from(points));
      points = List.from(redoHistory.last);
      redoHistory.removeLast();
    });
  }

  void clearCanvas() {
    setState(() {
      undoHistory.add(List.from(points));
      redoHistory.clear();
      points.clear();
      recognizedTeX = '';
      solvedResult = null;
    });
  }

  Future<void> recognizeHandwriting() async {
    if (points.isEmpty) {
      SnackBarUtils.showCustomSnackBar(
        context,
        message: 'Please write something first',
      );
      return;
    }

    setState(() {
      isLoading = true;
      loadingType = "recognizing";
    });

    try {
      final result = await _mathService.recognizeExpression(context, points);
      setState(() {
        recognizedTeX = result['standardized'] ?? '';
      });
    } catch (e) {
      SnackBarUtils.showCustomSnackBar(
        context,
        message: 'Recognition error: ${e.toString()}',
        isError: true,
      );
    } finally {
      setState(() {
        isLoading = false;
        loadingType = '';
      });
    }
  }

  Future<void> solveExpression(String expression) async {
    setState(() {
      isLoading = true;
      loadingType = 'solving';
    });

    try {
      final result = await _mathService.solveExpression(expression);
      setState(() {
        solvedResult = result;
      });

      widget.onHistoryItemAdded(
        MathHistoryItem(
          expression: expression,
          solution: result.result,
          steps: result.steps,
          rules: result.rules,
          timestamp: DateTime.now(),
        ),
      );
    } catch (e) {
      SnackBarUtils.showCustomSnackBar(
        context,
        message: 'Error solving expression: ${e.toString()}',
        isError: true,
      );
    } finally {
      setState(() {
        isLoading = false;
        loadingType = '';
      });
    }
  }
}
