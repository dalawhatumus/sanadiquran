import 'package:flutter/widgets.dart';

// Page turning that answers short, gentle swipes.

/// Page turning that is easy on the hand: a short swipe in either direction
/// turns the page (no need to drag past halfway), and pages settle quickly.
class EasyPagePhysics extends PageScrollPhysics {
  const EasyPagePhysics({super.parent});

  @override
  EasyPagePhysics applyTo(ScrollPhysics? ancestor) => EasyPagePhysics(parent: buildParent(ancestor));

  @override
  SpringDescription get spring => const SpringDescription(mass: 0.6, stiffness: 260, damping: 25);

  /// Even a gentle flick counts (Flutter's default ignores flicks slower
  /// than 50 pixels a second, which made short swipes snap back).
  @override
  double get minFlingVelocity => 5;

  @override
  Simulation? createBallisticSimulation(ScrollMetrics position, double velocity) {
    if ((velocity <= 0 && position.pixels <= position.minScrollExtent) ||
        (velocity >= 0 && position.pixels >= position.maxScrollExtent)) {
      return super.createBallisticSimulation(position, velocity);
    }
    final viewport = position.viewportDimension;
    final page = position.pixels / viewport;
    final tolerance = toleranceFor(position);
    // Any deliberate movement turns the page in that direction.
    final double target;
    if (velocity.abs() > 20) {
      target = velocity > 0 ? page.ceilToDouble() : page.floorToDouble();
    } else {
      target = page.roundToDouble();
    }
    final to = (target * viewport).clamp(position.minScrollExtent, position.maxScrollExtent);
    if ((to - position.pixels).abs() < tolerance.distance) return null;
    return ScrollSpringSimulation(spring, position.pixels, to, velocity, tolerance: tolerance);
  }
}
