import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:befit_fitness_app/src/food_scanner/domain/models/food_product.dart';

/// Data source for fetching food product information from Open Food Facts API
class FoodApiDataSource {
  final Dio _dio;
  static const String _baseUrl = 'https://world.openfoodfacts.org/api/v2';

  FoodApiDataSource({Dio? dio}) : _dio = dio ?? Dio();

  /// Fetch product information by barcode
  Future<FoodProduct?> getProductByBarcode(String barcode) async {
    try {
      final response = await _dio.get(
        '$_baseUrl/product/$barcode.json',
        options: Options(
          headers: {
            'User-Agent': 'BeFit Fitness App - Android - Version 1.0',
          },
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        if (response.data['status'] == 1) {
          // Product found
          return FoodProduct.fromJson(response.data);
        } else {
          // Product not found
          return null;
        }
      }
      return null;
    } catch (e) {
      throw Exception('Failed to fetch product: $e');
    }
  }

  /// Search products by name
  Future<List<FoodProduct>> searchProducts(String query) async {
    try {
      final response = await _dio.get(
        '$_baseUrl/cgi/search.pl',
        queryParameters: {
          'search_terms': query,
          'search_simple': 1,
          'action': 'process',
          'json': 1,
          'page_size': 20,
        },
        options: Options(
          headers: {
            'User-Agent': 'BeFit Fitness App - Android - Version 1.0',
          },
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        final products = response.data['products'] as List?;
        if (products != null) {
          return products
              .map((p) => FoodProduct.fromJson({'product': p, 'code': p['code']}))
              .where((p) => p.name != 'Unknown Product')
              .toList();
        }
      }
      return [];
    } catch (e) {
      throw Exception('Failed to search products: $e');
    }
  }
}

