import 'dart:math';

import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:insta_blocks/insta_blocks.dart';
import 'package:narangavellam/l10n/l10n.dart';
import 'package:shared/shared.dart';

class FeedPage extends StatelessWidget {
  const FeedPage({super.key});

  @override
  Widget build(BuildContext context) {
    return FeedView();
  }
}

class FeedView extends StatelessWidget {
  const FeedView({super.key});

  @override
  Widget build(BuildContext context) {
    final feed = List.generate(10, (index) => PostLargeBlock(
      id: uuid.v4(), 
      author: PostAuthor.randomConfirmed(), 
      createdAt:  DateTime.now().subtract(Duration(days:Random().nextInt(365))), 
      media: [ImageMedia(
        id: uuid.v4(), 
        url: 'https://cdn.pixabay.com/photo/2024/09/21/10/53/anime-9063542_1280.png',
        ), ],
      caption: 'NANANANANAANA',
      ),);

    return AppScaffold(
                    body: Column(
                      children: [
                        Text.rich(
                          t.likedBy(
                            name: const TextSpan(text: 'email'),
                            and : const TextSpan(text: 'and'),
                            others: const TextSpan(text: '5 others'),
                        ),
                        ),
                        Expanded(
                          child: ListView.builder(
                            itemCount: feed.length,
                            itemBuilder: (context,index){
                            final post = feed[index];
                            return Image.network(post.firstMediaUrl!);
                          },
                          ),
                        ),
                      ],
                    ),
    );
  }
}
