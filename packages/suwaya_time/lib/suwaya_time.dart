/// محرك سويعة الزمني (Suwaya Time Engine)
/// نظام برمجي يحول الأحداث الفلكية المتغيرة إلى 48 وحدة زمنية إنتاجية ثابتة (سويعات).
library suwaya_time;

// 1. تصدير النماذج الأساسية (البيانات)
export 'src/models/astro_models.dart';

// 2. تصدير العقل المدبر (المحرك)
export 'src/engine/suwaya_time_engine.dart';

// 3. تصدير الحاسبات والمولدات (في حال احتاجها التطبيق لعمليات متقدمة)
export 'src/calculators/prayer_calculator.dart';
export 'src/calculators/night_division.dart';
export 'src/generators/period_generator.dart';
export 'src/generators/suwaya_distributor.dart';