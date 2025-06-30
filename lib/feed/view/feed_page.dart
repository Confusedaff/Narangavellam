import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:insta_blocks/insta_blocks.dart';
import 'package:narangavellam/feed/bloc/feed_bloc.dart';
import 'package:narangavellam/feed/post/view/post_view.dart';
import 'package:posts_repository/posts_repository.dart';

class FeedPage extends StatelessWidget {
  const FeedPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create:(context) => FeedBloc(postsRepository: context.read<PostsRepository>()),
      child: const FeedView(),);
  }
}

class FeedView extends StatefulWidget {
  const FeedView({super.key});

  @override
  State<FeedView> createState() => _FeedViewState();
}

class _FeedViewState extends State<FeedView> {
  @override
  void initState() {
    super.initState();
    context.read<FeedBloc>().add(const FeedPageRequested(page: 0));
  }
  @override
  Widget build(BuildContext context) {
    return const AppScaffold(
                    body: FeedBody(),
    );
  }
}

class FeedBody extends StatelessWidget {
  const FeedBody({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        BlocBuilder<FeedBloc, FeedState>(
          builder: (context, state) {
            final blocks = state.feed.feedPage.blocks;
            return SliverList.builder(
              itemCount: state.feed.feedPage.totalBlocks,
              itemBuilder: (context, index) {
                final block = blocks[index];
                return switch ('') {
                  _ when block is PostBlock => PostView(
                    block: block,
                    withInViewNotifier: false,
                    ),
                  _ => SizedBox(
                        child: Text('Unsupported block type: ${block.type}'),
                      ),
                };
              },
            );
          },
        ),
      ],
    );
  }
}
