import "package:bmd_flutter_tools/utilities/theme_utilities.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";

class BeColorSwatchGrid extends StatelessWidget {
  const BeColorSwatchGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final entries = BeColorSwatch.entries.entries.toList();

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 50,
        mainAxisSpacing: 4,
        crossAxisSpacing: 4,
        childAspectRatio: 1,
      ),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        return _SwatchTile(name: entry.key, color: entry.value);
      },
    );
  }
}

class _SwatchTile extends StatelessWidget {
  const _SwatchTile({required this.name, required this.color});

  final String name;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final textColor = _idealTextColor(color);
    return Material(
      clipBehavior: Clip.antiAlias,
      borderRadius: BorderRadius.circular(4),
      color: color,
      child: InkWell(
        onTap: () {
          Clipboard.setData(ClipboardData(text: name));
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Copied $name"),
              duration: const Duration(milliseconds: 800),
            ),
          );
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            Align(
              alignment: Alignment.bottomLeft,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Text(
                  name,
                  style: Theme.of(context)
                      .textTheme
                      .labelSmall
                      ?.copyWith(color: textColor, fontSize: 8, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _idealTextColor(Color background) {
    final double luminance = background.computeLuminance();
    return luminance > 0.5 ? Colors.black : Colors.white;
  }
}
