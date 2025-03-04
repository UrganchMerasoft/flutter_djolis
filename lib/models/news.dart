class NewsModel {
  static const String tableName = "news";

  late int id;
  late String caption;
  late String picUrl;
  late int darkCaption;

  NewsModel({required this.id, required this.caption, required this.picUrl, required this.darkCaption});

  factory NewsModel.fromJson(Map<String, dynamic> json) {
    return NewsModel(
      id: json['id'],
      caption: json['caption'],
      picUrl: json['picUrl'],
      darkCaption: json['darkCaption'],
    );
  }

  Map<String, dynamic> toMap() {
    var map = <String, dynamic>{};
    map['id'] = id;
    map['caption'] = caption;
    map['picUrl'] = picUrl;
    map['darkCaption'] = darkCaption;
    return map;
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "caption": caption,
      "picUrl": picUrl,
      "darkCaption": darkCaption,
    };
  }

  NewsModel.fromMapObject(Map<String, dynamic> map) {
    id = map['id'];
    caption = map['caption'] ?? "";
    picUrl = map['picUrl'] ?? "";
    darkCaption = map['darkCaption'] ?? 0;
  }
}
