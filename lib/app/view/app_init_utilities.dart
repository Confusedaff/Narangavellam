import 'package:flutter/widgets.dart';
import 'package:narangavellam/l10n/l10n.dart';
import 'package:shared/shared.dart';

void initUtilities(BuildContext context, Locale locale) {
  final isSameLocal = Localizations.localeOf(context) == locale;
  if (isSameLocal) return;

  final l10n = context.l10n;

  PickImage().init(
    tabsTexts: TabsTexts(
      photoText: l10n.photoText,
      videoText: l10n.videoText,
      acceptAllPermissions: l10n.acceptAllPermissionsText,
      clearImagesText: l10n.clearImagesText,
      deletingText: l10n.deletingText,
      galleryText: l10n.galleryText,
      holdButtonText: l10n.holdButtonText,
      noMediaFound: l10n.noMediaFound,
      notFoundingCameraText: l10n.notFoundingCameraText,
      noCameraFoundText: l10n.noCameraFoundText,
      newPostText: l10n.newPostText,
      newAvatarImageText: l10n.newAvatarImageText,
    ),
  );
}

// StoriesEditorLocalizationDelegate storiesEditorLocalizationDelegate(
//   BuildContext context,
// ) {
//   final l10n = context.l10n;
//   return StoriesEditorLocalizationDelegate(
//     cancelText: l10n.cancelText,
//     discardEditsText: l10n.discardEditsText,
//     discardText: l10n.discardText,
//     doneText: l10n.doneText,
//     draftEmpty: l10n.draftEmpty,
//     errorText: l10n.errorText,
//     loseAllEditsText: l10n.loseAllEditsText,
//     saveDraft: l10n.saveDraft,
//     successfullySavedText: l10n.successfullySavedText,
//     tapToTypeText: l10n.tapToTypeText,
//     uploadText: l10n.uploadText,
//   );
// }