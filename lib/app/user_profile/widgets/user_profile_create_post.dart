import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:instagram_blocks_ui/instagram_blocks_ui.dart';
import 'package:narangavellam/app/home/provider/home_provider.dart';
import 'package:narangavellam/app/view/app.dart';
import 'package:narangavellam/feed/feed.dart';
import 'package:narangavellam/l10n/l10n.dart';
import 'package:posts_repository/posts_repository.dart';
import 'package:powersync_repository/powersync_repository.dart';
import 'package:shared/shared.dart';

class UserProfileCreatePost extends StatelessWidget {
  const UserProfileCreatePost({
    this.canPop = true,
    this.imagePickerKey,
    this.onPopInvoked,
    this.onBackButtonTap,
    this.pickVideo = false,
    super.key,
  });

  final bool canPop;
  final Key? imagePickerKey;
  final bool pickVideo;
  final VoidCallback? onBackButtonTap;
  final VoidCallback? onPopInvoked;


  @override
  Widget build(BuildContext context) {
  final pickerSource = pickVideo ? PickerSource.video : PickerSource.both;
  return PopScope(
      canPop: canPop,
      // ignore: deprecated_member_use
      onPopInvoked: (didPop) {
        if (didPop) return;
        onPopInvoked?.call();
      },
      child: PickImage().customMediaPicker(
        key: imagePickerKey,
        context: context,
        source: ImageSource.both,
        pickerSource: pickerSource,
        multiSelection: !pickVideo,
        onMediaPicked: (details) => context.pushNamed(
          'publish_post',
          extra: CreatePostProps(details: details,pickVideo: pickVideo),
        ),
        onBackButtonTap:
            onBackButtonTap != null ? () => onBackButtonTap?.call() : null,
      ),
    );
  } 
}

class CreatePostProps {
  const CreatePostProps({
    required this.details,
    this.pickVideo = false,
    this.context,
  });

  final SelectedImagesDetails details;
  final bool pickVideo;
  final BuildContext? context;
}

class CreatePostPage extends StatefulWidget {
  const CreatePostPage({required this.props,super.key});

  final CreatePostProps props;

  @override
  State<CreatePostPage> createState() => _CreatePostPageState();
}

class _CreatePostPageState extends State<CreatePostPage> {
  late TextEditingController _captionController;
  late List<Media> _media;

  List<SelectedByte> get selectedFiles => widget.props.details.selectedFiles;

  @override
   void initState(){
    super.initState();
    _captionController = TextEditingController();
    _media = selectedFiles
    .map(
      (e) => e.isThatImage
          ? MemoryImageMedia(bytes: e.selectedByte, id: uuid.v4())
          : MemoryVideoMedia(id: uuid.v4(), file: e.selectedFile),
    )
    .toList();
  }

  @override
  void dispose(){
    _captionController.dispose();
    super.dispose();
  }

