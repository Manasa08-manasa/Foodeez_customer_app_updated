class Restaurant {
  final String id;
  final String name;
  final String cuisines;
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

  const Restaurant({
    required this.id,
    required this.name,
    required this.cuisines,
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
  });

  /// Combined photo/video carousel: cover photo, then video (if any), then gallery photos.
  List<GalleryMedia> get gallery => [
        GalleryMedia(photoKey: photoKey),
        if (videoThumbnailKey != null)
          GalleryMedia(photoKey: videoThumbnailKey!, isVideo: true, duration: videoDuration ?? '0:15'),
        ...galleryPhotoKeys.map((k) => GalleryMedia(photoKey: k)),
      ];
}

/// A single item in a restaurant's photo/video gallery carousel.
class GalleryMedia {
  final String photoKey;
  final bool isVideo;
  final String? duration;
  const GalleryMedia({required this.photoKey, this.isVideo = false, this.duration});
}
