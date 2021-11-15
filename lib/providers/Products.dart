// ignore_for_file: file_names

import 'dart:convert';
import 'dart:core';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/http_exception.dart';
import 'auth.dart';
import 'product.dart';

class Products with ChangeNotifier {
  final List<Product> _items = [];
  String? token;
  String? userId;

  List<Product> get items {
    return [..._items];
  }

  void update(Auth auth) {
    token = auth.token;
    userId = auth.userId;
  }

  List<Product> get favoriteItems {
    return _items.where((element) => element.isFavorite).toList();
  }

  Product findById(String id) {
    return _items.firstWhere((element) => element.id == id);
  }

  Future<void> getAllProducts([bool filterByUser = false]) async {
    final filterString =
        filterByUser ? '&orderBy="creatorId"&equalTo="$userId"' : '';

    final url = Uri.parse(
        'https://myshop-flutter-ms0713-default-rtdb.asia-southeast1.firebasedatabase.app/products.json?auth=$token$filterString');

    final urlForUser = Uri.parse(
        'https://myshop-flutter-ms0713-default-rtdb.asia-southeast1.firebasedatabase.app/userFavorites/$userId.json?auth=$token');
    try {
      final response = await http.get(url);
      if (response.body.isEmpty) {
        return;
      }

      final userResponse = await http.get(urlForUser);
      final userData = json.decode(userResponse.body) as Map<String, dynamic>;
      
      final data = json.decode(response.body) as Map<String, dynamic>;
      _items.clear();
      
      data.forEach((productId, productData) {
        _items.add(Product(
          id: productId,
          title: productData['title'],
          description: productData['description'],
          price: productData['price'],
          imageUrl: productData['imageUrl'],
          isFavorite: userData == null ? false : userData[productId] ?? false,
        ));
      });
      notifyListeners();
    } catch (e) {
      throw e.toString();
    }
  }

  Future<void> addProduct(Product prod) async {
    final url = Uri.parse(
        'https://myshop-flutter-ms0713-default-rtdb.asia-southeast1.firebasedatabase.app/products.json?auth=$token');

    try {
      final response = await http.post(
        url,
        body: json.encode({
          'title': prod.title,
          'description': prod.description,
          'imageUrl': prod.imageUrl,
          'price': prod.price,
          'creatorId': userId,
        }),
      );
      final newProduct = Product(
        id: json.decode(response.body)['name'],
        title: prod.title,
        description: prod.description,
        price: prod.price,
        imageUrl: prod.imageUrl,
      );
      _items.add(newProduct);
      notifyListeners();
    } on Exception catch (e) {
      throw e.toString();
    }
  }

  Future<void> updateProduct(Product prod) async {
    final productIndex = _items.indexWhere((element) => element.id == prod.id);
    if (productIndex >= 0) {
      final url = Uri.parse(
          'https://myshop-flutter-ms0713-default-rtdb.asia-southeast1.firebasedatabase.app/products/${prod.id}.json?auth=$token');

      await http.patch(
        url,
        body: json.encode({
          'title': prod.title,
          'description': prod.description,
          'imageUrl': prod.imageUrl,
          'price': prod.price,
          'isFavorite': prod.isFavorite,
        }),
      );

      _items[productIndex] = prod;
      notifyListeners();
    } else {
      // Log error here
      print('...update failed');
    }
  }

  Future<void> deleteProduct(String id) async {
    final url = Uri.parse(
        'https://myshop-flutter-ms0713-default-rtdb.asia-southeast1.firebasedatabase.app/products/$id.json?auth=$token');

    final existingProductIndex =
        _items.indexWhere((element) => element.id == id);
    Product? existingProduct = _items[existingProductIndex];

    _items.removeAt(existingProductIndex);
    notifyListeners();

    final response = await http.delete(url);

    if (response.statusCode >= 400) {
      _items.insert(existingProductIndex, existingProduct);
      notifyListeners();
      throw HttpException('Could not delete product.');
    }
    existingProduct = null;
  }
}
