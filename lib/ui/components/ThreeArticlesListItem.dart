import 'dart:ui';

import 'package:firebase_blog_template/util/ImageAssets.dart';
import 'package:firebase_blog_template/util/StringExtension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_gen/gen_l10n/web_localizations.dart';

import '../../models/Article.dart';
import '../../models/ArticleTheme.dart';
import '../../util/ArticleTypesExtension.dart';

enum ThreeArticlesLayoutTypes {
  threePortraits,
  leftPortraitRightLandscapes,
  rightPortraitLeftLandscapes,
}

class ThreeArticlesListItem extends StatelessWidget {

  final AppLocalizations localization;
  final ArticleTheme theme;
  final List<Article> articles;
  final ThreeArticlesLayoutTypes type;
  final bool isAdmin;
  final void Function(BuildContext context, Article article)? onItemPressed;
  final void Function(Article article)? onEditingPressed;

  ThreeArticlesListItem({Key? key, required this.localization, required this.theme, required this.articles, this.type = ThreeArticlesLayoutTypes.threePortraits, required this.isAdmin, this.onItemPressed, this.onEditingPressed}) : super(key: key) {
    if (articles.isEmpty) {
      throw Exception('Invalid articles');
    }
  }

  Widget _getThreePortraitsWidget(BuildContext context, BoxConstraints constraints) {
    const double gap = 8;
    const double borderWidth = 5;
    const double defaultCardMargin = 4;
    final double portraitWidth = (constraints.maxWidth - (gap * 2) - (defaultCardMargin * 2 * 3)) / 3;
    final double portraitHeight = portraitWidth * (6 / 4);
    const double padding = 40;
    final double textBoxWidth = portraitWidth - padding*2;
    final double textBoxHeight = portraitHeight / 3;

    final List<Widget> cards = articles.map<Widget>((e) {
      final article = e;
      final index = articles.indexOf(article);
      const List<Alignment> alignments = [Alignment.bottomCenter, Alignment.center, Alignment.topCenter];
      final ValueNotifier<bool> isHovered = ValueNotifier(false);
      final articleTheme = article.theme ?? theme;
      String imagePath = articleTheme.portraitCoverImage?.split('\n').last ?? 'bg-portrait-1.png';
      dynamic bgImage = imagePath.startsWith('http') ? NetworkImage(imagePath) : ImageAssets(imagePath);
      Widget card = Card(
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
              alignment: alignments[index % alignments.length],
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
            if (isAdmin) SizedBox(
              width: portraitWidth,
              child: Row(
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
            ),
          ],
        ),
      );
      return article.isUncopiable ? card : SelectionArea(child: card);
    }).toList();

