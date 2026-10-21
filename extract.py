import os

# المجلدات والملفات المستهدفة
target_dirs = ['lib']
target_files = [
    'pubspec.yaml',
    'README.md',
    'ARCHITECTURE.md',
    'Suwaya-Time.md',
    'android/app/src/main/AndroidManifest.xml',
]
allowed_ext = ('.dart', '.yaml', '.md', '.xml', '.kt', '.json')

# استثناء الملفات المولدة تلقائياً لتقليل الحجم والتركيز على الكود الفعلي
excluded_suffixes = (
    '.g.dart',
    '.freezed.dart',
    '.gr.dart',
    '.mocks.dart',
    'generated_plugin_registrant.dart',
)

MAX_LINES_PER_FILE = 5000  # الحد التقريبي لكل ملف

files_to_process = []

# 1. جمع الملفات الفردية
for f in target_files:
  if os.path.exists(f):
    files_to_process.append(f)

# 2. جمع ملفات الأكواد من مجلد lib
for d in target_dirs:
  if os.path.exists(d):
    for root, _, files in os.walk(d):
      for file in sorted(files):
        if file.endswith(allowed_ext) and not file.endswith(excluded_suffixes):
          files_to_process.append(os.path.join(root, file))

part_num = 1
current_lines = 0
current_chunks = []


def save_part(part, chunks, line_count):
  filename = f'project_part_{part}.txt'
  with open(filename, 'w', encoding='utf-8') as out:
    out.write(
        f'=== الجزء رقم {part} (إجمالي الأسطر: {line_count}) ===\n\n'
    )
    out.writelines(chunks)
  print(f'✅ تم إنشاء: {filename} ({line_count} سطر)')


# 3. قراءة الملفات وتقسيمها بذكاء دون قطع الملف البرمجي الواحد
for path in files_to_process:
  try:
    with open(path, 'r', encoding='utf-8', errors='ignore') as infile:
      lines = infile.readlines()

    header = [f'\n{"="*50}\nFILE: {path}\n{"="*50}\n\n']
    file_block = header + lines + ['\n']
    block_len = len(file_block)

    # إذا كان إضافة هذا الملف ستجعل الجزء الحالي يتخطى 5000 سطر، نحفظ الجزء ونفتح جزءاً جديداً
    if current_lines + block_len > MAX_LINES_PER_FILE and current_lines > 0:
      save_part(part_num, current_chunks, current_lines)
      part_num += 1
      current_chunks = []
      current_lines = 0

    current_chunks.extend(file_block)
    current_lines += block_len

  except Exception as e:
    print(f'⚠️ خطأ في قراءة {path}: {e}')

# حفظ الجزء الأخير المتبقي
if current_chunks:
  save_part(part_num, current_chunks, current_lines)

print(f'\n🎉 اكتملت العملية! تم تقسيم المشروع إلى {part_num} ملفات.')