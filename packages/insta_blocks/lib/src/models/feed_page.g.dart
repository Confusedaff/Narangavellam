// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'feed_page.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FeedPage _$FeedPageFromJson(Map<String, dynamic> json) => FeedPage(
      blocks: const InstaBlocksConverter()
          .fromJson(json['blocks'] as List<Map<String, dynamic>>),
      totalBlocks: (json['totalBlocks'] as num).toInt(),
      page: (json['page'] as num).toInt(),
      hasMore: json['hasMore'] as bool,
    );

Map<String, dynamic> _$FeedPageToJson(FeedPage instance) => <String, dynamic>{
      'blocks': const InstaBlocksConverter().toJson(instance.blocks),
      'totalBlocks': instance.totalBlocks,
      'page': instance.page,
      'hasMore': instance.hasMore,
    };
