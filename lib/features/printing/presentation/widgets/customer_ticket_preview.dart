import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../domain/entities/customer_ticket_data.dart';
import '../../infrastructure/qr/qr_code_svg.dart';
import '../print_preview_formatters.dart';
import 'qr_svg_view.dart';

class CustomerTicketPreview extends StatelessWidget {
  const CustomerTicketPreview({
    required this.ticket,
    required this.qrCode,
    super.key,
  });

  final CustomerTicketData ticket;
  final QrCodeSvg qrCode;

  @override
  Widget build(BuildContext context) {
    const dateFormatter = PrintPreviewDateFormatter();

    return Container(
      width: 380,
      constraints: const BoxConstraints(minHeight: 640),
      padding: const EdgeInsets.all(AppSpacing.xxl),
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
            _TicketHeader(ticket: ticket),
            const _DashedDivider(),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: _TicketField(
                    label: 'Repair Code',
                    value: ticket.repairCode,
                    valueStyle: Theme.of(context).textTheme.headlineSmall
                        ?.copyWith(
                          color: Colors.black,
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                ),
                _TicketField(
                  label: 'Received Date',
                  value: dateFormatter.formatDate(ticket.receivedAt),
                  alignEnd: true,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _TicketField(
                    label: 'Customer',
                    value: _value(ticket.customerName),
                    secondaryValue: ticket.customerPhone,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _TicketField(
                    label: 'Device',
                    value: ticket.deviceDisplayName,
                    secondaryValue: 'Type: ${_value(ticket.deviceType)}',
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            const Divider(height: 1, color: AppColors.border),
            const SizedBox(height: AppSpacing.md),
            _TicketField(
              label: 'Problem Reported',
              value: ticket.reportedProblem,
              italic: true,
            ),
            const SizedBox(height: AppSpacing.md),
            _TicketField(
              label: 'Included Accessories',
              value: _value(ticket.receivedAccessories),
            ),
            if (ticket.isWarrantyReturn) ...[
              const SizedBox(height: AppSpacing.md),
              _TicketField(
                label: 'Warranty Return',
                value: ticket.originalRepairCode == null
                    ? 'Linked previous repair'
                    : 'Original repair: ${ticket.originalRepairCode}',
              ),
            ],
            const SizedBox(height: AppSpacing.xl),
            Center(
              child: Column(
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.borderStrong),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.xxs),
                      child: QrSvgView(
                        qrCode: qrCode,
                        size: 96,
                        semanticLabel: 'QR code for repair tracking',
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Scan to track your repair',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Colors.black,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    ticket.repairCode,
                    style: Theme.of(
                      context,
                    ).textTheme.labelSmall?.copyWith(color: Colors.black54),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            if (ticket.ticketFooter != null ||
                ticket.warrantyTerms != null) ...[
              const _DashedDivider(),
              if (ticket.ticketFooter != null)
                Text(
                  ticket.ticketFooter!,
                  textAlign: TextAlign.center,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.black54),
                ),
              if (ticket.warrantyTerms != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  ticket.warrantyTerms!,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.black,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _TicketHeader extends StatelessWidget {
  const _TicketHeader({required this.ticket});

  final CustomerTicketData ticket;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          ticket.shopName,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: Colors.black,
            fontWeight: FontWeight.w900,
          ),
        ),
        if (ticket.shopSubtitle != null) ...[
          const SizedBox(height: AppSpacing.xxs),
          Text(
            ticket.shopSubtitle!,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.black,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.xxs),
        if (ticket.shopPhone != null)
          Text(
            'Phone: ${ticket.shopPhone}',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Colors.black54),
          ),
        if (ticket.shopAddress != null)
          Text(
            'Address: ${ticket.shopAddress}',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Colors.black54),
          ),
      ],
    );
  }
}

class _TicketField extends StatelessWidget {
  const _TicketField({
    required this.label,
    required this.value,
    this.secondaryValue,
    this.valueStyle,
    this.alignEnd = false,
    this.italic = false,
  });

  final String label;
  final String value;
  final String? secondaryValue;
  final TextStyle? valueStyle;
  final bool alignEnd;
  final bool italic;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: alignEnd
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: Colors.black38,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          value,
          textAlign: alignEnd ? TextAlign.right : TextAlign.left,
          style:
              valueStyle ??
              Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.black,
                fontWeight: FontWeight.w700,
                fontStyle: italic ? FontStyle.italic : FontStyle.normal,
              ),
        ),
        if (secondaryValue != null)
          Text(
            secondaryValue!,
            textAlign: alignEnd ? TextAlign.right : TextAlign.left,
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: Colors.black54),
          ),
      ],
    );
  }
}

class _DashedDivider extends StatelessWidget {
  const _DashedDivider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final dashCount = (constraints.maxWidth / 6).floor();
          return Row(
            children: List.generate(
              dashCount,
              (_) => const Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 1),
                  child: Divider(height: 1, color: AppColors.borderStrong),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

String _value(String? value) {
  final trimmed = value?.trim();
  return trimmed == null || trimmed.isEmpty ? '—' : trimmed;
}
