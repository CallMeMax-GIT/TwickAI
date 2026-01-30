import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

Widget customLoader(context, Color color) {
  return Center(
    child: LoadingAnimationWidget.staggeredDotsWave(
      color: color,
      size: MediaQuery.sizeOf(context).height * 0.035,
    ),
  );
}