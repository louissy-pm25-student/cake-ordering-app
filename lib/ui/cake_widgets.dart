import 'package:flutter/material.dart';

import 'dart:convert';

import 'cake_style.dart';

String money(num value) => '\$${value.toStringAsFixed(2)}';

class AppLoadingOverlay extends StatelessWidget {
  final Widget child;
  final bool isLoading;

  const AppLoadingOverlay({
    required this.child,
    required this.isLoading,
    super.key,
  });

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      child,
      if (isLoading)
        Positioned.fill(
          child: Semantics(
            label: 'Loading',
            liveRegion: true,
            child: AbsorbPointer(
              child: ColoredBox(
                color: CakeStyle.ink.withValues(alpha: 0.20),
                child: Center(
                  child: Container(
                    width: 72,
                    height: 72,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: CakeStyle.paper,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x24000000),
                          blurRadius: 24,
                          offset: Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const SizedBox(
                      width: 34,
                      height: 34,
                      child: CircularProgressIndicator(strokeWidth: 3),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
    ],
  );
}

class CakePhoto extends StatelessWidget {
  final int index;
  final String photoData;
  const CakePhoto(this.index, {this.photoData = '', super.key});
  @override
  Widget build(BuildContext context) => photoData.isNotEmpty
      ? ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Image.memory(
            base64Decode(photoData),
            fit: BoxFit.cover,
            errorBuilder: (context, error, stack) =>
                const Icon(Icons.cake_outlined),
          ),
        )
      : ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: LayoutBuilder(
            builder: (context, box) => OverflowBox(
              alignment: Alignment(index.isEven ? -1 : 1, index < 2 ? -1 : 1),
              maxWidth: box.maxWidth * 2,
              maxHeight: box.maxHeight * 2,
              child: Image.asset(
                'assets/cake_collection.png',
                width: box.maxWidth * 2,
                height: box.maxHeight * 2,
                fit: BoxFit.fill,
                semanticLabel: [
                  'Strawberry cake',
                  'Chocolate cake',
                  'Vanilla cake',
                  'Red velvet cake',
                ][index.clamp(0, 3)],
              ),
            ),
          ),
        );
}

class PageTitle extends StatelessWidget {
  final String title, subtitle;
  const PageTitle(this.title, this.subtitle, {super.key});
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(title, style: Theme.of(context).textTheme.headlineMedium),
      const SizedBox(height: 7),
      Text(subtitle, style: const TextStyle(color: CakeStyle.muted)),
      const SizedBox(height: 20),
    ],
  );
}

class CakePanel extends StatelessWidget {
  final Widget child;
  final Color color;
  final double padding;
  const CakePanel({
    required this.child,
    this.color = CakeStyle.paper,
    this.padding = 20,
    super.key,
  });
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: EdgeInsets.all(padding),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(24),
    ),
    child: child,
  );
}

class Choices extends StatelessWidget {
  final List<String> options;
  final String selected;
  final ValueChanged<String> onChanged;
  const Choices(this.options, this.selected, this.onChanged, {super.key});
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Row(
      children: options
          .map(
            (option) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(option),
                selected: selected == option,
                onSelected: (_) => onChanged(option),
                showCheckmark: false,
                selectedColor: CakeStyle.caramel,
                backgroundColor: CakeStyle.paper,
                labelStyle: TextStyle(
                  color: selected == option ? Colors.white : CakeStyle.ink,
                ),
                side: BorderSide.none,
                shape: const StadiumBorder(),
                padding: const EdgeInsets.all(8),
              ),
            ),
          )
          .toList(),
    ),
  );
}

class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  const PrimaryButton(this.label, this.onPressed, {super.key});
  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    child: FilledButton(
      onPressed: onPressed,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Text(label, textAlign: TextAlign.center),
      ),
    ),
  );
}

class PriceRow extends StatelessWidget {
  final String label, value;
  const PriceRow(this.label, this.value, {super.key});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      children: [
        Expanded(
          child: Text(label, style: const TextStyle(color: CakeStyle.muted)),
        ),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    ),
  );
}

class EmptyCard extends StatelessWidget {
  final String title, subtitle;
  const EmptyCard(this.title, this.subtitle, {super.key});
  @override
  Widget build(BuildContext context) => CakePanel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 20, fontFamily: 'serif')),
        const SizedBox(height: 10),
        Text(subtitle),
      ],
    ),
  );
}

const gap = SizedBox(height: 18);
