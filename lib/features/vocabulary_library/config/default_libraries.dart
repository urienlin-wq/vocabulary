import '../models/vocabulary_library.dart';

abstract final class DefaultLibraries {
  static const localUserId = 'local';
  static const regularId = 'library_regular';
  static const familiarMeaningId = 'library_familiar_meaning';

  static List<VocabularyLibrary> create({DateTime? now}) {
    final timestamp = now ?? DateTime.now();
    return [
      VocabularyLibrary(
        id: regularId,
        userId: localUserId,
        name: '常规单词库',
        description: '日常积累的单词和短语',
        icon: 'menu_book',
        isSystemLibrary: true,
        createdAt: timestamp,
        updatedAt: timestamp,
      ),
      VocabularyLibrary(
        id: familiarMeaningId,
        userId: localUserId,
        name: '熟词生义库',
        description: '熟悉单词在特定语境中的新义项',
        icon: 'auto_stories',
        isSystemLibrary: true,
        createdAt: timestamp,
        updatedAt: timestamp,
      ),
    ];
  }
}
