import 'package:flutter/material.dart';
import 'package:obs_blade/utils/styling_helper.dart';

class IconClipper extends CustomClipper<Path> {
  final double xCut;
  final double yCut;

  final double borderRadius;

  IconClipper({@required this.xCut, this.yCut, this.borderRadius = 4.0});

  @override
  Path getClip(Size size) => Path()
    ..moveTo(0.0, this.yCut)
    ..lineTo(size.width - (this.xCut + this.borderRadius), this.yCut)
    ..quadraticBezierTo(size.width - this.xCut, this.yCut,
        size.width - this.xCut, (this.yCut + this.borderRadius))
    ..lineTo(size.width - this.xCut, size.height)
    ..lineTo(0.0, size.height)
    ..close();

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => true;
}

class HeaderDecoration extends StatelessWidget {
  final IconData icon;
  final double iconSize;

  final double iconXOffset;
  final double iconYOffset;

  final double iconXCut;
  final double iconYCut;
  final double iconCornerRadius;

  HeaderDecoration({
    this.icon = StylingHelper.CUPERTINO_PIE_CHART_SOLID,
    this.iconSize = 128.0,
    this.iconXOffset = 42.0,
    this.iconYOffset = -42.0,
    this.iconXCut = 28.0,
    this.iconYCut = 42.0,
    this.iconCornerRadius = 4.0,
  });

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: Offset(
        this.iconXOffset,
        this.iconYOffset,
      ),
      child: ClipPath(
        clipper: IconClipper(
          xCut: this.iconXCut,
          yCut: this.iconYCut,
          borderRadius: this.iconCornerRadius,
        ),
        clipBehavior: Clip.antiAlias,
        child: Transform.rotate(
          angle: -0.0,
          child: Icon(
            this.icon,
            size: this.iconSize,
          ),
        ),
      ),
    );
  }
}
