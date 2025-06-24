import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:narangavellam/app/bloc/app_bloc.dart';
import 'package:narangavellam/app/user_profile/bloc/user_profile_bloc.dart';
import 'package:narangavellam/app/user_profile/widgets/user_profile_header.dart';
import 'package:narangavellam/l10n/l10n.dart';
import 'package:posts_repository/posts_repository.dart';
import 'package:sliver_tools/sliver_tools.dart';
import 'package:user_repository/user_repository.dart';

class UserProfilePage extends StatelessWidget {
  const UserProfilePage({required this.userId, super.key});

  final String userId;

 @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => UserProfileBloc(
            userId: userId,
            postsRepository: context.read<PostsRepository>(),
            userRepository: context.read<UserRepository>(),
          )
            ..add(const UserProfileSubscriptionRequested())
            ..add(const UserProfilePostsCountSubscriptionRequested())
            ..add(const UserProfileFollowingsCountSubscriptionRequested())
            ..add(const UserProfileFollowersCountSubscriptionRequested()),
        ),
      ],
      child: UserProfileView(userId: userId),
    );
  }
}

class UserProfileView extends StatefulWidget {
  const UserProfileView({required this.userId, super.key});

  final String userId;

  @override
  State<UserProfileView> createState() => _UserProfileViewState();
}

class _UserProfileViewState extends State<UserProfileView> {
  late ScrollController _nestedScrollController;

  @override
  void initState() {
    _nestedScrollController = ScrollController();
    super.initState();
  }

  @override
  void dispose() {
    _nestedScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.select((UserProfileBloc bloc) => bloc.state.user);

    return AppScaffold(
      body: DefaultTabController(
        length: 2,
        child: NestedScrollView(
          controller: _nestedScrollController,
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverOverlapAbsorber(
                handle:
                    NestedScrollView.sliverOverlapAbsorberHandleFor(context),
                sliver: MultiSliver(
                  children: [
                    const UserProfileAppBar(),
                    if (!user.isAnonymous) ...[
                      UserProfileHeader(
                        userId: widget.userId,
                      ),
                    ],
                  ],
                ),
              ),
            ];
          },
          body: const Column(),
        ),
      ),
    );
  }
}

class UserProfileAppBar extends StatelessWidget {
  const UserProfileAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    final isOwner = context.select((UserProfileBloc bloc) => bloc.isOwner);
    final user = context.select((UserProfileBloc bloc) => bloc.state.user);

    return SliverPadding(
      padding: const EdgeInsets.only(right: AppSpacing.md),
      sliver: SliverAppBar(
        centerTitle: false,
        pinned: !ModalRoute.of(context)!.isFirst,
        floating: ModalRoute.of(context)!.isFirst,
        title: Row(
          children: [
            Flexible(
              flex: 12,
              child: Text(
                // ignore: unnecessary_string_interpolations
                '${user.displayUsername}',
                style: context.titleLarge?.copyWith(
                  fontWeight: AppFontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Flexible(
              child: Assets.icons.verifiedUser.svg(
                width: AppSize.iconSizeSmall,
                height: AppSize.iconSizeSmall,
              ),
            ),
          ],
        ),
        actions: [
          if (!isOwner)
            const UserProfileActions()
          else ...[
            const UserProfileAddMediaButton(),
            if (ModalRoute.of(context)?.isFirst ?? false) ...const [
              Gap.h(AppSpacing.md),
              UserProfileSettingsButton(),
            ],
          ],
        ],
      ),
    );
  }
}

class UserProfileActions extends StatelessWidget {
  const UserProfileActions({super.key});

  @override
  Widget build(BuildContext context) {
    return Tappable(
      onTap: () {},
      child: Icon(Icons.adaptive.more_outlined, size: AppSize.iconSize),
    );
  }
}

class UserProfileSettingsButton extends StatelessWidget {
  const UserProfileSettingsButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Tappable(
      onTap: () => context.showListOptionsModal(
        options: [
          // ModalOption(child: const LocaleModalOption()),
          //ModalOption(child: const ThemeSelectorModalOption()),
          //ModalOption(child: const LogoutModalOption()),
        ],
      ).then((option) {
        if (option == null) return;
        option.onTap(context);
      }),
      child: Assets.icons.setting.svg(
        height: AppSize.iconSize,
        width: AppSize.iconSize,
        colorFilter: ColorFilter.mode(
          context.adaptiveColor,
          BlendMode.srcIn,
        ),
      ),
    );
  }
}

class UserProfileAddMediaButton extends StatelessWidget {
  const UserProfileAddMediaButton({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final user = context.select((AppBloc bloc) => bloc.state.user);
    // final enableStory =
    //context.select((CreateStoriesBloc bloc) => bloc.state.isAvailable);

    return Tappable(
      onTap: () {},
      child: const Icon(
        Icons.add_box_outlined,
        size: AppSize.iconSize,
      ),
    );
  }
}
