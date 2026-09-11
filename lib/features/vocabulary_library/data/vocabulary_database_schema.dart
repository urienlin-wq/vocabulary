abstract final class VocabularyDatabaseSchema {
  static const librariesTable = 'vocabulary_libraries';
  static const entriesTable = 'vocabulary_entries';
  static const reviewStatesTable = 'word_review_states';

  static const createLibrariesTable = '''
CREATE TABLE IF NOT EXISTS vocabulary_libraries (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL,
  name TEXT NOT NULL,
  description TEXT,
  icon TEXT NOT NULL,
  color_value INTEGER NOT NULL,
  is_system_library INTEGER NOT NULL DEFAULT 0,
  is_deleted INTEGER NOT NULL DEFAULT 0,
  deleted_at TEXT,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
)
''';

  static const createEntriesTable = '''
CREATE TABLE IF NOT EXISTS vocabulary_entries (
  id TEXT PRIMARY KEY,
  library_id TEXT NOT NULL,
  english TEXT NOT NULL,
  chinese TEXT NOT NULL,
  entry_type TEXT NOT NULL,
  source TEXT NOT NULL,
  topic_tags TEXT NOT NULL DEFAULT '',
  is_deleted INTEGER NOT NULL DEFAULT 0,
  deleted_at TEXT,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  FOREIGN KEY (library_id) REFERENCES vocabulary_libraries(id)
)
''';

  static const createReviewStatesTable = '''
CREATE TABLE IF NOT EXISTS word_review_states (
  entry_id TEXT PRIMARY KEY,
  is_favorite INTEGER NOT NULL DEFAULT 0,
  must_review_next INTEGER NOT NULL DEFAULT 0,
  times_tested INTEGER NOT NULL DEFAULT 0,
  times_marked_unfamiliar INTEGER NOT NULL DEFAULT 0,
  last_tested_at TEXT,
  updated_at TEXT NOT NULL,
  FOREIGN KEY (entry_id) REFERENCES vocabulary_entries(id)
)
''';

  static const createActiveEntriesIndex = '''
CREATE INDEX IF NOT EXISTS idx_vocabulary_entries_library_active
ON vocabulary_entries(library_id, is_deleted, updated_at DESC)
''';

  static const createEnglishSearchIndex = '''
CREATE INDEX IF NOT EXISTS idx_vocabulary_entries_english
ON vocabulary_entries(english)
''';
}
