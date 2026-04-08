import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../data/models/maintenance_record_model.dart';

class MaintenanceCard extends StatelessWidget {
  const MaintenanceCard({required this.record, super.key});

  final MaintenanceRecord record;

  bool get _isOverdue {
    if (record.nextDueAt == null) return false;
    return record.nextDueAt!.isBefore(DateTime.now());
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    record.title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                if (_isOverdue)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.error),
                    ),
                    child: Text(
                      'Vencida',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppColors.error,
                          ),
                    ),
                  ),
              ],
            ),
            if (record.description != null) ...[
              const SizedBox(height: 4),
              Text(
                record.description!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey,
                    ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 4,
              children: [
                _Chip(
                  icon: Icons.calendar_today,
                  label: formatDate(record.performedAt),
                ),
                if (record.nextDueAt != null)
                  _Chip(
                    icon: Icons.event,
                    label: formatDueDate(record.nextDueAt),
                    color: _isOverdue ? AppColors.error : null,
                  ),
                if (record.costBrl != null)
                  _Chip(
                    icon: Icons.attach_money,
                    label: formatBrl(record.costBrl),
                  ),
                if (record.workshopName != null)
                  _Chip(
                    icon: Icons.store_outlined,
                    label: record.workshopName!,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.icon, required this.label, this.color});

  final IconData icon;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? Colors.grey;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: effectiveColor),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: effectiveColor),
        ),
      ],
    );
  }
}
