import 'package:flutter/material.dart';

import '../model/recognition_model.dart';

class ModelSelectionDialog extends StatefulWidget {
  const ModelSelectionDialog({super.key});

  @override
  State<ModelSelectionDialog> createState() => _ModelSelectionDialogState();
}

class _ModelSelectionDialogState extends State<ModelSelectionDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            padding: const EdgeInsets.all(24),
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Select Recognition Model',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A237E),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Choose the model that best suits your needs',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 16,
                    color: const Color(0xFF3F51B5).withOpacity(0.8),
                  ),
                ),
                const SizedBox(height: 24),
                ...RecognitionModel.values.asMap().entries.map(
                      (entry) => _buildModelOption(
                        context,
                        entry.value,
                        entry.key,
                      ),
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModelOption(
      BuildContext context, RecognitionModel model, int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 200 + (index * 100)),
      curve: Curves.easeOutQuart,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: InkWell(
          onTap: () async {
            // Add tap animation
            await _controller.reverse();
            if (context.mounted) {
              Navigator.pushReplacementNamed(
                context,
                '/drawing',
                arguments: model,
              );
            }
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(
                color: const Color(0xFF3F51B5).withOpacity(0.1),
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F3FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    model.emoji,
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        model.name,
                        style: const TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A237E),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        model.description,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 14,
                          color: const Color(0xFF3F51B5).withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: const Color(0xFF3F51B5).withOpacity(0.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
