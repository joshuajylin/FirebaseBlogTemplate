import 'dart:ui';

import 'package:firebase_blog_template/models/ArticleTheme.dart';
import 'package:firebase_blog_template/util/ImageAssets.dart';
import 'package:firebase_blog_template/util/StringExtension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_gen/gen_l10n/web_localizations.dart';

import '../../models/Article.dart';
import '../../util/ArticleTypesExtension.dart';

class SingleArticleListItem extends StatelessWidget {

  final AppLocalizations localization;
  final ArticleTheme theme;
  final List<Article> articles;
  final bool isAdmin;
  final void Function(BuildContext context, Article article)? onItemPressed;
  final void Function(Article article)? onEditingPressed;

  SingleArticleListItem({Key? key, required this.localization, required this.theme, required this.articles, required this.isAdmin, this.onItemPressed, this.onEditingPressed}) : super(key: key) {
    if (articles.isEmpty) {
      throw Exception('Invalid articles');
    }
  }

  @override
  Widget build(BuildContext context) {
    const double borderWidth = 5;
    const double defaultCardMargin = 4;
    final double portraitWidth = MediaQuery.of(context).size.width - (defaultCardMargin * 2);
    final double portraitHeight = portraitWidth * (6 / 4);
    const double padding = 40;
    final double textBoxWidth = portraitWidth - padding*2;
    final double textBoxHeight = portraitHeight / 3;
    final ValueNotifier<bool> isHovered = ValueNotifier(false);

    ArticleTheme articleTheme = articles.first.theme ?? theme;
    String imagePath = articleTheme.portraitCoverImage?.split('\n').last ?? 'bg-portrait-1.png';
    dynamic bgImage = imagePath.startsWith('http') ? NetworkImage(imagePath) : ImageAssets(imagePath);
    final article = articles.first;
    Widget child = Card(
      color: Color(articleTheme.bgColor),
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color: Color(articleTheme.borderColor),
          width: borderWidth,
        ),
        borderRadius: const BorderRadius.all(Radius.circular(10)),
      ),
      child: Stack(
        children: [
          Container(
            width: portraitWidth,
            height: portraitHeight,
            padding: const EdgeInsets.all(padding),
            alignment: Alignment.bottomCenter,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.all(Radius.circular(10)),
              image: DecorationImage(
                image: bgImage,
                fit: BoxFit.cover,
              ),
            ),
            child: ClipRRect(
              borderRadius: const BorderRadius.all(Radius.circular(10)),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                child: InkResponse(
                  onTapUp: article.content.isEmpty ? null : (details) {
                    onItemPressed?.call(context, article);
                  },
                  onHover: article.content.isEmpty ? null : (value) {
                    isHovered.value = value;
                  },
                  child: ValueListenableBuilder<bool>(
                    valueListenable: isHovered,
                    builder: (context, currentState, child) {
                      return Container(
                        width: textBoxWidth,
                        height: textBoxHeight,
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.all(Radius.circular(10)),
                          color: currentState ? Color(articleTheme.summaryBoxHoverColor) : Color(articleTheme.summaryBoxColor),
                        ),
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(20),
                          child: ArticleTypesExt.fromName(article.summaryType).getWidget(context, article.summary, textColor: Color(articleTheme.summaryTextColor)),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
          if (isAdmin) Row(
            children: [
              if (!article.isPublished) Container(
                height: 32,
                margin: const EdgeInsets.only(top: 5, left: 5),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                alignment: Alignment.center,
                decoration: ShapeDecoration(
                  color: Colors.orange,
                  shape: StadiumBorder(side: BorderSide(color: Color(articleTheme.fgColor))),
                ),
                child: Text(
                  localization.unpublished,
                  style: TextStyle(fontSize: 14, color: Color(articleTheme.fgColor)),
                ),
              ),
              const Spacer(),
              Container(
                width: 32,
                height: 32,
                margin: const EdgeInsets.only(top: 5, right: 5),
                decoration: ShapeDecoration(
                  color: Color(articleTheme.fgColor),
                  shape: const CircleBorder(),
                ),
                child: Material(
                  type: MaterialType.transparency,
                  shape: const CircleBorder(),
                  clipBehavior: Clip.antiAlias,
                  child: IconButton(
                    onPressed: () {
                      if (onEditingPressed != null) {
                        onEditingPressed!(article);
                      }
                    },
                    color: Color(articleTheme.bgColor),
                    iconSize: 16,
                    icon: const Icon(Icons.edit),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
    return article.isUncopiable ? child : SelectionArea(child: child);
  }

}