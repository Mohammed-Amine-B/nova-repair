import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../domain/entities/customer_ticket_data.dart';
import '../../domain/entities/device_label_data.dart';
import '../../infrastructure/qr/qr_code_svg.dart';
import 'qr_svg_view.dart';

class DeviceLabelPreview extends StatelessWidget {
  const DeviceLabelPreview({
    required this.label,
    required this.ticket,
    required this.qrCode,
    super.key,
  });

  final DeviceLabelData label;
  final CustomerTicketData ticket;
  final QrCodeSvg qrCode;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320,
      height: 200,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            blurRadius: 18,
            offset: Offset(0, 10),
            color: Color(0x1A000000),
          ),
        ],
      ),
      child: DefaultTextStyle(
        style: Theme.of(
          context,
        ).textTheme.bodySmall!.copyWith(color: Colors.black),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ticket.shopName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        label.repairCode,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              color: Colors.black,
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                    ],
                  ),
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.borderStrong),
                  ),
                  child: QrSvgView(qrCode: qrCode, size: 52),
                ),
              ],
            ),
            const Spacer(),
            const Divider(height: 1, color: AppColors.border),
            const SizedBox(height: AppSpacing.sm),
            _LabelRow(label: 'Device', value: label.deviceDisplayName),
            _LabelRow(label: 'Customer', value: _value(label.customerName)),
            _LabelRow(label: 'Phone', value: _value(label.customerPhone)),
          ],
        ),
      ),
    );
  }
}

class _LabelRow extends StatelessWidget {
  const _LabelRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xxs),
      child: Row(
        children: [
          SizedBox(
            width: 86,
            child: Text(
              label.toUpperCase(),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Colors.black38,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Colors.black,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _value(String? value) {
  final trimmed = value?.trim();
  return trimmed == null || trimmed.isEmpty ? '—' : trimmed;
}
