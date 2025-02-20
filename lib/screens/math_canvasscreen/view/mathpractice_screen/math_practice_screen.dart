import 'package:flutter/material.dart';
import '../../model/math_history_model.dart';
import '../../services/history_persistence_service.dart';
import '../../widgets/drawing_canvas.dart';
import '../mathhistory_screen/math_history_screen.dart';

class MathPracticeScreen extends StatefulWidget {
  const MathPracticeScreen({super.key});

  @override
  State<MathPracticeScreen> createState() => _MathPracticeScreenState();
}

class _MathPracticeScreenState extends State<MathPracticeScreen> {
  final HistoryPersistenceService _historyService = HistoryPersistenceService();
  List<MathHistoryItem> history = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final loadedHistory = await _historyService.loadHistory();
    setState(() {
      history = loadedHistory;
    });
  }

  Future<void> addToHistory(MathHistoryItem item) async {
    setState(() {
      history.insert(0, item);
    });
    await _historyService.saveHistory(history);
  }

  Future<void> _updateHistory(List<MathHistoryItem> newHistory) async {
    setState(() {
      history = newHistory;
    });
    await _historyService.saveHistory(newHistory);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.blue.shade50,
              Colors.purple.shade50,
              Colors.white,
            ],
            stops: const [0.0, 0.3, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(context),
              Expanded(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.shade100.withOpacity(0.2),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: DrawingCanvas(onHistoryItemAdded: addToHistory),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Hero(
            tag: 'app_logo',
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.shade100.withOpacity(0.3),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Image.asset(
                "assets/images/mathlogo.png",
                height: 28,
                color: const Color(0xFF3F51B5),
              ),
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Text(
              'MathScribe AI',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1A237E),
              ),
            ),
          ),
          _buildHistoryButton(context),
        ],
      ),
    );
  }

  Widget _buildHistoryButton(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.shade100.withOpacity(0.3),
            blurRadius: 8,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: IconButton(
          icon: const Icon(
            Icons.history,
            color: Color(0xFF3F51B5),
            size: 24,
          ),
          tooltip: 'View History',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => MathHistoryScreen(
                  history: history,
                  onHistoryChanged: _updateHistory,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
