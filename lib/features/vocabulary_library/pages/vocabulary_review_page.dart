import 'dart:math';
import 'package:flutter/material.dart';
import '../../../models/word_entry.dart';

class VocabularyReviewPage extends StatefulWidget {
  const VocabularyReviewPage({super.key, required this.words, required this.count});
  final List<WordEntry> words;
  final int count;
  @override State<VocabularyReviewPage> createState()=>_VocabularyReviewPageState();
}
class _VocabularyReviewPageState extends State<VocabularyReviewPage> {
  late final List<WordEntry> items;
  int i=0,hint=0; bool answer=false;
  @override void initState(){super.initState();items=[...widget.words]..shuffle(Random());items=items.take(widget.count).toList();}
  @override Widget build(BuildContext c){
    final w=items[i], en=i.isEven, q=en?w.english:w.chinese, a=en?w.chinese:w.english;
    final shown=en||answer?a:a.substring(0,min(hint,a.length));
    return Scaffold(appBar:AppBar(leading:IconButton(icon:const Icon(Icons.close),onPressed:()=>Navigator.pop(c))),body:Padding(padding:const EdgeInsets.all(24),child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[Text('${i+1}/${items.length}',textAlign:TextAlign.right),const Spacer(),Text(q,textAlign:TextAlign.center,style:Theme.of(c).textTheme.headlineMedium),const SizedBox(height:24),Text(shown,textAlign:TextAlign.center,style:Theme.of(c).textTheme.headlineSmall),const Spacer(),if(!en&&!answer)OutlinedButton(onPressed:()=>setState(()=>hint=min(hint+1,a.length)),child:const Text('提示')),OutlinedButton(onPressed:()=>setState(()=>answer=true),child:const Text('显示答案')),FilledButton(onPressed:()=>i+1==items.length?Navigator.pop(c):setState((){i++;hint=0;answer=false;}),child:Text(i+1==items.length?'完成':'下一题'))])));
  }
}
