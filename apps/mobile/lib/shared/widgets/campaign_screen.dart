import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';

class CampaignScreen extends StatelessWidget {
  const CampaignScreen({
    super.key,
    required this.header,
    required this.body,
    this.bodyRadius,
    this.bottomNavigationBar,
    this.scrollController,
  });

  final Widget header;
  final Widget body;
  final BorderRadius? bodyRadius;
  final Widget? bottomNavigationBar;
  final ScrollController? scrollController;

  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
    value: SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
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
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: MediaQuery.paddingOf(context).top,
            child: const ColoredBox(color: CureandoTheme.blue),
          ),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: SizedBox.expand(
                child: CampaignBackground(
                  child: SafeArea(
                    bottom: false,
                    child: CustomScrollView(
                      controller: scrollController,
                      slivers: <Widget>[
                        SliverToBoxAdapter(child: header),
                        SliverToBoxAdapter(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: bodyRadius,
                            ),
                            child: SafeArea(top: false, child: body),
                          ),
                        ),
                        const SliverFillRemaining(
                          hasScrollBody: false,
                          child: ColoredBox(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class CampaignBackground extends StatelessWidget {
  const CampaignBackground({super.key, this.child});

  final Widget? child;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: const BoxDecoration(
      color: CureandoTheme.blue,
      image: DecorationImage(
        image: AssetImage('assets/welcome/pag1-fondo.png'),
        fit: BoxFit.cover,
        alignment: Alignment.topCenter,
      ),
    ),
    child: child,
  );
}

class CampaignSymbol extends StatelessWidget {
  const CampaignSymbol({super.key, required this.size});

  final double size;

  @override
  Widget build(BuildContext context) => Image.asset(
    'assets/welcome/setu-symbol-white.png',
    width: size,
    height: size,
    semanticLabel: 'SéTú',
  );
}
