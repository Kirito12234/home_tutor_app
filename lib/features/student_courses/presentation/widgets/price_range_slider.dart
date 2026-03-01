import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';

class PriceRangeSlider extends StatefulWidget {
  final double minPrice;
  final double maxPrice;
  final RangeValues? initialRange;
  final ValueChanged<RangeValues>? onChanged;

  const PriceRangeSlider({
    Key? key,
    this.minPrice = 0,
    this.maxPrice = 100000,
    this.initialRange,
    this.onChanged,
  }) : super(key: key);

  @override
  State<PriceRangeSlider> createState() => _PriceRangeSliderState();
}

class _PriceRangeSliderState extends State<PriceRangeSlider> {
  late RangeValues _values;

  @override
  void initState() {
    super.initState();
    _values = widget.initialRange ?? RangeValues(widget.minPrice, widget.maxPrice);
  }
  
  @override
  void didUpdateWidget(covariant PriceRangeSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialRange != null && widget.initialRange != oldWidget.initialRange) {
      _values = widget.initialRange!;
    }
  }

  String _formatPrice(double price) {
    return 'Rs${price.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    )}';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        RangeSlider(
          values: _values,
          min: widget.minPrice,
          max: widget.maxPrice,
          divisions: 100,
          activeColor: AppColors.primary,
          inactiveColor: AppColors.inputBorder,
          onChanged: (values) {
            setState(() {
              _values = values;
            });
            widget.onChanged?.call(values);
          },
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _formatPrice(_values.start),
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textPrimary,
                fontFamily: 'OpenSans',
              ),
            ),
            Text(
              _formatPrice(_values.end),
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textPrimary,
                fontFamily: 'OpenSans',
              ),
            ),
          ],
        ),
      ],
    );
  }
}


