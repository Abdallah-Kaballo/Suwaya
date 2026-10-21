import os

# المجلدات والملفات التي نريد تجاهلها لكي تكون الشجرة نظيفة ومركزة
IGNORE_DIRS = {
    '.git',
    '.dart_tool',
    '.idea',
    '.vscode',
    'build',
    '.gradle',
    'ios',
    'macos',
    'linux',
    'windows',
    'web',
    '__pycache__',
}
IGNORE_FILES = {'.DS_Store'}


def generate_tree(dir_path, prefix=''):
  lines = []
  try:
    items = sorted(os.listdir(dir_path))
  except PermissionError:
    return lines

  # تصفية المجلدات والملفات غير المرغوب فيها والملفات النصية التي أنشأناها سابقاً
  items = [
      item
      for item in items
      if item not in IGNORE_DIRS
      and item not in IGNORE_FILES
      and not item.startswith('project_part_')
      and item not in ('project_code.txt', 'extract.py', 'tree.py')
  ]

  # ترتيب المجلدات أولاً ثم الملفات
  dirs = [i for i in items if os.path.isdir(os.path.join(dir_path, i))]
  files = [i for i in items if not os.path.isdir(os.path.join(dir_path, i))]
  sorted_items = dirs + files

  for index, item in enumerate(sorted_items):
    path = os.path.join(dir_path, item)
    is_last = index == len(sorted_items) - 1
    connector = '└── ' if is_last else '├── '

    if os.path.isdir(path):
      lines.append(f'{prefix}{connector}📁 {item}/')
      extension = '    ' if is_last else '│   '
      lines.extend(generate_tree(path, prefix + extension))
    else:
      lines.append(f'{prefix}{connector}📄 {item}')

  return lines


if __name__ == '__main__':
  project_name = os.path.basename(os.path.abspath('.'))
  tree_lines = [f'📦 {project_name}/'] + generate_tree('.')
  tree_output = '\n'.join(tree_lines)

  with open('project_tree.txt', 'w', encoding='utf-8') as f:
    f.write(tree_output)

  print(tree_output)
  print('\n✅ تم حفظ شجرة المشروع بنجاح في ملف: project_tree.txt')