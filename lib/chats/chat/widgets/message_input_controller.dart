// ignore_for_file: use_setters_to_change_properties

import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:narangavellam/chats/chat/widgets/message_text_field_controller.dart';
import 'package:shared/shared.dart';

/// A function that takes a [BuildContext] and returns a [TextStyle].
typedef TextStyleBuilder = TextStyle? Function(
  BuildContext context,
  String text,
);

/// A value listenable builder related to a [Message].
///
/// Pass in a [MessageInputController] as the `valueListenable`.
typedef MessageValueListenableBuilder = ValueListenableBuilder<Message>;

class MessageInputController extends ValueNotifier<Message> {
  /// Creates a controller for an editable text field.
  ///
  /// This constructor treats a null [message] argument as if it were the empty
  /// message.
  factory MessageInputController({
    Message? message,
    Map<RegExp, TextStyleBuilder>? textPatternStyle,
  }) =>
      MessageInputController._(
        initialMessage: message ?? Message(),
        textPatternStyle: textPatternStyle,
      );

  /// Creates a controller for an editable text field from an initial [text].
  factory MessageInputController.fromText(
    String? text, {
    Map<RegExp, TextStyleBuilder>? textPatternStyle,
  }) =>
      MessageInputController._(
        initialMessage: Message(message: text ?? ''),
        textPatternStyle: textPatternStyle,
      );

  /// Creates a controller for an editable text field from initial
  /// [attachments].
  factory MessageInputController.fromAttachments(
    List<Attachment> attachments, {
    Map<RegExp, TextStyleBuilder>? textPatternStyle,
  }) =>
      MessageInputController._(
        initialMessage: Message(attachments: attachments),
        textPatternStyle: textPatternStyle,
      );

  MessageInputController._({
    required Message initialMessage,
    Map<RegExp, TextStyleBuilder>? textPatternStyle,
  })  : _initialMessage = initialMessage,
        _textFieldController = MessageTextFieldController.fromValue(
          _textEditingValueFromMessage(initialMessage),
          textPatternStyle: textPatternStyle,
        ),
        super(initialMessage) {
    _textFieldController.addListener(_textFieldListener);
  }

  /// Returns the controller of the text field linked to this controller.
  MessageTextFieldController get textFieldController => _textFieldController;
  MessageTextFieldController _textFieldController;

  Message _initialMessage;

  static TextEditingValue _textEditingValueFromMessage(Message message) {
    final messageText = message.message;
    var textEditingValue = TextEditingValue.empty;
    if (messageText.isNotEmpty) {
      textEditingValue = TextEditingValue(
        text: messageText,
        selection: TextSelection.collapsed(offset: messageText.length),
      );
    }
    return textEditingValue;
  }

  void _textFieldListener() {
    final text = _textFieldController.text;
    message = message.copyWith(message: text);
  }

  /// Returns the current message associated with this controller.
  Message get message => value;

  /// Sets the current message associated with this controller.
  set message(Message message) => value = message;

  @override
  set value(Message message) {
    super.value = message;

    // Update text field controller only if message text has changed.
    final messageText = message.message;
    final textFieldText = _textFieldController.text;
    if (messageText != textFieldText) {
      textEditingValue = _textEditingValueFromMessage(message);
    }
  }

  /// Text of the message.
  String get text => _textFieldController.text;

  /// Sets the text of the message.
  set text(String text) {
    _textFieldController.text = text;
  }

  /// The currently selected [text].
  ///
  /// If the selection is collapsed, then this property gives the offset of the
  /// cursor within the text.
  TextSelection get selection => _textFieldController.selection;

  set selection(TextSelection newSelection) {
    _textFieldController.selection = selection;
  }

  /// Returns the textEditingValue associated with this controller.
  TextEditingValue get textEditingValue => _textFieldController.value;

  set textEditingValue(TextEditingValue value) {
    _textFieldController.value = value;
  }

  /// Returns the attachments of the message.
  List<Attachment> get attachments => message.attachments;

  /// Sets the list of [attachments] for the message.
  set attachments(List<Attachment> attachments) {
    message = message.copyWith(attachments: attachments);
  }

  /// Adds a new attachment to the message.
  void addAttachment(Attachment attachment) {
    attachments = [...attachments, attachment];
  }

  /// Removes the specified [attachment] from the message.
  void removeAttachment(Attachment attachment) {
    attachments = [...attachments]..remove(attachment);
  }

  /// Clears the message attachments.
  void clearAttachments() {
    attachments = [];
  }

  /// Local replying message instance. String represents user name that
  /// we are trying to reply, followed by his message.
  Message? _replyingMessage;

  Message? get replyingMessage => _replyingMessage;

