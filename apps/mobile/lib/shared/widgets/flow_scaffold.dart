import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_theme.dart';
import 'campaign_screen.dart';

/// Pantalla de recorrido: encabezado azul de campaña, cuerpo blanco con
/// desplazamiento y una acción fija abajo que nunca queda fuera de vista.
class FlowScaffold extends StatelessWidget {
  const FlowScaffold({
    super.key,
    required this.header,
    required this.body,
    this.bottom,
    this.bottomNavigationBar,
  });

  final Widget header;
  final Widget body;
  final Widget? bottom;
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
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              ClipRect(
                child: CampaignBackground(
                  child: SafeArea(bottom: false, child: header),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                  child: body,
                ),
              ),
              if (bottom != null)
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                    child: bottom,
                  ),
                ),
            ],
          ),
        ),
      ),
    ),
  );
}

class FlowHeader extends StatelessWidget {
  const FlowHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.showBrand = false,
    this.brandTrailing,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final bool showBrand;
  final Widget? brandTrailing;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final bool largeText = MediaQuery.textScalerOf(context).scale(16) > 22;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 6, 14, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (showBrand)
            Padding(
              padding: const EdgeInsets.only(left: 14, bottom: 2),
              child: Row(
                children: <Widget>[
                  const CampaignSymbol(size: 28),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: ExcludeSemantics(
                      child: Text(
                        'SéTú',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  ?brandTrailing,
                ],
              ),
            ),
          Row(
            children: <Widget>[
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded),
                color: Colors.white,
                tooltip: 'Volver',
                onPressed: () => context.pop(),
              ),
              Expanded(
                child: Semantics(
                  header: true,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          height: 1.15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (subtitle != null)
                        Text(
                          subtitle!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              if (trailing != null && !largeText) trailing!,
            ],
          ),
        ],
      ),
    );
  }
}

/// Botón principal alto de los recorridos estudiantiles.
ButtonStyle flowPrimaryStyle() => FilledButton.styleFrom(
  backgroundColor: CureandoTheme.blue,
  foregroundColor: Colors.white,
  minimumSize: const Size.fromHeight(60),
  textStyle: const TextStyle(
    fontFamily: 'Poppins',
    fontSize: 19,
    fontWeight: FontWeight.w700,
  ),
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
);

ButtonStyle flowSecondaryStyle() => OutlinedButton.styleFrom(
  foregroundColor: CureandoTheme.blue,
  minimumSize: const Size.fromHeight(56),
  side: const BorderSide(color: CureandoTheme.blue, width: 2),
  textStyle: const TextStyle(
    fontFamily: 'Poppins',
    fontSize: 18,
    fontWeight: FontWeight.w700,
  ),
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
);
