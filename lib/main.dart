import 'package:flutter/material.dart';
import 'models/word_entry.dart';
import 'features/vocabulary_library/pages/vocabulary_review_page.dart';
void main()=>runApp(const App());
class App extends StatelessWidget{const App({super.key});@override Widget build(BuildContext c)=>MaterialApp(theme:ThemeData(colorSchemeSeed:Colors.indigo),home:const Home());}
class Home extends StatefulWidget{const Home({super.key});@override State<Home> createState()=>_HomeState();}
class _HomeState extends State<Home>{
 final words=<WordEntry>[const WordEntry(english:'apple',chinese:'苹果'),const WordEntry(english:'book',chinese:'书'),const WordEntry(english:'learn',chinese:'学习'),const WordEntry(english:'water',chinese:'水')];
 final search=TextEditingController(); int count=4;
 List<WordEntry> get shown=>words.where((w)=>('${w.english}${w.chinese}').toLowerCase().contains(search.text.toLowerCase())).toList();
 void add(){final e=TextEditingController(),z=TextEditingController();showDialog(context:context,builder:(c)=>AlertDialog(title:const Text('新增词汇'),content:Column(mainAxisSize:MainAxisSize.min,children:[TextField(controller:e,decoration:const InputDecoration(labelText:'英文')),TextField(controller:z,decoration:const InputDecoration(labelText:'中文'))]),actions:[TextButton(onPressed:()=>Navigator.pop(c),child:const Text('取消')),FilledButton(onPressed:(){if(e.text.trim().isEmpty||z.text.trim().isEmpty)return;setState(()=>words.add(WordEntry(english:e.text.trim(),chinese:z.text.trim())));Navigator.pop(c);},child:const Text('保存'))]));}
 @override void dispose(){search.dispose();super.dispose();}
 @override Widget build(BuildContext c){final list=shown;final max=words.isEmpty?1:words.length;if(count>max)count=max;return Scaffold(appBar:AppBar(title:const Text('词汇库'),actions:[IconButton(onPressed:add,icon:const Icon(Icons.add))]),body:Padding(padding:const EdgeInsets.all(16),child:Column(children:[TextField(controller:search,onChanged:(_)=>setState((){}),decoration:const InputDecoration(prefixIcon:Icon(Icons.search),hintText:'搜索英文或中文')),const SizedBox(height:8),Text('词汇 ${words.length} 个 · 当前显示 ${list.length} 个'),Expanded(child:ListView.builder(itemCount:list.length,itemBuilder:(_,i){final w=list[i];return ListTile(title:Text(w.english),subtitle:Text(w.chinese),trailing:IconButton(icon:const Icon(Icons.delete_outline),onPressed:()=>setState(()=>words.remove(w)));})),if(words.isNotEmpty)...[Text('本次测试：$count 题'),Slider(value:count.toDouble(),min:1,max:max.toDouble(),divisions:max-1,label:'$count',onChanged:(v)=>setState(()=>count=v.round())),FilledButton.icon(onPressed:()=>Navigator.push(c,MaterialPageRoute(builder:(_)=>VocabularyReviewPage(words:words,count:count))),icon:const Icon(Icons.play_arrow),label:const Text('开始测试'))]else const Text('请先新增至少一个词汇')])));}
}
