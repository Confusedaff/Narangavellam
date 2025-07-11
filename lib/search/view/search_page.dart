import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:narangavellam/l10n/l10n.dart';
import 'package:narangavellam/stories/widgets/user_stories_avatar.dart';
import 'package:search_repository/search_repository.dart';
import 'package:shared/shared.dart';
import 'package:user_repository/user_repository.dart';

class SearchPage extends StatelessWidget {
  const SearchPage({this.withResult, super.key});

  final bool? withResult;

  @override
  Widget build(BuildContext context) {
    return SearchView(withResult: withResult ?? false);
  }
}

class SearchView extends StatelessWidget {
  const SearchView({required this.withResult, super.key});

  final bool withResult;

  @override
  Widget build(BuildContext context) {
    final users = ValueNotifier(<User>[]);

    return AppScaffold(
      appBar:
          SearcAppBar(onUsersSearch: (foundUsers) => users.value = foundUsers),
      body: ValueListenableBuilder(
        valueListenable: users,
        builder: (context, users, _) {
          return CustomScrollView(
            cacheExtent: 2760,
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            slivers: [
              SliverList.builder(
                itemCount: users.length,
                itemBuilder: (context, index) {
                  final user = users[index];
                  return UserListTile(
                    key: ValueKey(user.id),
                    user: user,
                    withResult: withResult,
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

class UserListTile extends StatelessWidget {
  const UserListTile({
    required this.user,
    required this.withResult,
    super.key,
  });

  final User user;
  final bool withResult;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: UserStoriesAvatar(
        resizeHeight: 156,
        author: user,
        withAdaptiveBorder: false,
        enableInactiveBorder: false,
        radius: 26,
      ),
      title: Text(user.displayUsername),
      subtitle: Text(
        user.displayFullName,
        style: context.labelLarge?.copyWith(
          fontWeight: AppFontWeight.medium,
          color: AppColors.grey,
        ),
      ),
      trailing: const Icon(Icons.keyboard_arrow_right),
      onTap: () => withResult
          ? context.pop(user.id)
          : context.pushNamed(
              'user_profile',
              pathParameters: {'user_id': user.id},
            ),
    );
  }
}

class SearcAppBar extends StatefulWidget implements PreferredSizeWidget {
  const SearcAppBar({required this.onUsersSearch, super.key});

  final ValueSetter<List<User>> onUsersSearch;

  @override
  State<SearcAppBar> createState() => _SearcAppBarState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _SearcAppBarState extends State<SearcAppBar> {
  late FocusNode _focusNode;
  late TextEditingController _searchController;

  late Debouncer _debouncer;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _searchController = TextEditingController();

    _debouncer = Debouncer();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: SearchInputField(
        active: false,
        readOnly: false,
        focusNode: _focusNode,
        textController: _searchController,
        onChanged: (query) {
          _debouncer.run(
            () async => widget.onUsersSearch.call(
              await context.read<SearchRepository>().searchUsers(query: query),
            ),
          );
        },
      ),
    );
  }
}

class SearchInputField extends StatelessWidget {
  const SearchInputField({
    required this.active,
    required this.readOnly,
    this.textController,
    this.focusNode,
    this.onChanged,
    super.key,
  });

  final TextEditingController? textController;
  final FocusNode? focusNode;
  final ValueSetter<String>? onChanged;
  final bool active;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    final activeColor = context.adaptiveColor;
    const inactiveColor = AppColors.grey;

    final search = AppTextField(
      filled: true,
      focusNode: focusNode,
      readOnly: readOnly,
      autofocus: !readOnly,
      textController: textController,
      onChanged: textController == null
          ? null
          : (query) {
              onChanged?.call(query);
            },
      constraints: const BoxConstraints.tightFor(height: 40),
      onTap: !readOnly ? null : () => context.pushNamed('search'), //**change here **//
      hintText: context.l10n.searchText,
      prefixIcon:
          Icon(Icons.search, color: active ? activeColor : inactiveColor),
      suffixIcon: textController?.text.trim().isEmpty ?? true
          ? null
          : Icon(
              Icons.clear,
              color: active ? activeColor : inactiveColor,
            ),
      border: outlinedBorder(borderRadius: 14),
    );
    if (textController != null) {
      return ListenableBuilder(
        listenable: textController!,
        builder: (context, child) => search,
      );
    }

    return search;
  }
}
