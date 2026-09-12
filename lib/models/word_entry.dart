class WordEntry {
  const WordEntry({this.id,required this.english,required this.chinese});
  final int? id; final String english, chinese;
  Map<String,Object?> toMap()=>{'id':id,'english':english,'chinese':chinese};
  factory WordEntry.fromMap(Map<String,Object?> m)=>WordEntry(id:m['id'] as int?,english:m['english'] as String,chinese:m['chinese'] as String);
}
