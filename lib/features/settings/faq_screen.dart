import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;

import 'faq_provider.dart';

class FAQScreen extends ConsumerWidget {
  const FAQScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final langCode = context.locale.languageCode;
    final faqAsyncValue = ref.watch(faqProvider(langCode));

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = Theme.of(context).scaffoldBackgroundColor;
    final surfaceColor = Theme.of(context).cardColor;
    final textColor = Theme.of(context).colorScheme.onSurface;
    final primaryColor = Theme.of(context).primaryColor;
    final borderColor = Theme.of(context).dividerColor;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            langCode == 'ar' ? LucideIcons.arrow_right : LucideIcons.arrow_left,
            color: textColor,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'drawer.faq'.tr(), 
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: faqAsyncValue.when(
        loading: () => Center(child: CircularProgressIndicator(color: primaryColor)),
        error: (err, stack) => _buildErrorState(context, primaryColor, textColor),
        data: (faqs) {
          if (faqs.isEmpty) return _buildErrorState(context, primaryColor, textColor);

          return RefreshIndicator(
            color: primaryColor,
            backgroundColor: surfaceColor,
            onRefresh: () async {
              // 🌟 تحديث إجباري عند سحب الشاشة للأسفل
              ref.invalidate(faqProvider(langCode));
            },
            child: ListView.builder(
              physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
              padding: const EdgeInsets.all(20),
              itemCount: faqs.length,
              itemBuilder: (context, index) {
                final faq = faqs[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: borderColor),
                    boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8)],
                  ),
                  child: Theme(
                    data: ThemeData().copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      iconColor: primaryColor,
                      collapsedIconColor: isDark ? Colors.white54 : Colors.black54,
                      title: Text(
                        faq.question,
                        style: TextStyle(
                          color: textColor,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      children: [
                        Container(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          alignment: Alignment.centerLeft,
                          child: Text(
                            faq.answer,
                            style: TextStyle(
                              color: isDark ? Colors.white70 : Colors.black87,
                              fontSize: 14,
                              height: 1.6,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, Color primaryColor, Color textColor) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.wifi_off, size: 64, color: primaryColor.withValues(alpha: 0.5)),
            const SizedBox(height: 24),
            Text(
              'يبدو أنك غير متصل بالإنترنت ولم يسبق تحميل الأسئلة.', // يمكنك لاحقاً إضافة مفتاح ترجمة لها
              textAlign: TextAlign.center,
              style: TextStyle(color: textColor, fontSize: 16, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}