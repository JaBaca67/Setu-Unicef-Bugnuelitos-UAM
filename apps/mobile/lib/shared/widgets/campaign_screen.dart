import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';
import 'unicef_logo.dart';

class CampaignScreen extends StatelessWidget {
  const CampaignScreen({
    super.key,
    required this.header,
    required this.body,
    this.bodyRadius,
    this.bottomNavigationBar,
    this.scrollController,
    this.onHorizontalDragStart,
    this.onHorizontalDragUpdate,
    this.onHorizontalDragEnd,
    this.onHorizontalDragCancel,
  });

  final Widget header;
  final Widget body;
  final BorderRadius? bodyRadius;
  final Widget? bottomNavigationBar;
  final ScrollController? scrollController;
  final GestureDragStartCallback? onHorizontalDragStart;
  final GestureDragUpdateCallback? onHorizontalDragUpdate;
  final GestureDragEndCallback? onHorizontalDragEnd;
  final VoidCallback? onHorizontalDragCancel;

  bool get _handlesHorizontalDrag =>
      onHorizontalDragStart != null ||
      onHorizontalDragUpdate != null ||
      onHorizontalDragEnd != null ||
      onHorizontalDragCancel != null;

  @override
  Widget build(BuildContext context) {
    final Widget scrollView = CustomScrollView(
      controller: scrollController,
      slivers: <Widget>[
        SliverToBoxAdapter(
          child: SafeArea(bottom: false, child: header),
        ),
        SliverToBoxAdapter(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: bodyRadius,
            ),
            child: SafeArea(
              top: false,
              maintainBottomViewPadding: true,
              child: body,
            ),
          ),
        ),
        const SliverFillRemaining(
          hasScrollBody: false,
          child: ColoredBox(color: Colors.white),
        ),
      ],
    );
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: CureandoTheme.statusBarOverlayLight.copyWith(
        systemNavigationBarColor: bottomNavigationBar == null
            ? Colors.white
            : Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        // La barra flota: el cuerpo se extiende por detrás y recibe el alto de
        // la barra como margen inferior de `MediaQuery`, que el `SafeArea` del
        // cuerpo convierte en espacio libre al final del desplazamiento.
        extendBody: bottomNavigationBar != null,
        bottomNavigationBar: bottomNavigationBar,
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: SizedBox.expand(
              child: CampaignBackground(
                child: _handlesHorizontalDrag
                    ? GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onHorizontalDragStart: onHorizontalDragStart,
                        onHorizontalDragUpdate: onHorizontalDragUpdate,
                        onHorizontalDragEnd: onHorizontalDragEnd,
                        onHorizontalDragCancel: onHorizontalDragCancel,
                        child: scrollView,
                      )
                    : scrollView,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class CampaignBackground extends StatelessWidget {
  const CampaignBackground({super.key, this.child});

  final Widget? child;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: const BoxDecoration(
      color: CureandoTheme.blue,
      image: DecorationImage(
        image: AssetImage('assets/welcome/campaign-pattern.png'),
        fit: BoxFit.fitWidth,
        alignment: Alignment.topCenter,
        repeat: ImageRepeat.repeatY,
      ),
    ),
    child: child,
  );
}

class CampaignSymbol extends StatelessWidget {
  const CampaignSymbol({super.key, required this.size, this.showUnicef = true});

  final double size;
  final bool showUnicef;

  @override
  Widget build(BuildContext context) {
    final Widget symbol = Image.asset(
      'assets/welcome/setu-symbol-white.png',
      width: size,
      height: size,
      semanticLabel: 'SéTú',
    );
    if (!showUnicef) return symbol;
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        symbol,
        SizedBox(width: size * 0.34),
        Container(width: 1, height: size * 0.68, color: Colors.white54),
        SizedBox(width: size * 0.34),
        UnicefLogo(height: size * 0.72),
      ],
    );
  }
}
