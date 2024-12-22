import 'dart:ui';

import 'package:flutter/cupertino.dart';

class RPSCustomPainter extends CustomPainter{

  @override
  void paint(Canvas canvas, Size size) {



    // Layer 1

    Paint paint_fill_0 = Paint()
      ..color = const Color.fromARGB(255, 255, 255, 255)
      ..style = PaintingStyle.fill
      ..strokeWidth = size.width*0.00
      ..strokeCap = StrokeCap.butt
      ..strokeJoin = StrokeJoin.miter;


    Path path_0 = Path();
    path_0.moveTo(size.height,size.height);
    path_0.lineTo(size.height*1.5,size.height*0.5);
    path_0.lineTo(size.height,0);
    path_0.lineTo(size.width,0);
    path_0.lineTo(size.width,size.height);

    canvas.drawPath(path_0, paint_fill_0);

  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }

}
