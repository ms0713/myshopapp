import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'auth.dart';
import 'cart.dart';

class OrderItem {
  final String id;
  final double amount;
  final List<CartItem> products;
  final DateTime dateTime;

  OrderItem(
      {required this.id,
      required this.amount,
      required this.products,
      required this.dateTime});
}

class Orders with ChangeNotifier {
  List<OrderItem> _orders = [];
  String? token;
  String? userId;

  List<OrderItem> get orders {
    return [..._orders];
  }

  void update(Auth auth){
    token = auth.token;
    userId = auth.userId;
  }
  
  Future<void> getAllOrders() async {
    final url = Uri.parse(
        'https://myshop-flutter-ms0713-default-rtdb.asia-southeast1.firebasedatabase.app/orders/$userId.json?auth=$token');

    final response = await http.get(url);
    List<OrderItem> loadedOrders = [];
    if (response.body.isEmpty) {
      return;
    }
    final data = json.decode(response.body) as Map<String, dynamic>;
    data.forEach((orderId, orderData) {
      loadedOrders.add(
        OrderItem(
          id: orderId,
          amount: orderData['amount'],
          dateTime: DateTime.parse(orderData['dateTime']),
          products: (orderData['products'] as List<dynamic>)
              .map(
                (item) => CartItem(
                  id: item['id'],
                  title: item['title'],
                  quantity: item['quantity'],
                  price: item['price'],
                ),
              )
              .toList(),
        ),
      );
    });

    _orders = loadedOrders.reversed.toList();
    notifyListeners();
  }

  Future<void> addOrder(List<CartItem> cartProdcuts, double total) async {
    final url = Uri.parse(
        'https://myshop-flutter-ms0713-default-rtdb.asia-southeast1.firebasedatabase.app/orders/$userId.json?auth=$token');

    final timestamp = DateTime.now();
    final response = await http.post(url,
        body: json.encode({
          'amount': total,
          'dateTime': timestamp.toIso8601String(),
          'products': cartProdcuts
              .map((cp) => {
                    'id': cp.id,
                    'title': cp.title,
                    'quantity': cp.quantity,
                    'price': cp.price,
                  })
              .toList(),
        }));

    _orders.insert(
        0,
        OrderItem(
            id: json.decode(response.body)['name'],
            amount: total,
            products: cartProdcuts,
            dateTime: timestamp));

    notifyListeners();
  }
}
