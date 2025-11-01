// lib/shared/widgets/health_progress_indicator.dart
import 'package:flutter/material.dart';

class HealthProgressIndicator extends StatefulWidget {
  final double progress;
  final Color primaryColor;
  final Color backgroundColor;
  final double size;
  final double strokeWidth;
  final Widget? centerChild;
  final String? label;
  final String? value;

  const HealthProgressIndicator({
    super.key,
    required this.progress,
    required this.primaryColor,
    this.backgroundColor = Colors.grey,
    this.size = 120,
    this.strokeWidth = 8,
    this.centerChild,
    this.label,
    this.value,
  });

  @override
  State<HealthProgressIndicator> createState() => _HealthProgressIndicatorState();
}

class _HealthProgressIndicatorState extends State<HealthProgressIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.0, end: widget.progress).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void didUpdateWidget(HealthProgressIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.progress != widget.progress) {
      _animation = Tween<double>(begin: _animation.value, end: widget.progress).animate(
        CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
      );
      _animationController.reset();
      _animationController.forward();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Background circle
            SizedBox(
              width: widget.size,
              height: widget.size,
              child: CircularProgressIndicator(
                value: 1.0,
                strokeWidth: widget.strokeWidth,
                valueColor: AlwaysStoppedAnimation(widget.backgroundColor.withValues(alpha: 0.2)),
                backgroundColor: Colors.transparent,
              ),
            ),
            // Progress circle
            AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                return RepaintBoundary(
                  child: SizedBox(
                    width: widget.size,
                    height: widget.size,
                    child: CircularProgressIndicator(
                      value: _animation.value.clamp(0.0, 1.0),
                      strokeWidth: widget.strokeWidth,
                      valueColor: AlwaysStoppedAnimation(widget.primaryColor),
                      backgroundColor: Colors.transparent,
                      strokeCap: StrokeCap.round,
                    ),
                  ),
                );
              },
            ),
            // Center content
            if (widget.centerChild != null)
              widget.centerChild!
            else if (widget.value != null || widget.label != null)
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (widget.value != null)
                    Text(
                      widget.value!,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: widget.primaryColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  if (widget.label != null)
                    Text(
                      widget.label!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

// Enhanced Linear Progress Indicator
class HealthLinearProgress extends StatefulWidget {
  final double progress;
  final Color primaryColor;
  final Color backgroundColor;
  final double height;
  final String? label;
  final String? value;

  const HealthLinearProgress({
    super.key,
    required this.progress,
    required this.primaryColor,
    this.backgroundColor = Colors.grey,
    this.height = 8,
    this.label,
    this.value,
  });

  @override
  State<HealthLinearProgress> createState() => _HealthLinearProgressState();
}

class _HealthLinearProgressState extends State<HealthLinearProgress>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.0, end: widget.progress).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
    _animationController.forward();
  }

  @override
  void didUpdateWidget(HealthLinearProgress oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.progress != widget.progress) {
      _animation = Tween<double>(begin: _animation.value, end: widget.progress).animate(
        CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
      );
      _animationController.reset();
      _animationController.forward();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.label != null || widget.value != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (widget.label != null)
                    Text(
                      widget.label!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  if (widget.value != null)
                    Text(
                      widget.value!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: widget.primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
            ),
          Container(
            height: widget.height,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(widget.height / 2),
              color: widget.backgroundColor.withValues(alpha: 0.2),
            ),
            child: AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                return RepaintBoundary(
                  child: LinearProgressIndicator(
                    value: _animation.value.clamp(0.0, 1.0),
                    backgroundColor: Colors.transparent,
                    valueColor: AlwaysStoppedAnimation(widget.primaryColor),
                    minHeight: widget.height,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
