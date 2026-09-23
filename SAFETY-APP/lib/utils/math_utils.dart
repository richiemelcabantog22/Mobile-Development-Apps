import 'dart:math';

double clamp(double v, double minValue, double maxValue) {
  return max(minValue, min(maxValue, v));
}

double deg(double rad) => rad * 180.0 / pi;
double rad(double deg) => deg * pi / 180.0;