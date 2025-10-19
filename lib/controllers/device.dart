/**
 * Created by:  Blake Davis
 * Description: Information about the device
 * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */

import "dart:ui";

import "package:flutter/material.dart";




// First get the FlutterView.
FlutterView view = WidgetsBinding.instance.platformDispatcher.views.first;

// Dimensions in physical pixels (px)
// Size size = view.physicalSize;
// double width = size.width;
// double height = size.height;

// Dimensions in logical pixels (dp)
Size   device_logical_size   = view.physicalSize / view.devicePixelRatio;
double device_logical_width  = device_logical_size.width;
double device_logical_height = device_logical_size.height;