  Future<void> _onShareTap(String caption) async{
    toggleLoadingIndeterminate();
    await Future<void>.delayed(const Duration(milliseconds: 100));
    void goHome(){
    if (!widget.props.pickVideo) {
    //context.go('/user');
      // context
      //       ..pop()
      //       ..pop();
      HomeProvider().animateToPage(1);
      FeedPageController().scrollToTop();
    } 
    }

    try{
      //toggleLoadingIndeterminate();

      final postId = uuid.v4();

      unawaited(FeedPageController().processPostMedia(
        selectedFiles: selectedFiles, 
        postId: postId, 
        caption: caption, 
        pickVideo: widget.props.pickVideo
        ,)
        ,);
        if (!mounted) return;

      void uploadPost({required List<Map<String,dynamic>>media,}) =>
        context.read<PostsRepository>().createPost(id: postId, caption: caption, media: jsonEncode(media));

     if(widget.props.pickVideo){
      try{
        late final postId = uuid.v4();
        late final storage = Supabase.instance.client.storage.from('posts');

        late final mediaPath = '$postId/video_0';

        final selectedFile = selectedFiles.first;
        final firstFrame = await VideoPlus.getVideoThumbnail(
        selectedFile.selectedFile,
        );
        if (!mounted) return;
        final blurHash = firstFrame == null
          ? ''
          : await BlurHashPlus.blurHashEncode(firstFrame);
        final compressedVideo = (await VideoPlus.compressVideo(
          selectedFile.selectedFile,
        ))
          ?.file ?? 
          selectedFile.selectedFile;
        final compressedVideoBytes = await PickImage().imageBytes(
        file: compressedVideo,
        );
        if (!mounted) return;
        final attachment = AttachmentFile(
        size: compressedVideoBytes.length,
        bytes: compressedVideoBytes,
        path: compressedVideo.path,
        );

        await storage.uploadBinary(
        mediaPath,
        attachment.bytes!,
        fileOptions: FileOptions(
        contentType: attachment.mediaType!.mimeType,
        cacheControl: '9000000',
        ),
      );
        if (!mounted) return;
        final mediaUrl = storage.getPublicUrl(mediaPath);
        String? firstFrameUrl;
        if (firstFrame != null) {
        late final firstFramePath = '$postId/video_first_frame_0';
        await storage.uploadBinary(
        firstFramePath,
        firstFrame,
        fileOptions: FileOptions(
        contentType: attachment.mediaType!.mimeType,
        cacheControl: '9000000',
     ),
    );
    if (!mounted) return;
        firstFrameUrl = storage.getPublicUrl(firstFramePath);
    }
    final media = [
        {
        'media_id': uuid.v4(),
        'url': mediaUrl,
        'type': VideoMedia.identifier,
        'blur_hash': blurHash,
        'first_frame_url': firstFrameUrl,
        }
      ];
      uploadPost(media: media);
      }catch(error,stackTrace){
        logE('Failed to create Reel!',
          error: error,
          stackTrace: stackTrace,
        );
       }
    }else{
        final storage = Supabase.instance.client.storage.from('posts');

      final media = <Map<String, dynamic>>[];
      for (var i = 0; i < selectedFiles.length; i++) {
      late final selectedByte = selectedFiles[i].selectedByte;
      late final selectedFile = selectedFiles[i].selectedFile;
      late final isVideo = selectedFile.isVideo;
      String blurHash;
      Uint8List? convertedBytes;
      if (isVideo) {
        convertedBytes = await VideoPlus.getVideoThumbnail(
          selectedFile,
        );
        if (!mounted) return;
        blurHash = convertedBytes == null
        ? ''
        : await BlurHashPlus.blurHashEncode(
          convertedBytes,
        );
        if (!mounted) return;
        } else {
        blurHash = await BlurHashPlus.blurHashEncode(
        selectedByte,
      );
      if (!mounted) return;
      }
      late final mediaExtension =
          selectedFile.path.split('.').last.toLowerCase();

        late final mediaPath = '$postId/${!isVideo ? 'image_$i' : 'video_$i'}';

        Uint8List bytes;
        if (isVideo) {
          try {
              final compressedVideo = await VideoPlus.compressVideo(
              selectedFile,
             );
             if (!mounted) return;
        bytes = await PickImage().imageBytes(
              file: compressedVideo!.file!,
        );
        if (!mounted) return;
        } catch (error, stackTrace) {
        logE(
            'Error compressing video',
             error: error,
              stackTrace: stackTrace,
          );
        bytes = selectedByte;
        }
      } else {
        bytes = selectedByte;
        }
        await storage.uploadBinary(
          mediaPath,
          bytes,
          fileOptions: FileOptions(
          contentType: '${!isVideo ? 'image' : 'video'}/$mediaExtension',
          cacheControl: '900000',
        ),
      );
      if (!mounted) return;
    final mediaUrl = storage.getPublicUrl(mediaPath);
    String? firstFrameUrl;
    if (convertedBytes != null) {
    late final firstFramePath = '$postId/video_first_frame_$i';
    await storage.uploadBinary(
    firstFramePath,
    convertedBytes,
    fileOptions: FileOptions(
      contentType: 'video/$mediaExtension',
      cacheControl: '900000',
    ),
    );
    if (!mounted) return;
    firstFrameUrl = storage.getPublicUrl(firstFramePath);
    }

    final mediaType =
      isVideo ? VideoMedia.identifier : ImageMedia.identifier;
      if (isVideo) {
      media.add({
      'media_id': uuid.v4(),
      'url': mediaUrl,
      'type': mediaType,
      'blur_hash': blurHash,
      'first_frame_url': firstFrameUrl,
    });
    } else {
      media.add({
      'media_id': uuid.v4(),
      'url': mediaUrl,
      'type': mediaType,
      'blur_hash': blurHash,
    });
    }
    }
    uploadPost(media: media);
    }
      goHome.call();
      toggleLoadingIndeterminate(enable: false);
      openSnackbar(
      const SnackbarMessage.success(
        title: 'Successfully created post!',
      ),
      );
      }
      catch(error,stackTrace){
      toggleLoadingIndeterminate(enable: false);
      logE('Failed to create post',error: error,stackTrace: stackTrace);
      openSnackbar(
        const SnackbarMessage.error(title: 'Failed to create Post!'),
      );
    }
  } 

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      releaseFocus: true,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        centerTitle: false,
        title: Text(context.l10n.newPostText),
      ),
      bottomNavigationBar: PublishPostButton(onShareTap: () => _onShareTap(_captionController.text)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.sm,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PostMedia(
              media: _media, 
              withInViewNotifier: false,
              withLikeOverlay: false,
              autoHideCurrentIndex: false,
              mediaCarouselSettings: const MediaCarouselSettings.empty(
                viewportFraction: .9,
              ),
              ),
            const Gap.v(AppSpacing.sm),
            CaptionInputField(
              captionController: _captionController, 
              caption: _captionController.text.trim(), 
              onSubmitted: _onShareTap,
            ),
          ],
        ),
      ),
    );
  }
}

