import 'dart:html' as html;

import 'package:firebase_blog_template/models/ArticleTheme.dart';
import 'package:firebase_blog_template/util/StringExtension.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flutter_html/flutter_html.dart';

import 'package:flutter_gen/gen_l10n/web_localizations.dart';
import 'package:flutter_gen/gen_l10n/web_localizations_en.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:responsive_framework/responsive_breakpoints.dart';

import '../models/Article.dart';
import '../util/PlatformExtension.dart';


class ArticleViewerDialog extends StatelessWidget {

  AppLocalizations localization = AppLocalizationsEn();
  Article article;
  ArticleTheme defaultTheme;
  Article? Function(Article current)? onGetPrevious;
  Article? Function(Article current)? onGetNext;

  double? elevation;
  Color? shadowColor;
  Color? surfaceTintColor;
  Duration insetAnimationDuration;
  Curve insetAnimationCurve;
  EdgeInsets? insetPadding;
  Clip clipBehavior;
  ShapeBorder? shape;
  AlignmentGeometry? alignment;

  final ValueNotifier<int> _updateUiCount = ValueNotifier(0);
  bool _isPhoneOrTablet = false;

  ArticleViewerDialog({
    Key? key,
    required this.localization,
    required this.article,
    required this.defaultTheme,
    this.onGetPrevious,
    this.onGetNext,
    this.elevation,
    this.shadowColor,
    this.surfaceTintColor,
    this.insetAnimationDuration = const Duration(milliseconds: 100),
    this.insetAnimationCurve = Curves.decelerate,
    this.insetPadding,
    this.clipBehavior = Clip.none,
    this.shape,
    this.alignment,
  }) : super(key: key);

  void _updateUi() {
    _updateUiCount.value++;
  }

  Widget _getArticleContentWidget(Article article, ArticleTheme theme) {
    Widget widget;
    if (article.contentType == ArticleTypes.html.name) {
      widget = Html(
        data: article.content,
        onLinkTap: (url, _, __) {
          if (url != null) {
            html.window.open(url, '');
          }
        },
      );
    } else if (article.contentType == ArticleTypes.markdown.name) {
      widget = MarkdownBody(data: article.content);
    } else { // text
      widget = Text(
        article.content,
        style: TextStyle(
          color: Color(theme.contentTextColor),
          fontSize: 18,
        ),
      );
    }
    return widget;
  }

