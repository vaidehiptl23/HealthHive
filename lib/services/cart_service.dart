class DocumentCartService {
  static final DocumentCartService _instance = DocumentCartService._internal();

  factory DocumentCartService() {
    return _instance;
  }

  DocumentCartService._internal();

  final List<Map<String, dynamic>> _cart = [];

  List<Map<String, dynamic>> get cart => _cart;

  void addToCart(Map<String, dynamic> doc) {
    if (!_cart.any((item) => item['id'] == doc['id'])) {
      _cart.add(doc);
    }
  }

  void removeFromCart(int id) {
    _cart.removeWhere((item) => item['id'] == id);
  }

  void clearCart() {
    _cart.clear();
  }

  bool isInCart(int id) {
    return _cart.any((item) => item['id'] == id);
  }
}
