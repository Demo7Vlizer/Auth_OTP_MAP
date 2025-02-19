class GalleryImage {
  final String url;
  final DateTime uploadedAt;
  final String id;

  GalleryImage({
    required this.url,
    required this.uploadedAt,
    required this.id,
  });

  Map<String, dynamic> toJson() => {
    'url': url,
    'uploadedAt': uploadedAt.toIso8601String(),
    'id': id,
  };

  factory GalleryImage.fromJson(Map<String, dynamic> json) => GalleryImage(
    url: json['url'],
    uploadedAt: DateTime.parse(json['uploadedAt']),
    id: json['id'],
  );
} 