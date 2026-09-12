import 'package:flutter/foundation.dart';

import '../model/local_account.dart';
import '../model/auth_verification.dart';

import '../data/cake_repository.dart';
import '../data/verification_service.dart';
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
  CakeViewModel(this.repository, {VerificationService? verificationService})
    : verificationService =
          verificationService ?? VerificationService.configured() {
    admin = AdminViewModel(_persistAdmin);
    admin.load({});
    admin.addListener(notifyListeners);
  }
  late final AdminViewModel admin;
  final VerificationService verificationService;
  Future<bool> _persistAdmin(Map<String, dynamic> data) async {
    final newCustomerOrder = (data['orders'] as List? ?? []).any(
      (o) =>
          o['source'] == 'online' &&
          o['email'] == email &&
          email.isNotEmpty &&
          admin.record('orders', '${o['id']}') == null,
    );
    final previousEmails = admin
        .records('customers')
        .map((customer) => customer.text('email').trim().toLowerCase())
        .where((email) => email.isNotEmpty)
        .toSet();
    final remainingEmails = (data['customers'] as List? ?? [])
        .map((customer) => Map<String, dynamic>.from(customer as Map))
        .where((customer) => customer['deleted'] != true)
        .map((customer) => '${customer['email'] ?? ''}'.trim().toLowerCase())
        .where((email) => email.isNotEmpty)
        .toSet();
    final removedEmails = previousEmails.difference(remainingEmails);
    final oldAccounts = List<LocalAccount>.from(_accounts);
    final oldUserData = Map<String, dynamic>.from(_userData);
    if (removedEmails.isNotEmpty) {
      _accounts.removeWhere((account) => removedEmails.contains(account.email));
      for (final removedEmail in removedEmails) {
        _userData.remove(removedEmail);
      }
    }
    final saved = await _persist({
      ..._snapshot(cart: newCustomerOrder ? [] : null),
      'admin': data,
    }, requireRemote: removedEmails.isNotEmpty);
    if (!saved && removedEmails.isNotEmpty) {
      _accounts
        ..clear()
        ..addAll(oldAccounts);
      _userData
        ..clear()
        ..addAll(oldUserData);
    }
    return saved;
  }

  String fulfilment = 'pickup', zone = '', orderNotes = '';
  String fulfilmentDate = dayKey(DateTime.now());
  bool get isAdmin => admin.signedIn;
  Future<void> exitAdmin() async {
    admin.logout();
    _destination = CakeDestination.home;
    await _persist(_snapshot());
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
  String? authNotice;
  RegistrationDraft? _registrationDraft;
  LocalAccount? _resetAccount;
  VerificationSession? verificationSession;
  bool get usesDevelopmentVerification => verificationService.isDevelopment;
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
      final session = Map<String, dynamic>.from(data['session'] as Map? ?? {});
      final adminUsername = '${session['adminUsername'] ?? ''}';
      final customerEmail = '${session['customerEmail'] ?? ''}';
      if (adminUsername.isNotEmpty && admin.restoreSession(adminUsername)) {
        _destination = CakeDestination.admin;
      } else if (customerEmail.isNotEmpty) {
        final account = _accounts
            .where((candidate) => candidate.email == customerEmail)
            .firstOrNull;
        if (account != null) {
          _restoreCustomer(account);
          _destination = CakeDestination.home;
        }
      }
    } catch (_) {
      error = 'Saved data could not be loaded.';
    }
    notifyListeners();
  }

  Map<String, dynamic> _snapshot({
    List<CartItem>? cart,
    List<CakeOrder>? orders,
    bool includeSession = true,
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
      'session': {
        'customerEmail': includeSession ? email : '',
        'adminUsername': includeSession && admin.signedIn ? admin.username : '',
      },
    };
  }

  void _restoreCustomer(LocalAccount account) {
    _account = account;
    final data = Map<String, dynamic>.from(
      _userData[account.email] as Map? ?? {},
    );
    _cart = (data['cart'] as List? ?? [])
        .map((e) => CartItem.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    _orders = (data['orders'] as List? ?? [])
        .map((e) => CakeOrder.fromJson(Map<String, dynamic>.from(e as Map)))
        .where((e) => e.items.isNotEmpty)
        .toList();
    _profile = data['profile'] == null
        ? UserProfile(name: account.name, phone: account.phone)
        : UserProfile.fromJson(
            Map<String, dynamic>.from(data['profile'] as Map),
          );
    final directory = admin
        .records('customers')
        .where((record) => record.text('email') == account.email)
        .firstOrNull;
    if (directory != null) {
      _profile = UserProfile(
        name: directory.text('name'),
        address: directory.text('address'),
        phone: directory.text('phone').isEmpty
            ? account.phone
            : directory.text('phone'),
      );
    }
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
        await _persist(_snapshot());
      } else {
        authError = 'Username or password is incorrect.';
      }
      notifyListeners();
      return;
    }
    if (name != null &&
        !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(normalized)) {
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
        if (candidate.email == normalized || candidate.username == normalized) {
          account = candidate;
        }
      }
      if (name != null) {
        if (account != null) {
          authError = 'This email is already registered. Please log in.';
          return;
        }
        account = await LocalAccount.create(
          name.trim(),
          normalized,
          password,
          username: normalized,
        );
        _accounts.add(account);
        if (!await _persist(_snapshot())) {
          _accounts.remove(account);
          authError = 'Registration could not be saved. Please retry.';
          return;
        }
      } else if (account == null || !await account.verify(password)) {
        authError = 'Username or password is incorrect.';
        return;
      }
      _restoreCustomer(account);
      final customerEmail = account.email;
      await admin.syncCustomer(
        customerEmail,
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

  Future<bool> beginRegistration({
    required String name,
    required String username,
    required String email,
    required String phone,
    required String gender,
    required String password,
    required String confirmPassword,
    required VerificationChannel channel,
  }) async {
    if (busy) return false;
    authError = null;
    authNotice = null;
    final cleanName = name.trim();
    final cleanUsername = username.trim().toLowerCase();
    final cleanEmail = email.trim().toLowerCase();
    final cleanPhone = normalizeMalaysiaMobile(phone);
    if (cleanName.isEmpty) return _authFail('Enter your full name.');
    if (!RegExp(r'^[a-z0-9_.-]{3,30}$').hasMatch(cleanUsername)) {
      return _authFail(
        'Username must be 3–30 letters, numbers, dots, underscores or hyphens.',
      );
    }
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(cleanEmail)) {
      return _authFail('Enter a valid email address.');
    }
    if (cleanPhone == null) {
      return _authFail('Enter a valid Malaysian mobile number.');
    }
    if (gender.isEmpty) return _authFail('Select your gender.');
    if (password.length < 8) {
      return _authFail('Use at least 8 characters for your password.');
    }
    if (password != confirmPassword) {
      return _authFail('Passwords do not match.');
    }
    if (admin.hasUsername(cleanUsername) ||
        _accounts.any(
          (a) =>
              a.username == cleanUsername ||
              a.email == cleanEmail ||
              a.phone == cleanPhone,
        )) {
      return _authFail(
        'That username, email or phone number is already registered.',
      );
    }
    _registrationDraft = RegistrationDraft(
      name: cleanName,
      username: cleanUsername,
      email: cleanEmail,
      phone: cleanPhone,
      gender: gender,
      password: password,
    );
    return _sendVerification(
      channel: channel,
      purpose: VerificationPurpose.registration,
      destination: channel == VerificationChannel.email
          ? cleanEmail
          : cleanPhone,
    );
  }

  Future<bool> beginPasswordReset({
    required String username,
    required VerificationChannel channel,
  }) async {
    if (busy) return false;
    authError = null;
    authNotice = null;
    final value = username.trim().toLowerCase();
    _resetAccount = _accounts
        .where((a) => a.username == value || a.email == value)
        .firstOrNull;
    if (_resetAccount == null) {
      return _authFail('No customer account matches that username or email.');
    }
    final destination = channel == VerificationChannel.email
        ? _resetAccount!.email
        : _resetAccount!.phone;
    if (destination.isEmpty) {
      return _authFail('This account does not have that recovery method.');
    }
    return _sendVerification(
      channel: channel,
      purpose: VerificationPurpose.passwordReset,
      destination: destination,
    );
  }

  Future<bool> _sendVerification({
    required VerificationChannel channel,
    required VerificationPurpose purpose,
    required String destination,
  }) async {
    busy = true;
    notifyListeners();
    try {
      verificationSession = await verificationService.sendCode(
        channel: channel,
        purpose: purpose,
        destination: destination,
      );
      _destination = CakeDestination.verifyAccount;
      return true;
    } catch (_) {
      return _authFail(
        'The verification code could not be sent. Please retry.',
      );
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<bool> resendVerification() async {
    final session = verificationSession;
    final draft = _registrationDraft;
    final reset = _resetAccount;
    if (session == null) return _authFail('Start verification again.');
    final destination = session.purpose == VerificationPurpose.registration
        ? (session.channel == VerificationChannel.email
              ? draft?.email
              : draft?.phone)
        : (session.channel == VerificationChannel.email
              ? reset?.email
              : reset?.phone);
    if (destination == null || destination.isEmpty) {
      return _authFail('Start verification again.');
    }
    return _sendVerification(
      channel: session.channel,
      purpose: session.purpose,
      destination: destination,
    );
  }

  Future<bool> verifyAuthenticationCode(String code) async {
    if (busy || verificationSession == null) return false;
    if (!RegExp(r'^\d{6}$').hasMatch(code.trim())) {
      return _authFail('Enter the 6-digit verification code.');
    }
    busy = true;
    authError = null;
    notifyListeners();
    try {
      final verified = await verificationService.verifyCode(
        verificationSession!,
        code,
      );
      if (!verified) {
        return _authFail('The verification code is incorrect or expired.');
      }
      if (verificationSession!.purpose == VerificationPurpose.passwordReset) {
        verificationSession = null;
        _destination = CakeDestination.resetPassword;
        return true;
      }
      final draft = _registrationDraft!;
      final account = await LocalAccount.create(
        draft.name,
        draft.email,
        draft.password,
        username: draft.username,
        phone: draft.phone,
        gender: draft.gender,
      );
      _accounts.add(account);
      if (!await _persist(_snapshot())) {
        _accounts.remove(account);
        return _authFail('Registration could not be saved. Please retry.');
      }
      _registrationDraft = null;
      verificationSession = null;
      authNotice = 'Account verified. Log in with your username and password.';
      _destination = CakeDestination.login;
      return true;
    } catch (_) {
      return _authFail('Verification could not be completed. Please retry.');
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<bool> resetPassword(String password, String confirmPassword) async {
    if (busy || _resetAccount == null) return false;
    if (password.length < 8) {
      return _authFail('Use at least 8 characters for your password.');
    }
    if (password != confirmPassword) {
      return _authFail('Passwords do not match.');
    }
    busy = true;
    authError = null;
    notifyListeners();
    final old = _resetAccount!;
    try {
      final replacement = await old.withPassword(password);
      final index = _accounts.indexOf(old);
      _accounts[index] = replacement;
      if (!await _persist(_snapshot())) {
        _accounts[index] = old;
        return _authFail('The new password could not be saved. Please retry.');
      }
      _resetAccount = null;
      authNotice = 'Password updated. Log in with your new password.';
      _destination = CakeDestination.login;
      return true;
    } catch (_) {
      return _authFail('The new password could not be saved. Please retry.');
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  bool _authFail(String message) {
    authError = message;
    notifyListeners();
    return false;
  }

  void cancelAuthenticationFlow() {
    if (busy) return;
    verificationSession = null;
    _registrationDraft = null;
    _resetAccount = null;
    authError = null;
    authNotice = null;
    _destination = CakeDestination.login;
    notifyListeners();
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
    final snapshot = _snapshot(includeSession: false);
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

  Future<bool> _persist(
    Map<String, dynamic> data, {
    bool requireRemote = false,
  }) {
    final operation = _writes.then(
      (_) => repository.save(data, requireRemote: requireRemote),
    );
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
    if ({
      CakeDestination.login,
      CakeDestination.register,
      CakeDestination.verifyAccount,
      CakeDestination.forgotPassword,
      CakeDestination.resetPassword,
    }.contains(_destination)) {
      if (_destination != CakeDestination.login &&
          _destination != CakeDestination.register) {
        cancelAuthenticationFlow();
        return;
      }
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