    final emptyCard = Card(
      color: Color(theme.bgColor),
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color: Color(theme.borderColor),
          width: borderWidth,
        ),
        borderRadius: const BorderRadius.all(Radius.circular(10)),
      ),
      child: Container(
        width: portraitWidth,
        height: portraitHeight,
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.all(Radius.circular(10)),
          image: DecorationImage(
            image: ImageAssets(theme.portraitCoverImage?.split('\n').last ?? 'bg-portrait-1.png'),
            fit: BoxFit.cover,
          ),
        ),
      ),
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        cards[0],
        const Spacer(),
        (cards.length > 1) ? cards[1] : emptyCard,
        const Spacer(),
        (cards.length > 2) ? cards[2] : emptyCard,
      ],
    );
  }

  Widget _getOnePortraitTwoLandscapesWidget(BuildContext context, BoxConstraints constraints, bool isPortraitOnLeft) {
    const double gap = 8;
    const double borderWidth = 5;
    const double defaultCardMargin = 4;
    final double portraitWidth = (constraints.maxWidth - (gap * 2) - (defaultCardMargin * 2 * 3)) / 3;
    final double portraitHeight = portraitWidth * (6 / 4);
    //final double landscapeWidth = (portraitWidth * 2) + gap + (defaultCardMargin * 2 * 2);
    final double landscapeHeight = (portraitHeight - gap - (defaultCardMargin * 2 * 2)) / 2;
    const double padding = 40;
    final double textBoxWidth = portraitWidth - padding*2;
    final double textBoxHeight = portraitHeight / 3;
    final List<ValueNotifier<bool>> hoverStates = [ValueNotifier(false), ValueNotifier(false), ValueNotifier(false)];

    final List<Widget> cards = articles.map<Widget>((e) {
      final article = e;
      final index = articles.indexOf(article);
      final articleTheme = article.theme ?? theme;
      String portraitImagePath = articleTheme.portraitCoverImage?.split('\n').last ?? 'bg-portrait-1.png';
      String landscapeImagePath = articleTheme.landscapeCoverImage?.split('\n').last ?? 'bg-landscape-1.png';
      dynamic portraitBgImage = portraitImagePath.startsWith('http') ? NetworkImage(portraitImagePath) : ImageAssets(portraitImagePath);
      dynamic landscapeBgImage = landscapeImagePath.startsWith('http') ? NetworkImage(landscapeImagePath) : ImageAssets(landscapeImagePath);
      final portraitCard = Card(
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
                  image: portraitBgImage,
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
                      hoverStates[index].value = value;
                    },
                    child: ValueListenableBuilder<bool>(
                      valueListenable: hoverStates[index],
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
            if (isAdmin) SizedBox(
              width: portraitWidth,
              child: Row(
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
            ),
          ],
        ),
      );
      final portraitWidget = article.isUncopiable ? portraitCard : SelectionArea(child: portraitCard);
      final landscapeCard = Card(
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
              height: landscapeHeight,
              padding: const EdgeInsets.all(padding),
              alignment: isPortraitOnLeft ? Alignment.centerRight : Alignment.centerLeft,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.all(Radius.circular(10)),
                image: DecorationImage(
                  image: landscapeBgImage,
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
                      hoverStates[index].value = value;
                    },
                    child: ValueListenableBuilder<bool>(
                      valueListenable: hoverStates[index],
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
      final landscapeWidget = article.isUncopiable ? landscapeCard : SelectionArea(child: landscapeCard);
      if (isPortraitOnLeft) {
        return (index == 0) ? portraitWidget : landscapeWidget;
      } else {
        return (index == 2) ? portraitWidget : landscapeWidget;
      }
    }).toList();

    final emptyPortraitWidget = Card(
      color: Color(theme.bgColor),
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color: Color(theme.borderColor),
          width: borderWidth,
        ),
        borderRadius: const BorderRadius.all(Radius.circular(10)),
      ),
      child: Container(
        width: portraitWidth,
        height: portraitHeight,
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.all(Radius.circular(10)),
          image: DecorationImage(
            image: ImageAssets(theme.portraitCoverImage?.split('\n').last ?? 'bg-portrait-1.png'),
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
    final emptyLandscapeWidget = Card(
      color: Color(theme.bgColor),
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color: Color(theme.borderColor),
          width: borderWidth,
        ),
        borderRadius: const BorderRadius.all(Radius.circular(10)),
      ),
      child: Container(
        height: landscapeHeight,
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.all(Radius.circular(10)),
          image: DecorationImage(
            image: ImageAssets(theme.landscapeCoverImage?.split('\n').last ?? 'bg-landscape-1.png'),
            fit: BoxFit.cover,
          ),
        ),
      ),
    );

    final leftWidget = isPortraitOnLeft ? cards[0] : Expanded(
      child: Column(
        children: [
          cards[0],
          const Spacer(),
          (cards.length > 1) ? cards[1] : emptyLandscapeWidget,
        ],
      ),
    );
    final rightWidget = isPortraitOnLeft ? Expanded(
      child: Column(
        children: [
          (cards.length > 1) ? cards[1] : emptyLandscapeWidget,
          const Spacer(),
          (cards.length > 2) ? cards[2] : emptyLandscapeWidget,
        ],
      ),
    ) : ((cards.length > 2) ? cards[2] : emptyPortraitWidget);
    return SizedBox(
      width: constraints.maxWidth,
      height: portraitHeight,
      child: Row(
        children: [
          leftWidget,
          const SizedBox(width: gap),
          rightWidget,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: switch (type) {
            ThreeArticlesLayoutTypes.threePortraits => _getThreePortraitsWidget(context, constraints),
            ThreeArticlesLayoutTypes.leftPortraitRightLandscapes => _getOnePortraitTwoLandscapesWidget(context, constraints, true),
            ThreeArticlesLayoutTypes.rightPortraitLeftLandscapes => _getOnePortraitTwoLandscapesWidget(context, constraints, false),
          },
        );
      },
    );
  }

}