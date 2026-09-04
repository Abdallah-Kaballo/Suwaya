import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/astro_engine/astro_models.dart';
import '../../../core/astro_engine/astro_provider.dart';
import '../../../models/task_model.dart';
import '../../tasks/screens/universal_add_screen.dart'; 
import 'premium_astro_dial.dart'; 

class PeriodDetailsSheet extends StatefulWidget {
  final AstroPeriod period;
  final AstroState astroState;
  final List<TaskModel> tasks; 

  const PeriodDetailsSheet({super.key, required this.period, required this.astroState, required this.tasks});
  @override State<PeriodDetailsSheet> createState() => _PeriodDetailsSheetState();
}

class _PeriodDetailsSheetState extends State<PeriodDetailsSheet> {
  bool _isCivilMode = false; 

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0D0D12) : Colors.white;
    final surfaceColor = isDark ? const Color(0xFF1A1A24) : const Color(0xFFF5F7FA);
    final pColor = widget.period.color.adapt(context);
    final textColor = isDark ? Colors.white : Colors.black87;

    final durationMicro = widget.period.endTime.difference(widget.period.startTime).inMicroseconds;
    final periodMins = durationMicro ~/ 60000000;
    final periodHours = periodMins ~/ 60;
    final periodLeftMins = periodMins % 60;
    final civilLengthStr = '${periodHours > 0 ? '$periodHours ${'details.hour_and'.tr()} ' : ''} $periodLeftMins ${'details.minute'.tr()}';
    
    final suwayaMicro = durationMicro ~/ (widget.period.suwayasCount > 0 ? widget.period.suwayasCount : 1);
    final durationSecs = suwayaMicro ~/ 1000000;
    final sMins = durationSecs ~/ 60;
    final sSecs = durationSecs % 60;
    final suwayaLengthStr = '$sMins ${'details.min_and'.tr()} $sSecs ${'details.sec'.tr()}';

    final astroLengthStr = '${widget.period.suwayasCount} ${'details.suwayas'.tr()}';
    
    final virtualMins = widget.period.suwayasCount * 30.0;
    double isolatedPeriodSpeed = virtualMins > 0 ? (virtualMins / periodMins) : 1.0;
    final timeSpeedStr = isolatedPeriodSpeed.toStringAsFixed(2);

    int startGlobalSuwaya = 0;
    for (var p in widget.astroState.periods) {
      if (p.id == widget.period.id) break;
      startGlobalSuwaya += p.suwayasCount;
    }
    int endGlobalSuwaya = startGlobalSuwaya + widget.period.suwayasCount - 1;

    final periodTasks = widget.tasks.where((t) => t.targetPeriodId == widget.period.id).toList();

    return Align(
      alignment: Alignment.bottomCenter,
      child: Material(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        clipBehavior: Clip.antiAlias,
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.85, 
          child: Column(
            children: [
              Container(width: 40, height: 4, margin: const EdgeInsets.only(top: 12, bottom: 16), decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(4))),
              
              SizedBox(
                height: 100, width: double.infinity,
                child: CustomPaint(
                  painter: ReplicaArcPainter(period: widget.period, tasks: periodTasks, isDark: isDark),
                ),
              ),
              
              Text(widget.period.name, style: TextStyle(color: textColor, fontSize: 26, fontWeight: FontWeight.w900, fontFamily: 'Tajawal')),
              Text('${'details.total_length'.tr()} ${_isCivilMode ? civilLengthStr : astroLengthStr}', style: TextStyle(color: pColor, fontSize: 13, fontWeight: FontWeight.bold)),
              
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  physics: const BouncingScrollPhysics(),
                  children: [
                    Container(
                      decoration: BoxDecoration(color: surfaceColor, borderRadius: BorderRadius.circular(16)),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () { HapticFeedback.selectionClick(); setState(() => _isCivilMode = false); },
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(color: !_isCivilMode ? pColor : Colors.transparent, borderRadius: BorderRadius.circular(16), boxShadow: !_isCivilMode ? [BoxShadow(color: pColor.withValues(alpha: 0.3), blurRadius: 8)] : []),
                                child: Center(child: Text('common.astro'.tr(), style: TextStyle(color: !_isCivilMode ? (isDark ? Colors.black : Colors.white) : textColor.withValues(alpha: 0.5), fontWeight: FontWeight.bold))),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () { HapticFeedback.selectionClick(); setState(() => _isCivilMode = true); },
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(color: _isCivilMode ? pColor : Colors.transparent, borderRadius: BorderRadius.circular(16), boxShadow: _isCivilMode ? [BoxShadow(color: pColor.withValues(alpha: 0.3), blurRadius: 8)] : []),
                                child: Center(child: Text('common.civil'.tr(), style: TextStyle(color: _isCivilMode ? (isDark ? Colors.black : Colors.white) : textColor.withValues(alpha: 0.5), fontWeight: FontWeight.bold))),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: surfaceColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: pColor.withValues(alpha: 0.2))),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildInfoCol('details.start'.tr(), _isCivilMode ? DateFormat('hh:mm a').format(widget.period.startTime) : '${'common.suwaya'.tr()} ${startGlobalSuwaya.toString().padLeft(2, '0')}', pColor, textColor),
                          Container(width: 1, height: 40, color: pColor.withValues(alpha: 0.2)),
                          _buildInfoCol('details.end'.tr(), _isCivilMode ? DateFormat('hh:mm a').format(widget.period.endTime) : '${'common.suwaya'.tr()} ${endGlobalSuwaya.toString().padLeft(2, '0')}', pColor, textColor),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(child: _buildStatCard('details.suwaya_length'.tr(), suwayaLengthStr, LucideIcons.timer, pColor, surfaceColor, textColor)),
                        const SizedBox(width: 12),
                        Expanded(child: _buildStatCard('details.flow_speed'.tr(), '${timeSpeedStr}x', LucideIcons.zap, pColor, surfaceColor, textColor)),
                      ],
                    ),
                    const SizedBox(height: 24),

                    Text('details.scheduled_tasks'.tr(), style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 8),
                    if (periodTasks.isEmpty)
                      Container(padding: const EdgeInsets.all(24), decoration: BoxDecoration(color: surfaceColor, borderRadius: BorderRadius.circular(16)), child: Center(child: Text('details.empty_period'.tr(), style: TextStyle(color: textColor.withValues(alpha: 0.4)))))
                    else
                      ...periodTasks.map((t) => Container(
                        margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: surfaceColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: getNeonColorForCategory(t.category).withValues(alpha: 0.3))),
                        child: Row(
                          children: [
                            Container(width: 12, height: 12, decoration: BoxDecoration(color: getNeonColorForCategory(t.category), shape: BoxShape.circle)),
                            const SizedBox(width: 12),
                            Text(t.title, style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
                            const Spacer(),
                            if (t.targetSuwayas.isNotEmpty) Text('${'common.suwaya'.tr()} ${t.targetSuwayas.first.toString().padLeft(2, '0')}', style: TextStyle(color: pColor, fontSize: 12, fontFamily: 'monospace')),
                          ],
                        )
                      )),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () { 
                          Navigator.pop(context); 
                          Navigator.push(context, MaterialPageRoute(builder: (_) => UniversalAddScreen(currentPeriodId: widget.period.id, currentSuwaya: 1, initialTab: 0))); 
                        },
                        icon: const Icon(LucideIcons.plus, color: Colors.white, size: 18), label: Text('common.new_task'.tr(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(backgroundColor: pColor, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () { 
                          Navigator.pop(context); 
                          Navigator.push(context, MaterialPageRoute(builder: (_) => UniversalAddScreen(currentPeriodId: widget.period.id, currentSuwaya: 1, initialTab: 1))); 
                        },
                        icon: Icon(LucideIcons.repeat, color: pColor, size: 18), label: Text('common.continuous_habit'.tr(), style: TextStyle(color: pColor, fontWeight: FontWeight.bold)),
                        style: OutlinedButton.styleFrom(side: BorderSide(color: pColor, width: 2), padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String val, IconData icon, Color pColor, Color surfaceColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: surfaceColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: pColor.withValues(alpha: 0.2))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [Icon(icon, color: pColor, size: 14), const SizedBox(width: 6), Text(label, style: TextStyle(color: textColor.withValues(alpha: 0.5), fontSize: 11))]),
          const SizedBox(height: 8),
          Text(val, style: TextStyle(color: textColor, fontSize: 14, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
        ],
      ),
    );
  }

  Widget _buildInfoCol(String label, String val, Color pColor, Color textColor) {
    return Column(
      children: [
        Text(label, style: TextStyle(color: textColor.withValues(alpha: 0.5), fontSize: 11)),
        const SizedBox(height: 4),
        Text(val, style: TextStyle(color: pColor, fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
      ],
    );
  }
}

class ReplicaArcPainter extends CustomPainter {
  final AstroPeriod period;
  final List<TaskModel> tasks;
  final bool isDark;
  ReplicaArcPainter({required this.period, required this.tasks, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 1.5); 
    final R = size.height * 1.4; 
    
    final pColor = period.color;
    const sweepAngle = pi / 2.5; 
    const startAngle = -pi / 2 - (sweepAngle / 2);

    final trackPaint = Paint()..color = isDark ? Colors.white12 : Colors.black12..style = PaintingStyle.stroke..strokeWidth = 20;
    canvas.drawArc(Rect.fromCircle(center: center, radius: R), startAngle, sweepAngle, false, trackPaint);
    
    final periodPaint = Paint()..color = pColor.withValues(alpha: 0.8)..style = PaintingStyle.stroke..strokeWidth = 14..strokeCap = StrokeCap.round;
    canvas.drawArc(Rect.fromCircle(center: center, radius: R - 20), startAngle, sweepAngle, false, periodPaint);

    final suwayaAngle = sweepAngle / period.suwayasCount;
    for(int i=0; i<=period.suwayasCount; i++) {
       final angle = startAngle + (i * suwayaAngle);
       final p1 = Offset(center.dx + (R - 30) * cos(angle), center.dy + (R - 30) * sin(angle));
       final p2 = Offset(center.dx + (R + 10) * cos(angle), center.dy + (R + 10) * sin(angle));
       canvas.drawLine(p1, p2, Paint()..color = pColor..strokeWidth = 2.0);
    }

    for (var t in tasks) {
      if (t.targetSuwayas.isEmpty) continue;
      int sIndex = t.targetSuwayas.first - 1;
      double progress = sIndex / period.suwayasCount;
      double angle = startAngle + (progress * sweepAngle) + (suwayaAngle / 2);

      Color tColor = getNeonColorForCategory(t.category);
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(angle + pi / 2);
      canvas.translate(0, -R);
      
      final path = Path()..moveTo(0, -5)..lineTo(-4, 4)..lineTo(4, 4)..close();
      canvas.drawPath(path, Paint()..color = tColor);
      canvas.restore();
    }
  }
  @override bool shouldRepaint(covariant CustomPainter old) => true;
}