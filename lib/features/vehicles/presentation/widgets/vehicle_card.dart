import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/models/vehicle_model.dart';

class VehicleCard extends StatelessWidget {
  const VehicleCard({
    required this.vehicle,
    required this.healthScore,
    super.key,
  });

  final Vehicle vehicle;
  final int? healthScore;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/vehicles/${vehicle.id}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Photo
            SizedBox(
              height: 140,
              child: vehicle.photoUrl != null
                  ? CachedNetworkImage(
                      imageUrl: vehicle.photoUrl!,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => const ColoredBox(
                        color: Color(0xFFEEEEEE),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    )
                  : const ColoredBox(
                      color: Color(0xFFEEEEEE),
                      child: Center(
                        child: Icon(
                          Icons.directions_car,
                          size: 48,
                          color: Colors.grey,
                        ),
                      ),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${vehicle.make} ${vehicle.model}',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          '${vehicle.year} • ${vehicle.color}',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: Colors.grey),
                        ),
                        if (vehicle.plate != null)
                          Text(
                            vehicle.plate!,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: Colors.grey),
                          ),
                      ],
                    ),
                  ),
                  if (healthScore != null)
                    _HealthScoreBadge(score: healthScore!),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HealthScoreBadge extends StatelessWidget {
  const _HealthScoreBadge({required this.score});

  final int score;

  Color get _color {
    if (score >= 80) return AppColors.healthGood;
    if (score >= 50) return AppColors.healthWarning;
    return AppColors.healthBad;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: _color.withOpacity(0.15),
        shape: BoxShape.circle,
        border: Border.all(color: _color, width: 2),
      ),
      child: Center(
        child: Text(
          '$score%',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: _color,
                fontWeight: FontWeight.bold,
              ),
        ),
      ),
    );
  }
}
