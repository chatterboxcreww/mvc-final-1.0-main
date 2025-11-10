// lib/shared/widgets/glass_container.dart
import 'dart:ui';
import 'package:flutter/material.dart';

/// A reusable glass-morphism container widget with blur effect
class GlassContainer extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final double blur;
  final double opacity;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Border? border;
  final List<Color>? gradientColors;
  final VoidCallback? onTap;
  final double? width;
  final double? height;
  final BoxShape shape;

  const GlassContainer({
    super.key,
    required this.child,
    this.borderRadius = 20,
    this.blur = 10,
    this.opacity = 0.1,
    this.padding,
    this.margin,
    this.border,
    this.gradientColors,
    this.onTap,
    this.width,
    this.height,
    this.shape = BoxShape.rectangle,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final defaultGradient = [
      (isDark ? Colors.white : Colors.white).withOpacity(opacity),
      (isDark ? Colors.white : Colors.white).withOpacity(opacity * 0.5),
    ];

    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: shape == BoxShape.circle
          ? BoxDecoration(
              shape: BoxShape.circle,
              border: border ?? Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1.5,
              ),
            )
          : null,
      child: ClipRRect(
        borderRadius: shape == BoxShape.circle ? BorderRadius.zero : BorderRadius.circular(borderRadius),
        clipBehavior: Clip.antiAlias,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            decoration: shape == BoxShape.circle
                ? BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: gradientColors ?? defaultGradient,
                    ),
                  )
                : BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: gradientColors ?? defaultGradient,
                    ),
                    borderRadius: BorderRadius.circular(borderRadius),
                    border: border ?? Border.all(
                      color: Colors.white.withOpacity(0.2),
                      width: 1.5,
                    ),
                  ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                borderRadius: shape == BoxShape.circle ? null : BorderRadius.circular(borderRadius),
                child: Padding(
                  padding: padding ?? const EdgeInsets.all(16),
                  child: child,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Glass card with elevation and shadow
class GlassCard extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final double elevation;

  const GlassCard({
    super.key,
    required this.child,
    this.borderRadius = 24,
    this.padding,
    this.margin,
    this.onTap,
    this.elevation = 8,
  });

  // Compact variant with minimal padding and margin
  const GlassCard.compact({
    super.key,
    required this.child,
    this.borderRadius = 16,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    this.onTap,
    this.elevation = 4,
  }) : padding = padding ?? const EdgeInsets.all(10.0),
       margin = margin ?? const EdgeInsets.symmetric(horizontal: 8, vertical: 3);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Minimal default margin for compact layout
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;
    final defaultMargin = isSmallScreen 
        ? const EdgeInsets.symmetric(horizontal: 4, vertical: 3)
        : const EdgeInsets.symmetric(horizontal: 8, vertical: 4);

    return Container(
      margin: margin ?? defaultMargin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black : colorScheme.shadow).withOpacity(0.1),
            blurRadius: elevation * 2,
            offset: Offset(0, elevation / 2),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: colorScheme.primary.withOpacity(0.05),
            blurRadius: elevation * 3,
            offset: Offset(0, elevation),
            spreadRadius: 0,
          ),
        ],
      ),
      child: GlassContainer(
        borderRadius: borderRadius,
        blur: 15,
        opacity: isDark ? 0.15 : 0.08,
        padding: padding ?? const EdgeInsets.all(16),
        onTap: onTap,
        gradientColors: [
          (isDark ? Colors.white : colorScheme.surface).withOpacity(isDark ? 0.15 : 0.95),
          (isDark ? Colors.white : colorScheme.surfaceContainer).withOpacity(isDark ? 0.1 : 0.85),
        ],
        border: Border.all(
          color: (isDark ? Colors.white : colorScheme.outline).withOpacity(isDark ? 0.2 : 0.1),
          width: 1,
        ),
        child: child,
      ),
    );
  }
}

/// Glass button with ripple effect
class GlassButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isPrimary;
  final bool isLoading;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;

  const GlassButton({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.isPrimary = true,
    this.isLoading = false,
    this.borderRadius = 16,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GlassContainer(
      borderRadius: borderRadius,
      blur: 10,
      opacity: isPrimary ? 0.2 : 0.1,
      padding: padding ?? const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      onTap: isLoading ? null : onPressed,
      gradientColors: isPrimary
          ? [
              colorScheme.primary.withOpacity(isDark ? 0.3 : 0.9),
              colorScheme.primary.withOpacity(isDark ? 0.2 : 0.7),
            ]
          : [
              Colors.white.withOpacity(isDark ? 0.15 : 0.1),
              Colors.white.withOpacity(isDark ? 0.1 : 0.05),
            ],
      border: Border.all(
        color: isPrimary
            ? colorScheme.primary.withOpacity(0.3)
            : Colors.white.withOpacity(0.2),
        width: 1.5,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isLoading)
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(
                  isPrimary ? colorScheme.onPrimary : colorScheme.primary,
                ),
              ),
            )
          else if (icon != null) ...[
            Icon(
              icon,
              color: isPrimary ? colorScheme.onPrimary : colorScheme.primary,
              size: 20,
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Text(
              text,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: isPrimary ? colorScheme.onPrimary : colorScheme.primary,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

/// Glass app bar with blur effect
class GlassAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool centerTitle;
  final double elevation;

  const GlassAppBar({
    super.key,
    required this.title,
    this.actions,
    this.leading,
    this.centerTitle = false,
    this.elevation = 0,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                (isDark ? Colors.white : colorScheme.surface).withOpacity(isDark ? 0.1 : 0.9),
                (isDark ? Colors.white : colorScheme.surfaceContainer).withOpacity(isDark ? 0.05 : 0.8),
              ],
            ),
            border: Border(
              bottom: BorderSide(
                color: (isDark ? Colors.white : colorScheme.outline).withOpacity(0.1),
                width: 1,
              ),
            ),
          ),
          child: AppBar(
            title: Text(title),
            actions: actions,
            leading: leading,
            centerTitle: centerTitle,
            elevation: elevation,
            backgroundColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

/// Glass bottom navigation bar
class GlassBottomNavigationBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final List<BottomNavigationBarItem> items;

  const GlassBottomNavigationBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black : colorScheme.shadow).withOpacity(0.15),
            blurRadius: 25,
            offset: const Offset(0, 8),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: colorScheme.primary.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  (isDark ? Colors.white : colorScheme.surface).withOpacity(isDark ? 0.15 : 0.95),
                  (isDark ? Colors.white : colorScheme.surfaceContainer).withOpacity(isDark ? 0.1 : 0.9),
                ],
              ),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: (isDark ? Colors.white : colorScheme.outline).withOpacity(0.1),
                width: 1,
              ),
            ),
            child: BottomNavigationBar(
              currentIndex: currentIndex,
              onTap: onTap,
              items: items,
              type: BottomNavigationBarType.fixed,
              elevation: 0,
              backgroundColor: Colors.transparent,
              selectedItemColor: colorScheme.primary,
              unselectedItemColor: colorScheme.onSurfaceVariant.withOpacity(0.6),
              selectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 11,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
