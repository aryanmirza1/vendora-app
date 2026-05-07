import 'package:flutter/material.dart';

class VendoraLogo extends StatelessWidget {
  final double? size;
  final bool showTagline;

  const VendoraLogo({
    super.key,
    this.size,
    this.showTagline = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Logo Image
            Image.asset(
              'assets/images/vendora_logo.png',
              width: size ?? 40,
              height: size ?? 40,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 8),
            Text(
              'Vendora',
              style: TextStyle(
                fontSize: (size ?? 40) * 0.7,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
        if (showTagline) ...[
          const SizedBox(height: 8),
          Text(
            'Your Style, Delivered.',
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ],
      ],
    );
  }
}



