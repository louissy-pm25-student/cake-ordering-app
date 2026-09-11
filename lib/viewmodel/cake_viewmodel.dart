import 'package:flutter/foundation.dart';

import '../model/local_account.dart';

import '../data/cake_repository.dart';
import 'admin/admin_viewmodel.dart';
import '../model/admin/admin_record.dart';
import '../model/cake.dart';
import '../model/cart_item.dart';
import '../model/cake_order.dart';
import '../model/user_profile.dart';
import '../model/cake_customization.dart';
import '../nav/cake_destination.dart';
import '../nav/cake_navigation.dart';

class CakeViewModel extends ChangeNotifier {
  final CakeRepository repository;
  CakeViewModel(this.repository) {
    admin = AdminViewModel(_persistAdmin);
    admin.load({});
    admin.addListener(notifyListeners);
  }
  late final AdminViewModel admin;
  Future<bool> _persistAdmin(Map<String, dynamic> data) {
    final newCustomerOrder = (data['orders'] as List? ?? []).any(
      (o) =>
          o['source'] == 'online' &&
          o['email'] == email &&
          email.isNotEmpty &&
          admin.record('orders', '${o['id']}') == null,
    );
    return _persist({
      ..._snapshot(cart: newCustomerOrder ? [] : null),
      'admin': data,
    });
  }

  String fulfilment = 'pickup', zone = '', orderNotes = '';
  String fulfilmentDate = dayKey(DateTime.now());
  bool get isAdmin => admin.signedIn;
  void exitAdmin() {
    admin.logout();
    _destination = CakeDestination.home;
    notifyListeners();
  }

  void setFulfilment(String value) {
    fulfilment = value;
    notifyListeners();
  }

  void setZone(String value) {
    zone = value;
    notifyListeners();
  }

  void setOrderDate(String value) {
    fulfilmentDate = value;
    notifyListeners();
  }

  double get deliveryFee => admin.feeFor(fulfilment, zone);
  List<AdminRecord> get customerNotifications => admin
      .records('notifications')
      .where((r) => r.text('email') == email && email.isNotEmpty)
      .toList();
  @override
  void dispose() {
    admin.removeListener(notifyListeners);
    admin.dispose();
    super.dispose();
  }

  final List<LocalAccount> _accounts = [];
  final Map<String, dynamic> _userData = {};
  LocalAccount? _account;
  CakeDestination? _pendingPage;
  Cake? _pendingCake;
  CakeDestination _guestPage = CakeDestination.home;
  String? authError;
  bool get isLoggedIn => _account != null;
  String get email => _account?.email ?? '';
  CakeDestination _destination = CakeDestination.home;
  List<CartItem> _cart = [];
  List<CakeOrder> _orders = [];
  UserProfile _profile = const UserProfile();
  CakeCustomization _custom = const CakeCustomization();
  String _query = '', _category = 'All', _payment = 'cash', _promo = '';
  String? error;
  bool _promoApplied = false, _promoError = false, busy = false;
  Future<void> _writes = Future.value();
  CakeDestination get destination => _destination;
  List<CartItem> get cart => List.unmodifiable(_cart);
  List<CakeOrder> get orders => admin
      .records('orders')
      .where((r) => email.isNotEmpty && r.text('email') == email)
      .map((r) => CakeOrder.fromJson(r.toJson()))
      .toList();
  UserProfile get profile => _profile;
  CakeCustomization get custom => _custom;
  String get query => _query;
  String get category => _category;
  String get payment => _payment;
  String get promo => _promo;
  bool get promoApplied => _promoApplied;
  bool get promoError => _promoError;
  List<Cake> get cakes => admin
      .records('products')
      .map(
        (r) => Cake(
          r.text('name'),
          r.number('price'),
          0,
          r.text('category'),
          r.text('description'),
          id: r.id,
          photoData: r.text('photoData'),
          available: r.flag('available'),
        ),
      )
      .toList();
  List<Cake> get filteredCakes => cakes
      .where(
        (c) =>
            (_category == 'All' || c.category == _category) &&
            '${c.name} ${c.note}'.toLowerCase().contains(_query.toLowerCase()),
      )
      .toList();
  int get cartCount => _cart.fold(0, (sum, item) => sum + item.quantity);
  double get subtotal =>
      _cart.fold(0.0, (sum, item) => sum + item.price * item.quantity);
  double get discount =>
      _promoApplied ? admin.discountFor(_promo, subtotal, email) : 0;
  double get total =>
      double.parse((subtotal - discount + deliveryFee).toStringAsFixed(2));
  bool get canPlaceOrder =>
      isLoggedIn &&
      _cart.isNotEmpty &&
      _profile.address.trim().length >= 10 &&
      !busy &&
      !admin.busy;
  double get customPrice =>
      40 +
      (switch (_custom.size) {
        '8 inch' => 12,
        '10 inch' => 24,
        _ => 0,
      }) +
      (_custom.decoration == 'Flowers' ? 8 : 5) +
      (_custom.shape == 'Heart' ? 5 : 0.0);
  int get customPhoto => switch (_custom.flavor) {
    'Chocolate' => 1,
    'Red Velvet' => 3,
    _ => _custom.decoration == 'Flowers' ? 2 : 0,
  };
  Future<void> load() async {
    try {
      final data = await repository.load();
      _accounts.addAll(
        (data['accounts'] as List? ?? []).map(
          (e) => LocalAccount.fromJson(Map<String, dynamic>.from(e as Map)),
        ),
      );
      _userData.addAll(Map<String, dynamic>.from(data['users'] as Map? ?? {}));
      admin.load(Map<String, dynamic>.from(data['admin'] as Map? ?? {}));
      admin.importCustomers(_userData, _accounts);
    } catch (_) {
      error = 'Saved data could not be loaded.';
    }
    notifyListeners();
  }

