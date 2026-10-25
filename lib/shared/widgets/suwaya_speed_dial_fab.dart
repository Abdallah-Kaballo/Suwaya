import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';

class SuwayaSpeedDialFab extends StatefulWidget {
  final Color color;
  final bool isDark;
  final int currentPeriodId;
  final int currentSuwaya;
  final DateTime? initialDate;

  const SuwayaSpeedDialFab({
    super.key,
    required this.color,
    required this.isDark,
    required this.currentPeriodId,
    required this.currentSuwaya,
    this.initialDate,
  });

  @override
  State<SuwayaSpeedDialFab> createState() => _SuwayaSpeedDialFabState();
}

class _SuwayaSpeedDialFabState extends State<SuwayaSpeedDialFab>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _expandAnimation;
  bool _isOpen = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _expandAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
      reverseCurve: Curves.easeInCubic,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleMenu() {
    HapticFeedback.lightImpact();
    setState(() {
      _isOpen = !_isOpen;
      if (_isOpen) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  void _openAddScreen(int tabIndex) {
    HapticFeedback.selectionClick();
    setState(() => _isOpen = false);
    _controller.reverse();

    context.push(
      '/add-task',
      extra: {
        'currentPeriodId': widget.currentPeriodId,
        'currentSuwaya': widget.currentSuwaya,
        'initialTab': tabIndex,
        if (widget.initialDate != null) 'initialDate': widget.initialDate,
      },
    );
  }

  Widget _buildPillOption({
    required String label,
    required IconData icon,
    required int tabIndex,
    required Color fgColor,
  }) {
    return ScaleTransition(
      scale: _expandAnimation,
      alignment: Directionality.of(context) == ui.TextDirection.rtl
          ? Alignment.bottomLeft
          : Alignment.bottomRight,
      child: FadeTransition(
        opacity: _expandAnimation,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: Material(
            color: widget.color,
            elevation: 6,
            shadowColor: Colors.black45,
            borderRadius: BorderRadius.circular(28),
            child: InkWell(
              borderRadius: BorderRadius.circular(28),
              onTap: () => _openAddScreen(tabIndex),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 13,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, color: fgColor, size: 20),
                    const SizedBox(width: 10),
                    Text(
                      label,
                      style: TextStyle(
                        color: fgColor,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fgColor = widget.isDark ? const Color(0xFF0F172A) : Colors.white;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (_isOpen || _controller.isAnimating) ...[
          _buildPillOption(
            label: 'tasks.routine_period'.tr(),
            icon: LucideIcons.compass,
            tabIndex: 2,
            fgColor: fgColor,
          ),
          _buildPillOption(
            label: 'tasks.continuous_habit'.tr(),
            icon: LucideIcons.repeat,
            tabIndex: 1,
            fgColor: fgColor,
          ),
          _buildPillOption(
            label: 'tasks.casual_task'.tr(),
            icon: LucideIcons.check,
            tabIndex: 0,
            fgColor: fgColor,
          ),
        ],
        FloatingActionButton(
          heroTag: null,
          backgroundColor: _isOpen
              ? widget.color.withValues(alpha: 0.85)
              : widget.color,
          foregroundColor: fgColor,
          elevation: 6,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_isOpen ? 28 : 20),
          ),
          onPressed: _toggleMenu,
          child: AnimatedRotation(
            turns: _isOpen ? 0.125 : 0.0, // دوران 45 درجة يحول + إلى × بنعومة
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            child: const Icon(LucideIcons.plus, size: 28),
          ),
        ),
      ],
    );
  }
}
