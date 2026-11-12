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
  });

  final Widget header;
  final Widget body;
  final BorderRadius? bodyRadius;
  final Widget? bottomNavigationBar;

  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
    value: const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
    child: Scaffold(
      backgroundColor: Colors.white,
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
                child: DecoratedBox(
                  decoration: const BoxDecoration(
                    color: CureandoTheme.blue,
                    image: DecorationImage(
                      image: AssetImage('assets/welcome/campaign-pattern.png'),
                      fit: BoxFit.fitWidth,
                      alignment: Alignment.topCenter,
                      repeat: ImageRepeat.repeatY,
                    ),
                  ),
                  child: SafeArea(
                    bottom: false,
                    child: CustomScrollView(
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
