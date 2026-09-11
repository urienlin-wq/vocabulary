import 'package:flutter/material.dart';

import '../controllers/vocabulary_library_controller.dart';
import '../models/vocabulary_entry.dart';
import '../models/vocabulary_library.dart';
import '../repositories/sqlite_vocabulary_library_repository.dart';

class VocabularyLibraryPage extends StatefulWidget {
  const VocabularyLibraryPage({super.key});

  @override
  State<VocabularyLibraryPage> createState() => _VocabularyLibraryPageState();
}

class _VocabularyLibraryPageState extends State<VocabularyLibraryPage> {
  late final VocabularyLibraryController _controller;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller = VocabularyLibraryController(SqliteVocabularyLibraryRepository());
    _load();
  }

  Future<void> _load() async {
    await _controller.loadLibraries();
    if (_controller.selectedLibraryId == null && _controller.libraries.isNotEmpty) {
      await _controller.selectLibrary(_controller.libraries.first.id);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => Scaffold(
        appBar: AppBar(
          title: const Text('我的词库'),
          actions: [
            IconButton(
              onPressed: _controller.isLoading ? null : _showAddLibrary,
              icon: const Icon(Icons.create_new_folder_outlined),
              tooltip: '新建词库',
            ),
          ],
        ),
        floatingActionButton: _controller.selectedLibraryId == null ? null : FloatingActionButton.extended(onPressed: _showAddEntry, icon: const Icon(Icons.add), label: const Text('添加词条')),
        body: _buildBody(context),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_controller.isLoading && _controller.libraries.isEmpty) return const Center(child: CircularProgressIndicator());
    if (_controller.error != null) return Center(child: Padding(padding: const EdgeInsets.all(24), child: Text('加载失败：${_controller.error}')));
    if (_controller.libraries.isEmpty) return const Center(child: Text('还没有词库，点击右上角新建一个。'));
    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        child: DropdownButtonFormField<String>(
          value: _controller.selectedLibraryId,
          isExpanded: true,
          decoration: const InputDecoration(labelText: '当前词库', border: OutlineInputBorder()),
          items: _controller.libraries.map((library) => DropdownMenuItem(value: library.id, child: Text(library.name))).toList(growable: false),
          onChanged: _controller.isLoading ? null : _controller.selectLibrary,
        ),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: TextField(
          controller: _searchController,
          onChanged: _controller.search,
          decoration: InputDecoration(
            hintText: '搜索英文、中文或标签',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _controller.query.isEmpty ? null : IconButton(icon: const Icon(Icons.clear), onPressed: () { _searchController.clear(); _controller.search(''); }),
            border: const OutlineInputBorder(),
          ),
        ),
      ),
      const SizedBox(height: 8),
      Expanded(child: _buildEntries()),
    ]);
  }

  Widget _buildEntries() {
    if (_controller.isLoading) return const Center(child: CircularProgressIndicator());
    if (_controller.entries.isEmpty) return Center(child: Text(_controller.query.isEmpty ? '这个词库还没有词条。' : '没有匹配的词条。'));
    return RefreshIndicator(
      onRefresh: _controller.loadEntries,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
        itemCount: _controller.entries.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final entry = _controller.entries[index];
          return ListTile(title: Text(entry.english), subtitle: Text(entry.chinese), trailing: entry.isPhrase ? const Icon(Icons.short_text) : const Icon(Icons.text_fields));
        },
      ),
    );
  }

  Future<void> _showAddLibrary() async {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final saved = await showDialog<bool>(context: context, builder: (context) => AlertDialog(
      title: const Text('新建词库'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [TextField(controller: nameController, autofocus: true, decoration: const InputDecoration(labelText: '名称')), TextField(controller: descriptionController, decoration: const InputDecoration(labelText: '说明（可选）'))]),
      actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('取消')), FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('保存'))],
    ));
    final name = nameController.text.trim();
    if (saved != true || name.isEmpty) return;
    final now = DateTime.now();
    final library = VocabularyLibrary(id: 'library-${now.microsecondsSinceEpoch}', userId: 'local-user', name: name, description: descriptionController.text.trim().isEmpty ? null : descriptionController.text.trim(), createdAt: now, updatedAt: now);
    await _controller.saveLibrary(library);
    await _controller.selectLibrary(library.id);
  }

  Future<void> _showAddEntry() async {
    final libraryId = _controller.selectedLibraryId;
    if (libraryId == null) return;
    final englishController = TextEditingController();
    final chineseController = TextEditingController();
    final saved = await showDialog<bool>(context: context, builder: (context) => AlertDialog(
      title: const Text('添加词条'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [TextField(controller: englishController, autofocus: true, decoration: const InputDecoration(labelText: '英文单词或短语')), TextField(controller: chineseController, decoration: const InputDecoration(labelText: '中文释义'))]),
      actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('取消')), FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('保存'))],
    ));
    final english = englishController.text.trim();
    final chinese = chineseController.text.trim();
    if (saved != true || english.isEmpty || chinese.isEmpty) return;
    final now = DateTime.now();
    await _controller.saveEntry(VocabularyEntry(id: 'entry-${now.microsecondsSinceEpoch}', libraryId: libraryId, english: english, chinese: chinese, type: english.contains(RegExp(r'\s')) ? VocabularyEntryType.phrase : VocabularyEntryType.word, createdAt: now, updatedAt: now));
  }
}
