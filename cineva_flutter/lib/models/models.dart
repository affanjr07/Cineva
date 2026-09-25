class Movie {
  final String id;
  final String title;
  final String type;
  final String posterImg;
  final String rating;
  final String url;
  final String qualityResolution;
  final List<String> genres;

  const Movie({
    required this.id,
    required this.title,
    required this.type,
    required this.posterImg,
    required this.rating,
    required this.url,
    required this.qualityResolution,
    required this.genres,
  });

  factory Movie.fromJson(Map<String, dynamic> json) {
    return Movie(
      id: json['_id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      type: json['type'] as String? ?? 'movie',
      posterImg: json['posterImg'] as String? ?? '',
      rating: json['rating'] as String? ?? '0',
      url: json['url'] as String? ?? '',
      qualityResolution: json['qualityResolution'] as String? ?? '',
      genres: _stringList(json['genres']),
    );
  }
}

class MovieDetails {
  final String id;
  final String title;
  final String type;
  final String posterImg;
  final String rating;
  final String quality;
  final String releaseDate;
  final String synopsis;
  final String duration;
  final String trailerUrl;
  final List<String> directors;
  final List<String> countries;
  final List<String> casts;
  final List<String> genres;

  const MovieDetails({
    required this.id,
    required this.title,
    required this.type,
    required this.posterImg,
    required this.rating,
    required this.quality,
    required this.releaseDate,
    required this.synopsis,
    required this.duration,
    required this.trailerUrl,
    required this.directors,
    required this.countries,
    required this.casts,
    required this.genres,
  });

  factory MovieDetails.fromJson(Map<String, dynamic> json) {
    return MovieDetails(
      id: json['_id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      type: json['type'] as String? ?? 'movie',
      posterImg: json['posterImg'] as String? ?? '',
      rating: json['rating'] as String? ?? '0',
      quality: json['quality'] as String? ?? '',
      releaseDate: json['releaseDate'] as String? ?? '',
      synopsis: json['synopsis'] as String? ?? '',
      duration: json['duration'] as String? ?? '',
      trailerUrl: json['trailerUrl'] as String? ?? '',
      directors: _stringList(json['directors']),
      countries: _stringList(json['countries']),
      casts: _stringList(json['casts']),
      genres: _stringList(json['genres']),
    );
  }
}

class SeriesDetails {
  final String id;
  final String title;
  final String type;
  final String posterImg;
  final String rating;
  final String status;
  final String releaseDate;
  final String synopsis;
  final String duration;
  final String trailerUrl;
  final List<String> directors;
  final List<String> countries;
  final List<String> casts;
  final List<String> genres;
  final List<Season> seasons;

  const SeriesDetails({
    required this.id,
    required this.title,
    required this.type,
    required this.posterImg,
    required this.rating,
    required this.status,
    required this.releaseDate,
    required this.synopsis,
    required this.duration,
    required this.trailerUrl,
    required this.directors,
    required this.countries,
    required this.casts,
    required this.genres,
    required this.seasons,
  });

  factory SeriesDetails.fromJson(Map<String, dynamic> json) {
    return SeriesDetails(
      id: json['_id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      type: json['type'] as String? ?? 'series',
      posterImg: json['posterImg'] as String? ?? '',
      rating: json['rating'] as String? ?? '0',
      status: json['status'] as String? ?? '',
      releaseDate: json['releaseDate'] as String? ?? '',
      synopsis: json['synopsis'] as String? ?? '',
      duration: json['duration'] as String? ?? '',
      trailerUrl: json['trailerUrl'] as String? ?? '',
      directors: _stringList(json['directors']),
      countries: _stringList(json['countries']),
      casts: _stringList(json['casts']),
      genres: _stringList(json['genres']),
      seasons: _seasonList(json['seasons']),
    );
  }
}

class Season {
  final int season;
  final int totalEpisodes;

  const Season({required this.season, required this.totalEpisodes});

  factory Season.fromJson(Map<String, dynamic> json) {
    return Season(
      season: (json['season'] as num?)?.toInt() ?? 1,
      totalEpisodes: (json['totalEpisodes'] as num?)?.toInt() ?? 0,
    );
  }
}

class StreamSource {
  final String provider;
  final String url;
  final List<String> resolutions;

  const StreamSource({
    required this.provider,
    required this.url,
    required this.resolutions,
  });

  factory StreamSource.fromJson(Map<String, dynamic> json) {
    return StreamSource(
      provider: json['provider'] as String? ?? '',
      url: json['url'] as String? ?? '',
      resolutions: _stringList(json['resolutions']),
    );
  }
}

class DownloadLink {
  final String server;
  final String link;
  final String quality;

  const DownloadLink({
    required this.server,
    required this.link,
    required this.quality,
  });

  factory DownloadLink.fromJson(Map<String, dynamic> json) {
    return DownloadLink(
      server: json['server'] as String? ?? '',
      link: json['link'] as String? ?? '',
      quality: json['quality'] as String? ?? '',
    );
  }
}

class SearchResult {
  final String id;
  final String title;
  final String type;
  final String posterImg;
  final String url;
  final List<String> genres;
  final List<String> directors;
  final List<String> casts;

  const SearchResult({
    required this.id,
    required this.title,
    required this.type,
    required this.posterImg,
    required this.url,
    required this.genres,
    required this.directors,
    required this.casts,
  });

  factory SearchResult.fromJson(Map<String, dynamic> json) {
    return SearchResult(
      id: json['_id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      type: json['type'] as String? ?? 'movie',
      posterImg: json['posterImg'] as String? ?? '',
      url: json['url'] as String? ?? '',
      genres: _stringList(json['genres']),
      directors: _stringList(json['directors']),
      casts: _stringList(json['casts']),
    );
  }
}

class Genre {
  final String parameter;
  final String name;
  final int numberOfContents;
  final String url;

  const Genre({
    required this.parameter,
    required this.name,
    required this.numberOfContents,
    required this.url,
  });

  factory Genre.fromJson(Map<String, dynamic> json) {
    return Genre(
      parameter: json['parameter'] as String? ?? '',
      name: json['name'] as String? ?? '',
      numberOfContents: (json['numberOfContents'] as num?)?.toInt() ?? 0,
      url: json['url'] as String? ?? '',
    );
  }
}

class Country {
  final String parameter;
  final String name;
  final int numberOfContents;
  final String url;

  const Country({
    required this.parameter,
    required this.name,
    required this.numberOfContents,
    required this.url,
  });

  factory Country.fromJson(Map<String, dynamic> json) {
    return Country(
      parameter: json['parameter'] as String? ?? '',
      name: json['name'] as String? ?? '',
      numberOfContents: (json['numberOfContents'] as num?)?.toInt() ?? 0,
      url: json['url'] as String? ?? '',
    );
  }
}

class Year {
  final String parameter;
  final int numberOfContents;
  final String url;

  const Year({
    required this.parameter,
    required this.numberOfContents,
    required this.url,
  });

  factory Year.fromJson(Map<String, dynamic> json) {
    return Year(
      parameter: json['parameter'] as String? ?? '',
      numberOfContents: (json['numberOfContents'] as num?)?.toInt() ?? 0,
      url: json['url'] as String? ?? '',
    );
  }
}

List<String> _stringList(dynamic value) {
  if (value is List) {
    return value.whereType<String>().toList();
  }
  return const [];
}

List<Season> _seasonList(dynamic value) {
  if (value is List) {
    return value
        .whereType<Map<String, dynamic>>()
        .map(Season.fromJson)
        .toList();
  }
  return const [];
}