class PublishPostButton extends StatelessWidget {
  const PublishPostButton({required this.onShareTap, super.key});

  final VoidCallback onShareTap;

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      elevation: 0,
      color: context.reversedAdaptiveColor,
      padding: EdgeInsets.zero,
      height: 90,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const AppDivider(),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.md,
            ),
            child: Tappable.faded(
              onTap: onShareTap,
              borderRadius: BorderRadius.circular(6),
              backgroundColor: AppColors.blue,
              child: Align(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: AppSpacing.md,
                    horizontal: AppSpacing.sm,
                  ),
                  child: Text(
                    context.l10n.sharePostText,
                    style: context.labelLarge,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CaptionInputField extends StatefulWidget {
  const CaptionInputField({
    required this.captionController,
    required this.caption,
    required this.onSubmitted,
    super.key, 
  });

  final TextEditingController captionController;
  final String caption;
  final ValueSetter<String> onSubmitted;

  @override
  State<CaptionInputField> createState() => _CaptionInputFieldState();
}

class _CaptionInputFieldState extends State<CaptionInputField> {
  late String _initialCaption;

    @override
  void initState() {
    super.initState();
    _initialCaption = widget.caption;
  }

  @override
  void didUpdateWidget(covariant CaptionInputField oldWidget) {
      super.didUpdateWidget(oldWidget);
      if (oldWidget.caption != _initialCaption) {
        setState(() => _initialCaption = widget.caption);
    }
  }

    String _effectiveValue(String? value) =>
      value ?? widget.captionController.text.trim();

  bool _equals(String? value) => _initialCaption == _effectiveValue(value);

  @override
  Widget build(BuildContext context) {
  return AppTextField(
    border: InputBorder.none,
    textController: widget.captionController,
    contentPadding: EdgeInsets.zero,
    textInputType: TextInputType.text,
    textInputAction: TextInputAction.done, // might  want to change here
    textCapitalization: TextCapitalization.sentences,
    hintText: context.l10n.writeCaptionText,
    onFieldSubmitted: (value) =>
                    _equals(value) ? null : widget.onSubmitted(_effectiveValue(value)),
    );
  }
}
