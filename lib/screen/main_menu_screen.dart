import 'package:flutter/material.dart';

import '../viewmodel/cake_viewmodel.dart';
import '../model/cake.dart';
import '../nav/cake_destination.dart';
import '../ui/cake_style.dart';
import '../ui/cake_widgets.dart';

class MainMenuScreen extends StatelessWidget {
  final CakeViewModel vm;
  const MainMenuScreen(this.vm, {super.key});
  Future<void> _add(BuildContext context, Cake cake) async {
    if (!vm.isLoggedIn) {
      vm.addCake(cake);
      return;
    }
    final variants = vm.admin
        .records('variants')
        .where((v) => v.text('product') == cake.id)
        .toList();
    if (variants.isEmpty) {
      vm.addCake(cake);
      return;
    }
    final selected = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.all(20),
          children: [
            Text(cake.name, style: Theme.of(context).textTheme.headlineSmall),
            ListTile(
              title: const Text('Standard cake'),
              trailing: Text(money(cake.price)),
              onTap: () => Navigator.pop(context, ''),
            ),
            ...variants.map(
              (v) => ListTile(
                title: Text(v.text('name')),
                subtitle: Text(
                  '${v.text('size')} · ${v.text('flavor')} · ${v.text('filling')}',
                ),
                trailing: Text(money(cake.price + v.number('adjustment'))),
                onTap: () => Navigator.pop(context, v.id),
              ),
            ),
          ],
        ),
      ),
    );
    if (selected != null) vm.addCake(cake, variantId: selected);
  }

  @override
  Widget build(BuildContext context) {
    final home = vm.destination == CakeDestination.home;
    return ListView(
      padding: const EdgeInsets.all(22),
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'SWEET STUDIO',
                    style: TextStyle(
                      color: CakeStyle.caramel,
                      letterSpacing: 2,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    home
                        ? 'A little cake,\na lot of happiness.'
                        : 'Our Cake Menu',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ],
              ),
            ),
            IconButton.filledTonal(
              tooltip: 'Your profile',
              onPressed: () => vm.navigate(CakeDestination.profile),
              icon: const Icon(Icons.person_outline),
            ),
          ],
        ),
        gap,
        TextFormField(
          initialValue: vm.query,
          onChanged: vm.setQuery,
          decoration: const InputDecoration(
            hintText: 'Search cakes or flavors',
            prefixIcon: Icon(Icons.search),
          ),
        ),
        gap,
        Choices(
          const ['All', 'Birthday', 'Wedding', 'Custom', 'Seasonal'],
          vm.category,
          vm.setCategory,
        ),
        gap,
        if (home)
          const CakePanel(
            color: CakeStyle.blush,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'BAKED WITH LOVE',
                  style: TextStyle(
                    color: CakeStyle.caramel,
                    letterSpacing: 1,
                    fontSize: 10,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Something sweet for\nevery celebration.',
                  style: TextStyle(fontFamily: 'serif', fontSize: 23),
                ),
              ],
            ),
          ),
        gap,
        Row(
          children: [
            Expanded(
              child: Text(
                home ? 'Popular cakes' : 'Fresh from our oven',
                style: const TextStyle(
                  fontFamily: 'serif',
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (home)
              TextButton(
                onPressed: () => vm.navigate(CakeDestination.menu),
                child: const Text('View all →'),
              ),
          ],
        ),
        gap,
        if (vm.filteredCakes.isEmpty)
          EmptyCard(
            vm.cakes.isEmpty ? 'Our menu is being prepared' : 'No cakes found',
            vm.cakes.isEmpty
                ? 'Check back soon for freshly added cakes.'
                : 'Try another flavor or select All.',
          ),
        LayoutBuilder(
          builder: (context, box) {
            final columns = box.maxWidth > 650 ? 3 : 2;
            final width = (box.maxWidth - 14 * (columns - 1)) / columns;
            return Wrap(
              spacing: 14,
              runSpacing: 14,
              children: vm.filteredCakes
                  .map(
                    (cake) => SizedBox(
                      width: width,
                      child: CakePanel(
                        padding: 8,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AspectRatio(
                              aspectRatio: 1,
                              child: cake.photoData.isEmpty
                                  ? const ColoredBox(
                                      color: CakeStyle.blush,
                                      child: Icon(
                                        Icons.cake_outlined,
                                        size: 60,
                                        color: CakeStyle.caramel,
                                      ),
                                    )
                                  : CakePhoto(
                                      cake.photo,
                                      photoData: cake.photoData,
                                    ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(7),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    cake.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 7),
                                  Text(
                                    cake.note,
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: CakeStyle.muted,
                                      fontSize: 11,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 6,
                                    crossAxisAlignment:
                                        WrapCrossAlignment.center,
                                    children: [
                                      Text(
                                        money(cake.price),
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      FilledButton.tonal(
                                        onPressed: cake.available
                                            ? () => _add(context, cake)
                                            : null,
                                        child: Text(
                                          cake.available
                                              ? 'Add'
                                              : 'Out of stock',
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                  .toList(),
            );
          },
        ),
        gap,
        const Text(
          'Made with care. Shared with love.',
          style: TextStyle(color: CakeStyle.muted, fontSize: 12),
        ),
        if (!vm.isLoggedIn)
          TextButton.icon(
            onPressed: () => vm.navigate(CakeDestination.login),
            icon: const Icon(Icons.admin_panel_settings_outlined),
            label: const Text('Staff / admin login'),
          ),
        if (vm.cart.isNotEmpty) const SizedBox(height: 80),
      ],
    );
  }
}
