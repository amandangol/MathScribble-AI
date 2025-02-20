import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
                style: GoogleFonts.rubik(
                  fontSize: 20,
                  color: Colors.grey[800],
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Your solved expressions will appear here',
                style: GoogleFonts.roboto(
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
      initialItemCount: widget.history.length,
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index, animation) {
        final item = widget.history[index];
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

  Widget _buildHistoryItem(MathHistoryItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.shade100.withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TweenAnimationBuilder<double>(
        duration: const Duration(milliseconds: 300),
        tween: Tween(begin: 0.96, end: 1.0),
        builder: (context, value, child) {
          return Transform.scale(
            scale: value,
            child: child,
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildIconContainer(
                    icon: Icons.functions,
                    color: Colors.blue,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Expression',
                          style: GoogleFonts.rubik(
                            fontSize: 14,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          item.expression,
                          style: GoogleFonts.robotoMono(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    _formatDate(item.timestamp),
                    style: GoogleFonts.roboto(
                      color: Colors.grey[500],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              if (item.solution != null) ...[
                const SizedBox(height: 16),
                Divider(color: Colors.grey[200]),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _buildIconContainer(
                      icon: Icons.check_circle,
                      color: Colors.green,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Solution',
                            style: GoogleFonts.rubik(
                              fontSize: 14,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            item.solution!,
                            style: GoogleFonts.robotoMono(
                              fontSize: 16,
                              color: Colors.green[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIconContainer({
    required IconData icon,
    required MaterialColor color,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        icon,
        color: color.shade600,
        size: 20,
      ),
    );
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
          title: Text(
            'Clear History',
            style: GoogleFonts.rubik(fontWeight: FontWeight.bold),
          ),
          content: Text(
            'Are you sure you want to clear all history? This action cannot be undone.',
            style: GoogleFonts.roboto(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                'Cancel',
                style: GoogleFonts.rubik(color: Colors.grey[600]),
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
                child: Text(
                  'Clear',
                  style: GoogleFonts.rubik(color: Colors.red),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if (result == true) {
      // Animate items out before clearing
      final itemCount = widget.history.length;
      for (var i = itemCount - 1; i >= 0; i--) {
        _listKey.currentState?.removeItem(
          i,
          (context, animation) => SizeTransition(
            sizeFactor: animation,
            child: FadeTransition(
              opacity: animation,
              child: _buildHistoryItem(widget.history[i]),
            ),
          ),
          duration: const Duration(milliseconds: 200),
        );
      }

      // Wait for animation to complete before clearing
      await Future.delayed(const Duration(milliseconds: 250));
      await _persistenceService.clearHistory();
      widget.onHistoryChanged([]);
    }
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
            style: GoogleFonts.rubik(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const Spacer(),
          if (widget.history.isNotEmpty)
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

  String _formatDate(DateTime date) {
    return DateFormat('MMM d, y • h:mm a').format(date);
  }
}
