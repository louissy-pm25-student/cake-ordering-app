import 'package:cake_ordering_app/viewmodel/cake_viewmodel.dart';

Future<void> seedMenu(CakeViewModel vm) async {
  await vm.admin.login('admin', 'admin123');
  await vm.admin.save('products', {
    'name': 'Strawberry Dream',
    'description': 'Vanilla sponge',
    'price': 29,
    'category': 'Birthday',
    'available': true,
  }, id: 'strawberry');
  vm.admin.logout();
}
