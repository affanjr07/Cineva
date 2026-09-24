import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/models.dart';

class ApiClient {
  ApiClient({String? baseUrl}) : baseUrl = baseUrl ?? _defaultBaseUrl();

  final String baseUrl;
  static const _timeout = Duration(seconds: 15);

  static String _defaultBaseUrl() {
    const fromEnv = String.fromEnvironment('API_URL');
    if (fromEnv.isNotEmpty) return fromEnv;
    return 'http://localhost:8080';
  }

  Future<dynamic> _get(String path,
      {Map<String, String>? queryParameters}) async {
    final uri = Uri.parse('$baseUrl$path').replace(
      queryParameters: queryParameters,
    );
    try {
      final res = await http.get(uri, headers: {
        'Content-Type': 'application/json',
      }).timeout(_timeout);
      final body = res.body.isEmpty ? 'null' : res.body;
      return jsonDecode(body);
    } catch (e) {
      debugPrint('API Error GET $path: $e');
      return null;
    }
  }
}

class MoviesApi {
  MoviesApi(this._client);

  final ApiClient _client;

  Future<List<Movie>> getMovies({int page = 0}) async {
    final data = await _client._get('/movies', queryParameters: {'page': '$page'});
    return _movieList(data);
  }

  Future<List<Movie>> getPopularMovies({int page = 0}) async {
    final data = await _client._get('/popular/movies',
        queryParameters: {'page': '$page'});
    return _movieList(data);
  }

  Future<List<Movie>> getRecentReleaseMovies({int page = 0}) async {
    final data = await _client._get('/recent-release/movies',
        queryParameters: {'page': '$page'});
    return _movieList(data);
  }

  Future<List<Movie>> getTopRatedMovies({int page = 0}) async {
    final data = await _client._get('/top-rated/movies',
        queryParameters: {'page': '$page'});
    return _movieList(data);
  }

  Future<MovieDetails> getMovieDetails(String id) async {
    final data = await _client._get('/movies/$id');
    if (data is! Map<String, dynamic>) return _emptyDetails();
    return MovieDetails.fromJson(data);
  }

  Future<List<StreamSource>> getMovieStreams(String id) async {
    final data = await _client._get('/movies/$id/streams');
    return _streamList(data);
  }

  Future<List<DownloadLink>> getMovieDownloads(String id) async {
    final data = await _client._get('/movies/$id/download');
    return _downloadList(data);
  }

  MovieDetails _emptyDetails() => const MovieDetails(
        id: '',
        title: '',
        type: 'movie',
        posterImg: '',
        rating: '',
        quality: '',
        releaseDate: '',
        synopsis: '',
        duration: '',
        trailerUrl: '',
        directors: [],
        countries: [],
        casts: [],
        genres: [],
      );
}

class SeriesApi {
  SeriesApi(this._client);

  final ApiClient _client;

  Future<List<Movie>> getSeries({int page = 0}) async {
    final data = await _client._get('/series', queryParameters: {'page': '$page'});
    return _movieList(data);
  }

  Future<List<Movie>> getPopularSeries({int page = 0}) async {
    final data = await _client._get('/popular/series',
        queryParameters: {'page': '$page'});
    return _movieList(data);
  }

  Future<List<Movie>> getRecentReleaseSeries({int page = 0}) async {
    final data = await _client._get('/recent-release/series',
        queryParameters: {'page': '$page'});
    return _movieList(data);
  }

  Future<List<Movie>> getTopRatedSeries({int page = 0}) async {
    final data = await _client._get('/top-rated/series',
        queryParameters: {'page': '$page'});
    return _movieList(data);
  }

  Future<SeriesDetails> getSeriesDetails(String id) async {
    final data = await _client._get('/series/$id');
    if (data is! Map<String, dynamic>) return _emptyDetails();
    return SeriesDetails.fromJson(data);
  }

  Future<List<StreamSource>> getSeriesStreams(String id,
      {int season = 1, int episode = 1}) async {
    final data = await _client._get('/series/$id/streams',
        queryParameters: {'season': '$season', 'episode': '$episode'});
    return _streamList(data);
  }

  Future<List<DownloadLink>> getSeriesDownloads(String id,
      {int season = 1, int episode = 1}) async {
    final data = await _client._get('/series/$id/downloads',
        queryParameters: {'season': '$season', 'episode': '$episode'});
    return _downloadList(data);
  }

  SeriesDetails _emptyDetails() => const SeriesDetails(
        id: '',
        title: '',
        type: 'series',
        posterImg: '',
        rating: '',
        status: '',
        releaseDate: '',
        synopsis: '',
        duration: '',
        trailerUrl: '',
        directors: [],
        countries: [],
        casts: [],
        genres: [],
        seasons: [],
      );
}

class SearchApi {
  SearchApi(this._client);

  final ApiClient _client;

  Future<List<SearchResult>> search(String title) async {
    if (title.trim().isEmpty) return const [];
    final data = await _client._get('/search/${Uri.encodeComponent(title.trim())}');
    if (data is! List) return const [];
    return data
        .whereType<Map<String, dynamic>>()
        .map(SearchResult.fromJson)
        .toList();
  }
}

class CatalogApi {
  CatalogApi(this._client);

  final ApiClient _client;

  Future<List<Genre>> getGenres() async {
    final data = await _client._get('/genres');
    if (data is! List) return const [];
    return data
        .whereType<Map<String, dynamic>>()
        .map(Genre.fromJson)
        .toList();
  }

  Future<List<Movie>> getMoviesByGenre(String genre, {int page = 0}) async {
    final data = await _client._get('/genres/$genre',
        queryParameters: {'page': '$page'});
    return _movieList(data);
  }

  Future<List<Country>> getCountries() async {
    final data = await _client._get('/countries');
    if (data is! List) return const [];
    return data
        .whereType<Map<String, dynamic>>()
        .map(Country.fromJson)
        .toList();
  }

  Future<List<Movie>> getMoviesByCountry(String country, {int page = 0}) async {
    final data = await _client._get('/countries/$country',
        queryParameters: {'page': '$page'});
    return _movieList(data);
  }

  Future<List<Year>> getYears() async {
    final data = await _client._get('/years');
    if (data is! List) return const [];
    return data
        .whereType<Map<String, dynamic>>()
        .map(Year.fromJson)
        .toList();
  }

  Future<List<Movie>> getMoviesByYear(String year, {int page = 0}) async {
    final data = await _client._get('/years/$year',
        queryParameters: {'page': '$page'});
    return _movieList(data);
  }
}

List<Movie> _movieList(dynamic data) {
  if (data is! List) return const [];
  return data
      .whereType<Map<String, dynamic>>()
      .map(Movie.fromJson)
      .toList();
}

List<StreamSource> _streamList(dynamic data) {
  if (data is! List) return const [];
  return data
      .whereType<Map<String, dynamic>>()
      .map(StreamSource.fromJson)
      .toList();
}

List<DownloadLink> _downloadList(dynamic data) {
  if (data is! List) return const [];
  return data
      .whereType<Map<String, dynamic>>()
      .map(DownloadLink.fromJson)
      .toList();
}