import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/ui_providers.dart';

class SuwayaSpeedDialFab extends ConsumerStatefulWidget {
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
  ConsumerState<SuwayaSpeedDialFab> createState() => _SuwayaSpeedDialFabState();
}

class _SuwayaSpeedDialFabState extends ConsumerState<SuwayaSpeedDialFab>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _controller;
  late final Animation<double> _expandAnimation;
  late final Animation<double> _backdropAnimation;
  final OverlayPortalController _overlayController = OverlayPortalController();
  final LayerLink _layerLink = LayerLink();

  GoRouterDelegate? _routerDelegate;
  bool _isOpen = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _expandAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
      reverseCurve: Curves.easeInCubic,
    );
    _backdropAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
      reverseCurve: Curves.easeIn,
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.dismissed &&
          !_isOpen &&
          _overlayController.isShowing) {
        _overlayController.hide();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final delegate = GoRouter.maybeOf(context)?.routerDelegate;
    if (_routerDelegate != delegate) {
      _routerDelegate?.removeListener(_onRouteChanged);
      _routerDelegate = delegate;
      _routerDelegate?.addListener(_onRouteChanged);
    }
  }

  @override
  void deactivate() {
    _closeMenu(immediate: true);
    super.deactivate();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _routerDelegate?.removeListener(_onRouteChanged);
    _controller.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed && _isOpen) {
      _closeMenu(immediate: true);
    }
  }

  void _onRouteChanged() {
    if (_isOpen) {
      _closeMenu(immediate: true);
    }
  }

  void _openMenu() {
    if (_isOpen) return;
    HapticFeedback.lightImpact();
    setState(() => _isOpen = true);
    if (!_overlayController.isShowing) {
      _overlayController.show();
    }
    _controller.forward();
  }

  void _closeMenu({bool immediate = false}) {
    if (!_isOpen && !_overlayController.isShowing) return;
    if (mounted) {
      setState(() => _isOpen = false);
    } else {
      _isOpen = false;
    }

    if (immediate) {
      _controller.value = 0.0;
      if (_overlayController.isShowing) {
        _overlayController.hide();
      }
    } else {
      _controller.reverse();
    }
  }

  void _toggleMenu() {
    if (_isOpen) {
      HapticFeedback.lightImpact();
      _closeMenu();
    } else {
      _openMenu();
    }
  }

  void _openAddScreen(int tabIndex) {
    HapticFeedback.selectionClick();
    _closeMenu(immediate: true);

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
    required bool isRTL,
  }) {
    return ScaleTransition(
      scale: _expandAnimation,
      alignment: isRTL ? Alignment.bottomLeft : Alignment.bottomRight,
      child: FadeTransition(
        opacity: _backdropAnimation,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: Material(
            color: widget.color,
            elevation: 8,
            shadowColor: Colors.black54,
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

  Widget _buildFabButton(Color fgColor) {
    return FloatingActionButton(
      heroTag: null,
      backgroundColor: widget.color,
      foregroundColor: fgColor,
      elevation: _isOpen ? 10 : 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_isOpen ? 28 : 20),
      ),
      onPressed: _toggleMenu,
      child: AnimatedRotation(
        turns: _isOpen ? 0.125 : 0.0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        child: const Icon(LucideIcons.plus, size: 28),
      ),
    );
  }

  // استبدل دالة build في lib/shared/widgets/suwaya_speed_dial_fab.dart بالكامل بما يلي:

  @override
  Widget build(BuildContext context) {
    ref.listen<bool>(isDrawerOpenProvider, (prev, isOpen) {
      if (isOpen && _isOpen) {
        _closeMenu(immediate: true);
      }
    });

    final fgColor = widget.isDark ? const Color(0xFF0F172A) : Colors.white;
    final isRTL = Directionality.of(context) == ui.TextDirection.rtl;

    return PopScope(
      canPop: !_isOpen,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _isOpen) {
          _closeMenu();
        }
      },
      child: OverlayPortal(
        controller: _overlayController,
        overlayChildBuilder: (overlayContext) {
          return Stack(
            children: [
              // 1. طبقة تعتيم الخلفية الكاملة التي تغلق القائمة عند لمس أي مكان فارغ
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _closeMenu,
                  child: FadeTransition(
                    opacity: _backdropAnimation,
                    child: const ColoredBox(color: Color(0x8C000000)),
                  ),
                ),
              ),

              // 2. الخيارات الثلاثة منفصلة ومرتبطة بأعلى الزر الأصلي مباشرة
              CompositedTransformFollower(
                link: _layerLink,
                showWhenUnlinked: false,
                targetAnchor: isRTL ? Alignment.topLeft : Alignment.topRight,
                followerAnchor: isRTL
                    ? Alignment.bottomLeft
                    : Alignment.bottomRight,
                offset: const Offset(0, -4),
                child: Directionality(
                  textDirection: isRTL
                      ? ui.TextDirection.rtl
                      : ui.TextDirection.ltr,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _buildPillOption(
                        label: 'tasks.routine_period'.tr(),
                        icon: LucideIcons.compass,
                        tabIndex: 2,
                        fgColor: fgColor,
                        isRTL: isRTL,
                      ),
                      _buildPillOption(
                        label: 'tasks.continuous_habit'.tr(),
                        icon: LucideIcons.repeat,
                        tabIndex: 1,
                        fgColor: fgColor,
                        isRTL: isRTL,
                      ),
                      _buildPillOption(
                        label: 'tasks.casual_task'.tr(),
                        icon: LucideIcons.check,
                        tabIndex: 0,
                        fgColor: fgColor,
                        isRTL: isRTL,
                      ),
                    ],
                  ),
                ),
              ),

              // 3. زر الإغلاق (×) منطبق 100% فوق مركز الزر الأصلي (+) بحجم ثابت لا يتحرك أبداً
              CompositedTransformFollower(
                link: _layerLink,
                showWhenUnlinked: false,
                targetAnchor: Alignment.center,
                followerAnchor: Alignment.center,
                child: SizedBox(
                  width: 56,
                  height: 56,
                  child: _buildFabButton(fgColor),
                ),
              ),
            ],
          );
        },
        child: CompositedTransformTarget(
          link: _layerLink,
          child: SizedBox(
            width: 56,
            height: 56,
            child: Opacity(
              opacity: _isOpen ? 0.0 : 1.0,
              child: _buildFabButton(fgColor),
            ),
          ),
        ),
      ),
    );
  }
}
