import 'dart:io';
import 'dart:convert';
import 'package:crypto/crypto.dart';

/// CacheLayer: Memory cache for JSON files with hash-based invalidation.
class CacheLayer {
  final Map<String, _CacheEntry> _cache = {};

  /// Reads a JSON file from cache or disk.
  /// Automatically invalidates cache if the file's hash changes.
  Future<Map<String, dynamic>> readJson(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) throw Exception('File not found: $filePath');

    final bytes = await file.readAsBytes();
    final currentHash = sha256.convert(bytes).toString();

    final cached = _cache[filePath];
    if (cached != null && cached.hash == currentHash) {
      return cached.data;
    }

    // Cache miss or invalidation
    final content = utf8.decode(bytes);
    final data = jsonDecode(content);
    _cache[filePath] = _CacheEntry(hash: currentHash, data: data);
    
    return data;
  }
}

class _CacheEntry {
  final String hash;
  final Map<String, dynamic> data;
  _CacheEntry({required this.hash, required this.data});
}
