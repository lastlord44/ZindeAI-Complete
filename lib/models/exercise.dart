class ExerciseMetadata {
  final String exerciseId;
  final String source;
  final bool available;
  final Map<String, String> mediaUrls;
  final String? preferredFormat;
  final Map<String, dynamic>? dimensions;
  final String? thumbnail;

  ExerciseMetadata({
    required this.exerciseId,
    required this.source,
    required this.available,
    required this.mediaUrls,
    this.preferredFormat,
    this.dimensions,
    this.thumbnail,
  });

  factory ExerciseMetadata.fromJson(Map<String, dynamic> json) {
    return ExerciseMetadata(
      exerciseId: json['exerciseId'] ?? '',
      source: json['source'] ?? 'unknown',
      available: json['available'] ?? false,
      mediaUrls: Map<String, String>.from(json['mediaUrls'] ?? {}),
      preferredFormat: json['preferredFormat'],
      dimensions: json['dimensions'],
      thumbnail: json['thumbnail'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'exerciseId': exerciseId,
      'source': source,
      'available': available,
      'mediaUrls': mediaUrls,
      'preferredFormat': preferredFormat,
      'dimensions': dimensions,
      'thumbnail': thumbnail,
    };
  }
}

class BatchCheckResult {
  final List<ExerciseCheck> results;

  BatchCheckResult({required this.results});

  factory BatchCheckResult.fromJson(Map<String, dynamic> json) {
    return BatchCheckResult(
      results: (json['results'] as List?)
              ?.map((item) => ExerciseCheck.fromJson(item))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'results': results.map((item) => item.toJson()).toList(),
    };
  }
}

class ExerciseCheck {
  final String exerciseId;
  final bool exists;
  final String? url;
  final String? format;

  ExerciseCheck({
    required this.exerciseId,
    required this.exists,
    this.url,
    this.format,
  });

  factory ExerciseCheck.fromJson(Map<String, dynamic> json) {
    return ExerciseCheck(
      exerciseId: json['exerciseId'] ?? '',
      exists: json['exists'] ?? false,
      url: json['url'],
      format: json['format'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'exerciseId': exerciseId,
      'exists': exists,
      'url': url,
      'format': format,
    };
  }
}