  Map<String, dynamic> _snapshot({
    List<CartItem>? cart,
    List<CakeOrder>? orders,
  }) {
    final users = Map<String, dynamic>.from(_userData);
    if (_account != null) {
      users[email] = {
        'cart': (cart ?? _cart).map((e) => e.toJson()).toList(),
        'orders': (orders ?? _orders).map((e) => e.toJson()).toList(),
        'profile': _profile.toJson(),
      };
    }
    return {
      'admin': admin.toJson(),
      'accounts': _accounts.map((e) => e.toJson()).toList(),
      'users': users,
    };
  }

  bool _requireLogin(CakeDestination page, {Cake? cake}) {
    if (isLoggedIn) return true;
    if (_destination == CakeDestination.home ||
        _destination == CakeDestination.menu) {
      _guestPage = _destination;
    }
    _pendingPage = page;
    if (cake != null) _pendingCake = cake;
    _destination = CakeDestination.login;
    authError = null;
    notifyListeners();
    return false;
  }

  Future<void> authenticate({
    required String email,
    required String password,
    String? name,
  }) async {
    if (busy) return;
    final normalized = email.trim().toLowerCase();
    authError = null;
    if (name == null && admin.hasUsername(normalized)) {
      if (_account != null) {
        authError = 'Log out of your customer account first.';
        notifyListeners();
        return;
      }
      busy = true;
      notifyListeners();
      final ok = await admin.login(normalized, password);
      busy = false;
      if (ok) {
        _destination = CakeDestination.admin;
        _pendingCake = null;
        _pendingPage = null;
      } else {
        authError = 'Username or password is incorrect.';
      }
      notifyListeners();
      return;
    }
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(normalized)) {
      authError = 'Enter a valid email address.';
      notifyListeners();
      return;
    }
    if (name != null && (name.trim().isEmpty || password.length < 8)) {
      authError = 'Enter your name and a password of at least 8 characters.';
      notifyListeners();
      return;
    }
    busy = true;
    notifyListeners();
    try {
      LocalAccount? account;
      for (final candidate in _accounts) {
        if (candidate.email == normalized) account = candidate;
      }
      if (name != null) {
        if (account != null) {
          authError = 'This email is already registered. Please log in.';
          return;
        }
        account = await LocalAccount.create(name.trim(), normalized, password);
        _accounts.add(account);
        if (!await _persist(_snapshot())) {
          _accounts.remove(account);
          authError = 'Registration could not be saved. Please retry.';
          return;
        }
      } else if (account == null || !await account.verify(password)) {
        authError = 'Email or password is incorrect.';
        return;
      }
      _account = account;
      final data = Map<String, dynamic>.from(
        _userData[normalized] as Map? ?? {},
      );
      _cart = (data['cart'] as List? ?? [])
          .map((e) => CartItem.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      _orders = (data['orders'] as List? ?? [])
          .map((e) => CakeOrder.fromJson(Map<String, dynamic>.from(e as Map)))
          .where((e) => e.items.isNotEmpty)
          .toList();
      _profile = data['profile'] == null
          ? UserProfile(name: account.name)
          : UserProfile.fromJson(
              Map<String, dynamic>.from(data['profile'] as Map),
            );
      final directory = admin
          .records('customers')
          .where((r) => r.text('email') == normalized)
          .firstOrNull;
      if (directory != null) {
        _profile = UserProfile(
          name: directory.text('name'),
          address: directory.text('address'),
          phone: directory.text('phone'),
        );
      }
      await admin.syncCustomer(
        normalized,
        _profile.name,
        _profile.address,
        _profile.phone,
      );
      final cake = _pendingCake;
      final next = _pendingPage ?? CakeDestination.home;
      _pendingCake = null;
      _pendingPage = null;
      busy = false;
      if (cake != null) addCake(cake);
      _destination = next;
    } catch (_) {
      authError = 'Unable to log in. Please try again.';
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  void cancelLogin() {
    if (busy) return;
    _pendingCake = null;
    _pendingPage = null;
    authError = null;
    _destination = _guestPage;
    notifyListeners();
  }

  Future<void> logout() async {
    if (busy) return;
    busy = true;
    notifyListeners();
    final snapshot = _snapshot();
    if (await _persist(snapshot)) {
      _userData.clear();
      _userData.addAll(Map<String, dynamic>.from(snapshot['users'] as Map));
      _account = null;
      _cart = [];
      _orders = [];
      _profile = const UserProfile();
      _custom = const CakeCustomization();
      _promo = '';
      _promoApplied = false;
      _promoError = false;
      _pendingCake = null;
      _pendingPage = null;
      _destination = CakeDestination.home;
    }
    busy = false;
    notifyListeners();
  }

  Future<bool> _persist(Map<String, dynamic> data) {
    final operation = _writes.then((_) => repository.save(data));
    _writes = operation.catchError((Object _) {});
    return operation.then((_) => true).catchError((Object _) {
      error = 'Could not save changes. Please try again.';
      notifyListeners();
      return false;
    });
  }

  void navigate(CakeDestination page) {
    if (busy) return;
    if (page == CakeDestination.admin && !isAdmin) {
      _destination = CakeDestination.login;
      notifyListeners();
      return;
    }
    if (CakeNavigation.requiresLogin(page) && !_requireLogin(page)) return;
    if (page == CakeDestination.home || page == CakeDestination.menu) {
      _pendingCake = null;
      _pendingPage = null;
    }
    authError = null;
    _destination = page;
    notifyListeners();
  }

  void goBack() {
    if (_destination == CakeDestination.login ||
        _destination == CakeDestination.register) {
      cancelLogin();
      return;
    }
    final page = CakeNavigation.backDestination(_destination);
    if (page != null) navigate(page);
  }

  void setQuery(String value) {
    _query = value;
    notifyListeners();
  }

  void setCategory(String value) {
    _category = value;
    notifyListeners();
  }

  void setPhone(String value) {
    _profile = _profile.copyWith(phone: value);
  }

  void setName(String value) {
    _profile = _profile.copyWith(name: value);
  }

  void setAddress(String value) {
    _profile = _profile.copyWith(address: value);
    notifyListeners();
  }

  void setCustom(CakeCustomization value) {
    _custom = value;
    notifyListeners();
  }

  void setPayment(String value) {
    _payment = value;
    notifyListeners();
  }

  void setPromo(String value) {
    _promo = value;
    _promoApplied = false;
    _promoError = false;
    notifyListeners();
  }

  void applyPromo() {
    _promoApplied = admin.discountFor(_promo, subtotal, email) > 0;
    _promoError = !_promoApplied;
    notifyListeners();
  }

  void dismissError() {
    error = null;
    notifyListeners();
  }

  void addCake(Cake cake, {String variantId = ''}) {
    if (busy) return;
    if (!_requireLogin(CakeDestination.checkout, cake: cake)) return;
    final product = admin.record('products', cake.id);
    if (product == null || !product.flag('available')) {
      error = 'This cake is currently unavailable.';
      notifyListeners();
      return;
    }
    final variant = variantId.isEmpty
        ? null
        : admin.record('variants', variantId);
    if (variantId.isNotEmpty && variant?.text('product') != cake.id) {
      error = 'Invalid cake option.';
      notifyListeners();
      return;
    }
    final price =
        product.number('price') + (variant?.number('adjustment') ?? 0);
    if (price < 0) {
      error = 'This option has an invalid price.';
      notifyListeners();
      return;
    }
    final id = variantId.isEmpty ? cake.id : '${cake.id}:$variantId';
    final index = _cart.indexWhere((e) => e.id == id);
    if (index < 0) {
      _cart.add(
        CartItem(
          id: id,
          name: cake.name,
          price: price,
          photo: cake.photo,
          details: variant == null
              ? 'Standard cake'
              : '${variant.text('size')} · ${variant.text('flavor')} · ${variant.text('filling')}',
          productId: cake.id,
          variantId: variantId,
          photoData: cake.photoData,
        ),
      );
    } else {
      _cart[index] = _cart[index].withQuantity(_cart[index].quantity + 1);
    }
    _persist(_snapshot());
    notifyListeners();
  }

  void changeQuantity(String id, int delta) {
    if (!_requireLogin(CakeDestination.checkout)) return;
    if (busy) return;
    _cart = _cart
        .map((e) => e.id == id ? e.withQuantity(e.quantity + delta) : e)
        .where((e) => e.quantity > 0)
        .toList();
    _persist(_snapshot());
    notifyListeners();
  }

  void addCustomCake() {
    if (!_requireLogin(CakeDestination.customize)) return;
    if (busy) return;
    _cart.add(
      CartItem(
        id: 'custom-${DateTime.now().microsecondsSinceEpoch}',
        name: 'Custom Celebration Cake',
        price: customPrice,
        photo: customPhoto,
        details:
            '${_custom.size} · ${_custom.shape} · ${_custom.flavor}\n${_custom.decoration}${_custom.message.isEmpty ? '' : '\nMessage: ${_custom.message}'}',
      ),
    );
    _persist(_snapshot());
    navigate(CakeDestination.checkout);
  }

  Future<bool> saveProfile() async {
    if (!_requireLogin(CakeDestination.profile)) return false;
    _profile = UserProfile(
      name: _profile.name.trim(),
      address: _profile.address.trim(),
      phone: _profile.phone.trim(),
    );
    final ok = await _persist(_snapshot());
    if (ok) {
      await admin.syncCustomer(
        email,
        _profile.name,
        _profile.address,
        _profile.phone,
      );
    }
    notifyListeners();
    return ok;
  }

  Future<void> placeOrder() async {
    if (!canPlaceOrder) return;
    busy = true;
    error = null;
    notifyListeners();
    final ok = await admin.customerOrder({
      'phone': _profile.phone,
      'customer': _profile.name,
      'email': email,
      'address': _profile.address,
      'payment': _payment,
      'date': fulfilmentDate,
      'slot': '',
      'fulfilment': fulfilment,
      'zone': zone,
      'notes': orderNotes,
      'code': _promoApplied ? _promo : '',
      'items': _cart
          .map(
            (item) => {
              ...item.toJson(),
              'product': item.productId.isEmpty ? item.id : item.productId,
            },
          )
          .toList(),
    });
    if (ok) {
      _cart = [];
      _orders = orders;
      _promo = '';
      _promoApplied = false;
      _promoError = false;
      _destination = CakeDestination.orders;
      await _persist(_snapshot());
    } else {
      error = admin.error;
    }
    busy = false;
    notifyListeners();
  }
}
