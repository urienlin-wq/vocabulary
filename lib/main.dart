import 'package:flutter/material.dart';
import 'models/word_entry.dart';
import 'features/vocabulary_library/pages/vocabulary_review_page.dart';
void main()=>runApp(const App());
class App extends StatelessWidget{const App({super.key});@override Widget build(BuildContext c)=>MaterialApp(home:const Home());}
class Home extends StatefulWidget{const Home({super.key});@override State<Home> createState()=>_HomeState();}
class _HomeState extends State<Home>{
 final words=const [WordEntry(english:'apple',chinese:'苹果'),WordEntry(english:'book',chinese:'书'),WordEntry(english:'learn',chinese:'学习'),WordEntry(english:'water',chinese:'水')]; int count=4;
 @override Widget build(BuildContext c)=>Scaffold(appBar:AppBar(title:const Text('词汇库')),body:Padding(padding:const EdgeInsets.all(24),child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[Text('共 ${words.length} 个词汇'),const SizedBox(height:24),Text('本次测试：$count 题'),Slider(value:count.toDouble(),min:1,max:words.length.toDouble(),divisions:words.length-1,label:'$count',onChanged:(v)=>setState(()=>count=v.round())),FilledButton(onPressed:()=>Navigator.push(c,MaterialPageRoute(builder:(_)=>VocabularyReviewPage(words:words,count:count))),child:const Text('开始测试'))])));
}
