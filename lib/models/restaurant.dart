class Restaurant {
  final String id;
  final String name;
  final String cuisines;
  final String description;
  final String address;
  final double rating;
  final String time;
  final String price;
  final String dist;
  final String offer;
  final bool veg;
  final String photoKey;
  final bool isOpen;
  final List<String> galleryPhotoKeys;
  final String? videoThumbnailKey;
  final String? videoDuration;
  final int maxGuests;

  const Restaurant({
    required this.id,
    required this.name,
    required this.cuisines,
    this.description = '',
    this.address = '',
    required this.rating,
    required this.time,
    required this.price,
    required this.dist,
    required this.offer,
    required this.veg,
    required this.photoKey,
    this.isOpen = true,
    this.galleryPhotoKeys = const [],
    this.videoThumbnailKey,
    this.videoDuration,
    this.maxGuests = 20,
  });

  Restaurant copyWith({
    String? id,
    String? name,
    String? cuisines,
    String? description,
    String? address,
    double? rating,
    String? time,
    String? price,
    String? dist,
    String? offer,
    bool? veg,
    String? photoKey,
    bool? isOpen,
    List<String>? galleryPhotoKeys,
    String? videoThumbnailKey,
    String? videoDuration,
    int? maxGuests,
  }) {
    return Restaurant(
      id: id ?? this.id,
      name: name ?? this.name,
      cuisines: cuisines ?? this.cuisines,
      description: description ?? this.description,
      address: address ?? this.address,
      rating: rating ?? this.rating,
      time: time ?? this.time,
      price: price ?? this.price,
      dist: dist ?? this.dist,
      offer: offer ?? this.offer,
      veg: veg ?? this.veg,
      photoKey: photoKey ?? this.photoKey,
      isOpen: isOpen ?? this.isOpen,
      galleryPhotoKeys: galleryPhotoKeys ?? this.galleryPhotoKeys,
      videoThumbnailKey: videoThumbnailKey ?? this.videoThumbnailKey,
      videoDuration: videoDuration ?? this.videoDuration,
      maxGuests: maxGuests ?? this.maxGuests,
    );
  }

  /// Combined photo/video carousel: cover photo, then video (if any), then gallery photos.
  List<GalleryMedia> get gallery => [
    GalleryMedia(photoKey: photoKey),
    if (videoThumbnailKey != null)
      GalleryMedia(
        photoKey: videoThumbnailKey!,
        isVideo: true,
        duration: videoDuration ?? '0:15',
      ),
    ...galleryPhotoKeys.map((k) => GalleryMedia(photoKey: k)),
  ];
}

/// A single item in a restaurant's photo/video gallery carousel.
class GalleryMedia {
  final String photoKey;
  final bool isVideo;
  final String? duration;
  const GalleryMedia({
    required this.photoKey,
    this.isVideo = false,
    this.duration,
  });
}
