import 'package:crimson/crimson.dart';
import 'package:json_annotation/json_annotation.dart';

import 'media.dart';

part 'entities.g.dart';

@JsonSerializable()
@json
class Entities {
  Entities();

  factory Entities.fromJson(Map<String, dynamic> json) =>
      _$EntitiesFromJson(json);

  Map<String, dynamic> toJson() => _$EntitiesToJson(this);

  List<Hashtag>? hashtags;

  List<Media>? media;

  List<Url>? urls;

  List<UserMention>? user_mentions;

  List<Symbol>? symbols;

  List<Poll>? polls;
}

@JsonSerializable()
@json
class Hashtag {
  Hashtag();

  factory Hashtag.fromJson(Map<String, dynamic> json) =>
      _$HashtagFromJson(json);

  Map<String, dynamic> toJson() => _$HashtagToJson(this);

  List<int>? indices;

  String? text;
}

@JsonSerializable()
@json
class Poll {
  Poll();

  factory Poll.fromJson(Map<String, dynamic> json) => _$PollFromJson(json);

  Map<String, dynamic> toJson() => _$PollToJson(this);

  List<Option>? options;

  String? end_datetime;

  String? duration_minutes;
}

@JsonSerializable()
@json
class Option {
  Option();

  factory Option.fromJson(Map<String, dynamic> json) => _$OptionFromJson(json);

  Map<String, dynamic> toJson() => _$OptionToJson(this);

  int? position;

  String? text;
}

@JsonSerializable()
@json
class Symbol {
  Symbol();

  factory Symbol.fromJson(Map<String, dynamic> json) => _$SymbolFromJson(json);

  Map<String, dynamic> toJson() => _$SymbolToJson(this);

  List<int>? indices;

  String? text;
}

@JsonSerializable()
@json
class Url {
  Url();

  factory Url.fromJson(Map<String, dynamic> json) => _$UrlFromJson(json);

  Map<String, dynamic> toJson() => _$UrlToJson(this);

  String? display_url;

  String? expanded_url;

  List<int>? indices;

  String? url;
}

@JsonSerializable()
@json
class UserMention {
  UserMention();

  factory UserMention.fromJson(Map<String, dynamic> json) =>
      _$UserMentionFromJson(json);

  Map<String, dynamic> toJson() => _$UserMentionToJson(this);

  String? id_str;

  List<int>? indices;

  String? name;

  String? screen_name;
}