  @override
  Widget build(BuildContext context) {
    _isPhoneOrTablet = PlatformExt.isPhoneOrTablet;
    ArticleTheme theme = article.theme ?? defaultTheme;
    double iconSize = _isPhoneOrTablet ? 20 : 24;
    MenuController menuController = MenuController();
    return ValueListenableBuilder<int>(
      valueListenable: _updateUiCount,
      builder: (context, currentState, child) {
        bool isMobile = ResponsiveBreakpoints.of(context).isMobile;
        Size size = MediaQuery.of(context).size;
        double margin = isMobile ? 20 : 40 ;
        double padding = isMobile ? 20 : 40 ;
        double width = size.width - margin*2;
        double height = size.height - margin*2;
        double barHeight = 48;
        final previousArticle = onGetPrevious?.call(article);
        final nextArticle = onGetNext?.call(article);
        return Dialog(
          backgroundColor: Color(theme.contentBgColor),
          elevation: elevation,
          shadowColor: shadowColor,
          surfaceTintColor: surfaceTintColor,
          insetAnimationDuration: insetAnimationDuration,
          insetAnimationCurve: insetAnimationCurve,
          insetPadding: insetPadding,
          clipBehavior: clipBehavior,
          shape: shape,
          alignment: alignment,
          child: Container(
            width: width,
            height: height,
            padding: EdgeInsets.zero,
            decoration: ShapeDecoration(
              color: Color(theme.contentBgColor),
              shape: shape ?? RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Column(
              children: [
                Container(
                  height: barHeight,
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: Color(theme.fgColor & 0x55FFFFFF))),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 40),
                        alignment: Alignment.center,
                        child: article.isUncopiable ? Text(
                          article.title,
                          style: TextStyle(
                            color: Color(theme.contentTextColor),
                            fontSize: 16,
                          ),
                        ) : SelectionArea(
                          child: Text(
                            article.title,
                            style: TextStyle(
                              color: Color(theme.contentTextColor),
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Material(
                            type: MaterialType.transparency,
                            shape: const CircleBorder(),
                            clipBehavior: Clip.antiAlias,
                            child: MenuAnchor(
                              controller: menuController,
                              menuChildren: [
                                MenuItemButton(
                                  child: Row(
                                    children: [
                                      const Icon(Icons.copy, size: 24, color: Colors.black),
                                      const SizedBox(width: 8),
                                      Text(localization.copyLink, style: const TextStyle(fontSize: 16, color: Colors.black)),
                                    ],
                                  ),
                                  onPressed: () {
                                    final baseUri = Uri.base;
                                    final uri = Uri(scheme: baseUri.scheme, host: baseUri.host, port: baseUri.port, path: article.path);
                                    html.window.navigator.clipboard?.writeText(uri.toString());
                                  },
                                ),
                              ],
                              child: IconButton(
                                onPressed: () {
                                  if (menuController.isOpen) {
                                    menuController.close();
                                  } else {
                                    menuController.open();
                                  }
                                },
                                icon: Icon(
                                  Icons.ios_share,
                                  size: iconSize,
                                  color: Color(theme.fgColor),
                                ),
                              ),
                            ),
                          ),
                          if (!isMobile) Material(
                            type: MaterialType.transparency,
                            shape: const CircleBorder(),
                            clipBehavior: Clip.antiAlias,
                            child: IconButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                              icon: Icon(
                                Icons.cancel_outlined,
                                size: iconSize,
                                color: Color(theme.fgColor),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Container(
                    padding: EdgeInsets.all(padding),
                    child: SingleChildScrollView(
                      child: article.isUncopiable ? _getArticleContentWidget(article, theme) : SelectionArea(
                        child: _getArticleContentWidget(article, theme),
                      ),
                    ),
                  ),
                ),
                Container(
                  height: barHeight,
                  decoration: BoxDecoration(
                    border: Border(top: BorderSide(color: Color(theme.fgColor & 0x55FFFFFF))),
                  ),
                  child: Row(
                    children: [
                      TextButton(
                        style: TextButton.styleFrom(
                          shape: const StadiumBorder(),
                          foregroundColor: Color(theme.fgColor & 0x55FFFFFF),
                        ),
                        onPressed: (previousArticle == null) ? null : () {
                          article = previousArticle;
                          _updateUi();
                        },
                        child: Row(
                          children: [
                            Icon(
                              Icons.arrow_back_ios_new,
                              size: iconSize,
                              color: Color((previousArticle != null) ? theme.fgColor : (theme.fgColor & 0x55FFFFFF)),
                            ),
                            Text(
                              localization.previous,
                              style: TextStyle(
                                  color: Color((previousArticle != null) ? theme.fgColor : (theme.fgColor & 0x55FFFFFF)),
                                  fontSize: 16
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      if (isMobile) Material(
                        type: MaterialType.transparency,
                        shape: const CircleBorder(),
                        clipBehavior: Clip.antiAlias,
                        child: IconButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          icon: Icon(
                            Icons.cancel_outlined,
                            size: iconSize,
                            color: Color(theme.fgColor),
                          ),
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        style: TextButton.styleFrom(
                          shape: const StadiumBorder(),
                          foregroundColor: Color(theme.fgColor & 0x55FFFFFF),
                        ),
                        onPressed: (nextArticle == null) ? null : () {
                          article = nextArticle;
                          _updateUi();
                        },
                        child: Row(
                          children: [
                            Text(
                              localization.next,
                              style: TextStyle(
                                  color: Color((nextArticle != null) ? theme.fgColor : (theme.fgColor & 0x55FFFFFF)),
                                  fontSize: 16
                              ),
                            ),
                            Icon(
                              Icons.arrow_forward_ios,
                              size: iconSize,
                              color: Color((nextArticle != null) ? theme.fgColor : (theme.fgColor & 0x55FFFFFF)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

}
