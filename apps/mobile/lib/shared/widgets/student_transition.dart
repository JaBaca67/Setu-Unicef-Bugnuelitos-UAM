import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

Page<T> studentTransition<T>(
  BuildContext context,
  GoRouterState state,
  Widget child,
) {
  if (MediaQuery.disableAnimationsOf(context)) {
    return NoTransitionPage<T>(key: state.pageKey, child: child);
  }
  return CustomTransitionPage<T>(
    key: state.pageKey,
    transitionDuration: const Duration(milliseconds: 260),
    reverseTransitionDuration: const Duration(milliseconds: 220),
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final Animation<double> progress = animation.drive(
        CurveTween(curve: Curves.easeOutCubic),
      );
      return FadeTransition(
        opacity: progress,
        child: SlideTransition(
          position: progress.drive(
            Tween<Offset>(begin: const Offset(.035, 0), end: Offset.zero),
          ),
          child: child,
        ),
      );
    },
  );
}
