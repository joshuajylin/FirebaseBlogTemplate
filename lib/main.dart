import 'dart:html' as html;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_blog_template/ui/MainPage.dart';
import 'package:firebase_blog_template/ui/components/NoTransitionsBuilder.dart';
import 'package:firebase_blog_template/util/StringExtension.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:flutter_gen/gen_l10n/web_localizations.dart';
import 'package:flutter_gen/gen_l10n/web_localizations_en.dart';
import 'package:provider/provider.dart';
import 'package:firebase_blog_template/util/LocaleChangeNotifier.dart';

import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  usePathUrlStrategy();
  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (context) => LocaleChangeNotifier()),
    ],
    child: MyApp(),
  ));
}

class MyApp extends StatelessWidget {
  MyApp({super.key});
  // This widget is the root of your application.
  Widget? _mainPage;

  @override
  Widget build(BuildContext context) {
    Locale? defaultLocale;
    // NOTE: Flutter needs the format "${language_code}-${script_code}-${country_code}" for deciding language.
    if ((html.window.navigator.language == 'zh-TW' || html.window.navigator.language == 'zh-HK') &&
        (context.read<LocaleChangeNotifier>().locale == null)) {
      defaultLocale = const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant');
    }
    final textTheme = Theme.of(context).textTheme;
    return MaterialApp(
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        //useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        textTheme: GoogleFonts.robotoTextTheme(textTheme),
        pageTransitionsTheme: PageTransitionsTheme(
          builders: {
            for (final platform in TargetPlatform.values)
              platform:const NoTransitionsBuilder(),
          },
        ),
      ),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: defaultLocale,
      builder: (context, child) => ResponsiveBreakpoints.builder(
        child: child!,
        breakpoints: [
          const Breakpoint(start: 0, end: 600, name: MOBILE),
          const Breakpoint(start: 601, end: 1280, name: TABLET),
          const Breakpoint(start: 1281, end: 1920, name: DESKTOP),
          const Breakpoint(start: 1921, end: double.infinity, name: '4K'),
        ],
      ),
      initialRoute: '/',
      onGenerateRoute: (RouteSettings settings) {
        var currentRoute = ModalRoute.of(context)?.settings.name;
        var nextRoute = settings.name;
        if (nextRoute == currentRoute) {
          return null;
        }
        Widget? widget;
        switch (nextRoute) {
          case '/':
            _mainPage ??= const MainPage();
            widget = _mainPage;
          default:
            widget = _mainPage;
        }
        return (widget == null) ? null : MaterialPageRoute(builder: (BuildContext context) {
          return MaxWidthBox(
            maxWidth: double.maxFinite,
            background: Container(color: const Color(0xFFFFFFFF)),
            alignment: Alignment.center,
            child: ResponsiveScaledBox(
              width: ResponsiveValue<double>(context, conditionalValues: [
                Condition.equals(name: MOBILE, value: 450),
                //Condition.between(start: 800, end: 1100, value: 800),
                //Condition.between(start: 1000, end: 1200, value: 1000),
              ]).value,
              child: BouncingScrollWrapper.builder(
                context,
                widget!,
                //dragWithMouse: true
              ),
            ),
          );
        });
      },
      //debugShowCheckedModeBanner: false,
    );
  }
}
