import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../model/math_history_model.dart';
import '../../services/history_persistence_service.dart';

class MathHistoryScreen extends StatefulWidget {
  final List<MathHistoryItem> history;
  final Function(List<MathHistoryItem>) onHistoryChanged;

  const MathHistoryScreen({
    super.key,
    required this.history,
    required this.onHistoryChanged,
  });

  @override
  State<MathHistoryScreen> createState() => _MathHistoryScreenState();
}

class _MathHistoryScreenState extends State<MathHistoryScreen> {
  final HistoryPersistenceService _persistenceService =
      HistoryPersistenceService();
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  late List<MathHistoryItem> _localHistory;

  @override
  void initState() {
    super.initState();
    _localHistory = List.from(widget.history);
  }

  @override
  void didUpdateWidget(MathHistoryScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.history != oldWidget.history) {
      _localHistory = List.from(widget.history);
    }
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
                child: widget.history.isEmpty
                    ? _buildEmptyState()
                    : _buildAnimatedHistoryList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Hero(
            tag: 'back_button',
            child: Material(
              color: Colors.transparent,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.shade100.withOpacity(0.3),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Icon(Icons.arrow_back, color: Colors.blue.shade600),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Text(
            'Recognition History',
            style: TextStyle(
              fontFamily: 'Rubik',
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const Spacer(),
          if (_localHistory.isNotEmpty)
            TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 300),
              tween: Tween(begin: 0.0, end: 1.0),
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: child,
                );
              },
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.shade100.withOpacity(0.3),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => _showClearHistoryDialog(context),
                  tooltip: 'Clear History',
                  color: Colors.red.shade400,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSolutionSection(String title, String content) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontFamily: 'Rubik',
              fontSize: 14,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: TextStyle(
              fontFamily: 'Rubik',
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: title == 'Result' ? Colors.green[700] : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepItem(int index, String step) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.blue[100],
              shape: BoxShape.circle,
            ),
            child: Text(
              '$index',
              style: TextStyle(
                fontFamily: 'Rubik',
                fontWeight: FontWeight.w500,
                color: Colors.blue[900],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              step,
              style: TextStyle(
                fontFamily: 'Rubik',
                fontSize: 15,
                color: Colors.blue[900],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRuleItem(String rule) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.purple[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 20, color: Colors.purple[400]),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              rule,
              style: TextStyle(
                fontFamily: 'Rubik',
                fontSize: 14,
                color: Colors.purple[900],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(MathHistoryItem item) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showSolutionBottomSheet(item),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.functions,
                        color: Colors.blue.shade600, size: 16),
                  ),
                  const SizedBox(width: 12),
                  // Expression text
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Expression',
                          style: TextStyle(
                            fontFamily: 'Rubik',
                            fontSize: 13,
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.expression,
                          style: const TextStyle(
                            fontFamily: 'Rubik',
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _formatDate(item.timestamp),
                      style: TextStyle(
                        fontFamily: 'Rubik',
                        color: Colors.grey[700],
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              if (item.solution != null) ...[
                const SizedBox(height: 12),
                Divider(height: 1, thickness: 1, color: Colors.grey[200]),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.check_circle,
                          color: Colors.green.shade600, size: 16),
                    ),
                    const SizedBox(width: 12),
                    // Solution text
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Solution',
                            style: TextStyle(
                              fontFamily: 'Rubik',
                              fontSize: 13,
                              color: Colors.grey[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.solution!,
                            style: TextStyle(
                              fontFamily: 'Rubik',
                              fontSize: 15,
                              color: Colors.green[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (item.steps != null && item.steps!.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.touch_app,
                              size: 14, color: Colors.blue[600]),
                          const SizedBox(width: 6),
                          Text(
                            'Tap to view solution steps',
                            style: TextStyle(
                              fontFamily: 'Rubik',
                              fontSize: 10,
                              letterSpacing: 1,
                              color: Colors.blue[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showSolutionBottomSheet(MathHistoryItem item) {
    print('Steps: ${item.steps}'); // Debug print
    print('Rules: ${item.rules}'); // Debug print

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  children: [
                    Text(
                      'Step by Step Solution',
                      style: TextStyle(
                        fontFamily: 'Rubik',
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildSolutionSection('Expression', item.expression),
                    if (item.solution != null)
                      _buildSolutionSection('Result', item.solution!),
                    if (item.steps != null && item.steps!.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      Text(
                        'Solution Steps',
                        style: TextStyle(
                          fontFamily: 'Rubik',
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...item.steps!.asMap().entries.map((entry) {
                        return _buildStepItem(entry.key + 1, entry.value);
                      }).toList(),
                    ],
                    if (item.rules != null && item.rules!.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      Text(
                        'Rules Applied',
                        style: TextStyle(
                          fontFamily: 'Rubik',
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...item.rules!.map(_buildRuleItem).toList(),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 400),
      tween: Tween(begin: 0.8, end: 1.0),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: child,
        );
      },
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(32),
          margin: const EdgeInsets.all(24),
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 600),
                tween: Tween(begin: 0.0, end: 1.0),
                curve: Curves.elasticOut,
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: child,
                  );
                },
                child: Icon(
                  Icons.history,
                  size: 60,
                  color: Colors.blue.shade200,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'No History Yet',
                style: TextStyle(
                  fontFamily: 'Rubik',
                  fontSize: 20,
                  color: Colors.grey[800],
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Your solved expressions will appear here',
                style: TextStyle(
                  fontFamily: 'Rubik',
                  fontSize: 15,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedHistoryList() {
    return AnimatedList(
      key: _listKey,
      initialItemCount: _localHistory.length,
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index, animation) {
        final item = _localHistory[index];
        return SlideTransition(
          position: animation.drive(
            Tween(
              begin: const Offset(1.0, 0.0),
              end: Offset.zero,
            ).chain(CurveTween(curve: Curves.easeOutCubic)),
          ),
          child: FadeTransition(
            opacity: animation,
            child: _buildHistoryItem(item),
          ),
        );
      },
    );
  }

  Future<void> _clearHistoryWithAnimation() async {
    final currentItems = List.from(_localHistory);

    // Create a reversed copy to remove items from the end first
    final reversedItems = currentItems.reversed.toList();

    for (var i = 0; i < reversedItems.length; i++) {
      final index = _localHistory.length - 1 - i;

      // Remove the item from the local list
      final removedItem = _localHistory.removeAt(index);

      // Tell AnimatedList to animate the removal
      _listKey.currentState?.removeItem(
        index,
        (context, animation) => SizeTransition(
          sizeFactor: animation,
          child: FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: animation.drive(
                Tween(
                  begin: const Offset(1.0, 0.0),
                  end: Offset.zero,
                ).chain(CurveTween(curve: Curves.easeInCubic)),
              ),
              child: _buildHistoryItem(removedItem),
            ),
          ),
        ),
        duration: Duration(milliseconds: 150 + (50 * i)),
      );

      // Add a small delay between removals for a cascading effect
      await Future.delayed(const Duration(milliseconds: 50));
    }

    // Update state to reflect empty history
    setState(() {});
  }

  Future<void> _showClearHistoryDialog(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => TweenAnimationBuilder<double>(
        duration: const Duration(milliseconds: 200),
        tween: Tween(begin: 0.8, end: 1.0),
        curve: Curves.easeOut,
        builder: (context, value, child) {
          return Transform.scale(
            scale: value,
            child: child,
          );
        },
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Clear History',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontFamily: 'Rubik',
            ),
          ),
          content: const Text(
            'Are you sure you want to clear all history? This action cannot be undone.',
            style: TextStyle(
              fontFamily: 'Rubik',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                'Cancel',
                style: TextStyle(color: Colors.grey[600], fontFamily: 'Rubik'),
              ),
            ),
            Container(
              margin: const EdgeInsets.only(left: 8),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  'Clear',
                  style: TextStyle(color: Colors.red, fontFamily: 'Rubik'),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if (result == true) {
      await _clearHistoryWithAnimation();

      await _persistenceService.clearHistory();

      widget.onHistoryChanged([]);
    }
  }

  String _formatDate(DateTime date) {
    return DateFormat('MMM d, y • h:mm a').format(date);
  }
}
