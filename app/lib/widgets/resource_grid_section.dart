import 'package:flutter/material.dart';

import '../models/api_models.dart';
import '../utils/app_spacing.dart';
import '../utils/breakpoints.dart';
import 'responsive_layout.dart';

/// Renders a list of [HubResource] cards as a single mobile column or a
/// 2-3 column desktop grid — shared by the Notes/QP/Syllabus hub screens,
/// which otherwise repeat this exact layout pattern.
class ResourceGridSection extends StatelessWidget {
  final List<HubResource> items;
  final Widget Function(HubResource item, {bool includeMargin}) cardBuilder;

  const ResourceGridSection({
    super.key,
    required this.items,
    required this.cardBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobile: (_) => Column(
        children:
            items.map((r) => cardBuilder(r, includeMargin: true)).toList(),
      ),
      desktop: (_) => LayoutBuilder(
        builder: (context, constraints) {
          final columns = Breakpoints.isWide(constraints.maxWidth) ? 3 : 2;
          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              mainAxisSpacing: AppSpacing.lg,
              crossAxisSpacing: AppSpacing.lg,
              childAspectRatio: 1.4,
            ),
            itemBuilder: (_, i) => cardBuilder(items[i], includeMargin: false),
          );
        },
      ),
    );
  }
}