  void setReplyingMessage(Message replyingMessage) {
    clearEditingMessage();
    final alreadyReplied = replyingMessage.replyMessageId != null &&
        replyingMessage.attachments.isEmpty;
    message = message.copyWith(
      replyMessageId: replyingMessage.id,
      replyMessageUsername: replyingMessage.sender?.username,
      replyMessageAttachmentUrl: alreadyReplied
          ? null
          : replyingMessage.sharedPost != null
              ? replyingMessage.sharedPost?.firstMediaUrl
              : replyingMessage.attachments.firstOrNull?.imageUrl,
      sharedPostId: replyingMessage.sharedPostId,
    );
    _replyingMessage = replyingMessage.sharedPost != null
        ? replyingMessage.copyWith(
            replyMessageAttachmentUrl:
                replyingMessage.sharedPost?.firstMediaUrl,
          )
        : replyingMessage.copyWith(
            replyMessageAttachmentUrl:
                replyingMessage.attachments.firstOrNull?.imageUrl,
          );
  }

  /// Local editing message instance.
  Message? _editingMessage;

  Message? get editingMessage => _editingMessage;

  void setEditingMessage(Message message) {
    clearReplyingMessage();
    if (message.message.trim().isEmpty) return;
    _editingMessage = message;
    this.message =
        this.message.copyWith(id: message.id, message: message.message);
  }

  void clearEditingMessage() {
    if (_editingMessage == null) return;
    message = Message.empty;
    if (_editingMessage != null) {
      _editingMessage = null;
    }
  }

  void clearReplyingMessage() {
    if (replyingMessage == null) return;
    message = Message.empty;
    if (_replyingMessage != null) {
      _replyingMessage = null;
    }
  }

  /// Returns the og attachment of the message if set
  Attachment? get ogAttachment =>
      attachments.firstWhereOrNull((it) => it.id == _ogAttachment?.id);

  // Only used to store the value locally in order to remove it if we call
  // [clearOGAttachment] or [setOGAttachment] again.
  Attachment? _ogAttachment;

  /// Sets the og attachment in the message.
  void setOGAttachment(Attachment attachment) {
    if (attachments
        .map((e) => e.type.toAttachmentType)
        .contains(AttachmentType.urlPreview)) {
      attachments = attachments
        ..removeWhere(
          (e) => e.type.toAttachmentType == AttachmentType.urlPreview,
        );
    }
    addAttachment(attachment);
    _ogAttachment = attachment;
  }

  /// Removes the og attachment.
  void clearOGAttachment() {
    if (_ogAttachment != null) {
      removeAttachment(_ogAttachment!);
    }
    _ogAttachment = null;
  }

  /// Sets the [message], to empty.
  void clear() {
    message = Message.empty;
  }

  /// Sets the [message] to the initial [Message] value.
  void reset({bool resetId = true}) {
    if (resetId) {
      final newId = uuid.v4();
      _initialMessage = _initialMessage.copyWith(id: newId);
    }
    // Reset the message to the initial value.
    message = _initialMessage;
  }

  /// Sets the [message] to the initial [Message] value.
  void resetAll({bool resetId = true}) {
    clearAttachments();
    clearOGAttachment();
    clearReplyingMessage();
    clearEditingMessage();

    reset(resetId: resetId);
  }

  @override
  void dispose() {
    _textFieldController
      ..removeListener(_textFieldListener)
      ..dispose();
    super.dispose();
  }
}

/// A [RestorableProperty] that knows how to store and restore a
/// [MessageInputController].
///
/// The [MessageInputController] is accessible via the [value] getter.
/// During state restoration,
/// the property will restore [MessageInputController.message]
/// to the value it had when the restoration data it is getting restored from
/// was collected.
class RestorableMessageInputController
    extends RestorableChangeNotifier<MessageInputController> {
  /// Creates a [RestorableMessageInputController].
  ///
  /// This constructor creates a default [Message] when no `message` argument
  /// is supplied.
  RestorableMessageInputController({Message? message})
      : _initialValue = message ?? Message();

  /// Creates a [RestorableMessageInputController] from an initial
  /// [text] value.
  factory RestorableMessageInputController.fromText(String? text) =>
      RestorableMessageInputController(
        message: Message(message: text ?? ''),
      );

  final Message _initialValue;

  @override
  MessageInputController createDefaultValue() =>
      MessageInputController(message: _initialValue);

  @override
  MessageInputController fromPrimitives(Object? data) {
    final message =
        Message.fromJson(json.decode(data! as String) as Map<String, dynamic>);
    return MessageInputController(message: message);
  }

  @override
  String toPrimitives() => json.encode(value.message);
}
