import "package:flutter/material.dart";




class SkewCut extends CustomClipper<Path> {

    bool left,
         right;

    SkewCut({
        required this.left,
        required this.right
    });


    @override
    Path getClip(Size size) {

        double topLeftX = left ? 20 : 0;
        double bottomRightX = size.width - (right ? 20 : 0);

        final path = Path();

        path.moveTo(topLeftX, 0);
        path.lineTo(size.width, 0);
        path.lineTo(bottomRightX, size.height);
        path.lineTo(0, size.height);
        path.close();

        return path;
    }

    @override
    bool shouldReclip(SkewCut oldClipper) => false;
}




