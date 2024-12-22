import 'dart:html' as html;
import 'dart:math';
import 'dart:ui';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:custom_pop_up_menu/custom_pop_up_menu.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_blog_template/firebase/ArticlesDB.dart';
import 'package:firebase_blog_template/firebase/ThemesDB.dart';
import 'package:firebase_blog_template/models/ToolbarTheme.dart';
import 'package:firebase_blog_template/ui/ArticleViewerDialog.dart';
import 'package:firebase_blog_template/ui/components/SingleArticleListItem.dart';
import 'package:firebase_blog_template/util/DateTimeExtension.dart';
import 'package:firebase_blog_template/util/StringExtension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/web_localizations.dart';
import 'package:flutter_gen/gen_l10n/web_localizations_en.dart';
import 'package:firebase_blog_template/util/LocaleChangeNotifier.dart';
import 'package:responsive_framework/responsive_framework.dart';

import '../firebase/ProfileDB.dart';
import '../firebase/SettingsDB.dart';
import '../firebase/UserAccount.dart';
import '../models/Article.dart';
import '../models/UserAccountInfo.dart';
import '../models/WebsiteSettings.dart';
import '../models/WebsiteTheme.dart';
import '../util/ImageAssets.dart';
import '../util/ArticleTypesExtension.dart';
import '../util/PlatformExtension.dart';
import 'ArticleEditorDialog.dart';
import 'ProfileEditorDialog.dart';
import 'SettingsDialog.dart';
import 'components/ThreeArticlesListItem.dart';
import 'components/TwoArticlesListItem.dart';

enum PopupMenuItems {
  login,
  logout,
  settings,
  newArticle,
}

class MainPage extends StatefulWidget {
  const MainPage({Key? key}) : super(key: key);

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> with WidgetsBindingObserver {
  final _listViewKey = GlobalKey();
  final _appBarKey = GlobalKey();
  final _appBarAnchorKey = GlobalKey();
  final ScrollController _scrollController = ScrollController();
  final ValueNotifier<bool> _isAppBarOnTop = ValueNotifier(false);
  final CustomPopupMenuController _popupMenuController = CustomPopupMenuController();
  final TextEditingController _searchController = TextEditingController();
  final ValueNotifier<bool> _isSearchEmpty = ValueNotifier(true);
  final FocusNode _searchFocusNode = FocusNode();

  AppLocalizations _localization = AppLocalizationsEn();
  WebsiteSettings? _websiteSettings;
  WebsiteTheme? _websiteTheme;
  UserAccountInfo? _accountInfo;
  Article? _aboutMe;
  Article? _introduction;
  List<Article> _unpublishedArticles = [];
  List<Article> _allArticles = [];
  List<Article> _articles = [];
  List<String> _tags = [];
  String? _selectedTag;
  bool get _isInitDone => (_websiteSettings != null && _websiteTheme != null && _aboutMe != null && _introduction != null);
  
  bool _isMobile = false;
  bool _isPhoneOrTablet = false;
  bool? _isAdult;

  late Article _defaultAboutMe;
  late Article _defaultIntroduction;

  void _updateUi(void Function() fn) {
    if (mounted) {
      setState(fn);
    }
  }

  void _updateTheme() {
    final themeName = _websiteSettings!.theme;
    ThemesDB.instance.getTheme(themeName).then((value) {
      _websiteTheme = value;
    }).catchError((err) {
      '$err'.log();
      _websiteTheme = WebsiteTheme.defaultTheme;
    }).whenComplete(() => _updateUi(() { }));
  }

  void _updateArticle(Article oldArticle, Article? newArticle) {
    int index = _articles.indexOf(oldArticle);
    if (index >= 0) {
      if (newArticle == null) {
        _articles.removeAt(index);
      } else {
        _articles[index] = newArticle;
      }
    }
    index = _allArticles.indexOf(oldArticle);
    if (index >= 0) {
      if (newArticle == null) {
        _allArticles.removeAt(index);
      } else {
        _allArticles[index] = newArticle;
      }
    }
    index = _unpublishedArticles.indexOf(oldArticle);
    if (index >= 0) {
      if (newArticle == null) {
        _unpublishedArticles.removeAt(index);
      } else {
        _unpublishedArticles[index] = newArticle;
      }
    }
    _updateTags(_allArticles);
  }

  void _updateTags(List<Article> articles) {
    List<String> tags = [];
    for (var article in articles) {
      for (var element in article.tags) {
        if (!tags.contains(element)) {
          tags.add(element);
        }
      }
    }
    tags.sort();
    _tags = tags;
  }

  List<Article> _searchArticles({required String keyword}) {
    List<Article> articles = _allArticles.where((article) => (article.summary.contains(keyword) || article.content.contains(keyword))).toList();
    if (_accountInfo?.isAdmin == true) {
      _articles.insertAll(0, _unpublishedArticles.where((article) => (article.summary.contains(keyword) || article.content.contains(keyword))).toList());
    }
    return articles;
  }

  void _login() {
    UserAccount.instance.login().then((info) {
      // NOTE: login will redirect to IdP's website then redirect back, so code will never get here.
      _accountInfo = info;
      _updateUi(() {});
    }).catchError((err) {
      '$err'.log();
    });
  }

  void _logout() {
    UserAccount.instance.logout();
    _accountInfo = null;
    _updateUi(() {});
  }

  void _showSettings() {
    if (_websiteSettings != null) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return SettingsDialog(
            localization: _localization,
            settings: _websiteSettings!,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            onFinish: (settings) {
              _websiteSettings = settings;
              _updateTheme();
            },
          );
        },
      );
    }
  }

  void _showProfileEditor({Article? article, void Function(Article?)? onFinish}) {
    final theme = _websiteTheme?.articleTheme;
    if (theme == null) {
      return;
    }
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return ProfileEditorDialog(
          localization: _localization,
          defaultTheme: theme,
          article: article,
          onFinish: onFinish,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        );
      },
    );
  }

  void _showArticleEditor({Article? article, bool isDeletable = true, void Function(Article?)? onFinish}) {
    final theme = _websiteTheme?.articleTheme;
    if (theme == null) {
      return;
    }
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return ArticleEditorDialog(
          localization: _localization,
          defaultTheme: theme,
          article: article,
          isDeletable: isDeletable,
          onFinish: onFinish,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        );
      },
    );
  }

  void _showNewArticleEditor() {
    _showArticleEditor(onFinish: (article) {
      if (article != null) {
        _allArticles.insert(0, article);
        _updateTags(_allArticles);
        _updateUi(() { });
      }
    });
  }

  PreferredSizeWidget _getAppBar({Key? key, required ToolbarTheme theme, bool isOnTop = false, double hMargin = 0}) {
    double barHeight = _isPhoneOrTablet ? 56 : 48;
    double margin = 5;
    double padding = 8;
    double widgetWidth = _isMobile ? 170 : 220;
    double iconSize = _isPhoneOrTablet ? 20 : 24;

    final tags = [''];
    tags.addAll(_tags);

    List<PopupMenuItems> menuItems = [PopupMenuItems.login];
    if (UserAccount.instance.isLoggedIn) {
      menuItems = [PopupMenuItems.logout];
      if (_accountInfo?.isAdmin ?? false) {
        menuItems.insertAll(0, [PopupMenuItems.newArticle, PopupMenuItems.settings]);
      }
    }
    final menuTextStyle = TextStyle(
      fontSize: 16,
      color: Color(theme.textColor),
    );
    var menuItemWidth = menuItems.map((e) {
      final width = e.toLocalizedString(_localization).calculateTextSize(context: context, style: menuTextStyle).width;
      return width;
    }).reduce(max) + 16*2 + iconSize + 16;
    var menuItemHeight = 48.0 * menuItems.length;
    if (_isPhoneOrTablet) {
      menuItemWidth += 8;
      menuItemHeight += 8 * menuItems.length;
    }

    return PreferredSize(
      key: key,
      preferredSize: Size(double.maxFinite, barHeight + padding * 2),
      child: Container(
        height: barHeight,
        margin: EdgeInsets.symmetric(vertical: margin, horizontal: isOnTop ? hMargin : 0),
        padding: EdgeInsets.symmetric(vertical: padding, horizontal: padding),
        decoration: ShapeDecoration(
          color: Color(theme.barColor),
          shape: const StadiumBorder(),
          //shape: StadiumBorder(side: BorderSide(color: Color(theme.borderColor), width: 1)),
          //shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (_tags.isNotEmpty) Container(
              width: widgetWidth,
              decoration: ShapeDecoration(
                color: Color(theme.bgColor),
                shape: StadiumBorder(
                  side: BorderSide(color: Color(theme.borderColor), width: 1),
                ),
              ),
              child: DropdownButton<String>(
                value: _selectedTag,
                style: TextStyle(color: Color(theme.textColor), fontSize: 16, overflow: TextOverflow.ellipsis),
                alignment: AlignmentDirectional.center,
                dropdownColor: Color(theme.bgColor),
                focusColor: Colors.transparent,
                iconSize: iconSize,
                hint: Container(
                  width: widgetWidth - iconSize - 2,
                  padding: const EdgeInsets.only(left: 8),
                  child: Text(_localization.tags, textAlign: TextAlign.center, maxLines: 1, style: TextStyle(color: Color(theme.textColor))),
                ),
                iconEnabledColor: Color(theme.iconColor),
                borderRadius: BorderRadius.circular(10),
                underline: Container(),
                items: tags.map<DropdownMenuItem<String>>((e) => DropdownMenuItem(
                  value: e,
                  child: Container(
                    width: widgetWidth - iconSize - 2,
                    padding: EdgeInsets.only(left: iconSize + 2),
                    child: Text(e, textAlign: TextAlign.left, maxLines: 1),
                  ),
                )).toList(),
                onChanged: (value) {
                  if (value == null) {
                    return;
                  }
                  _selectedTag = value;
                  if (value.isEmpty) {
                    _selectedTag = null;
                    _articles = _allArticles;
                    if (_accountInfo?.isAdmin == true) {
                      _articles.insertAll(0, _unpublishedArticles);
                    }
                  } else {
                    _articles = _allArticles.where((article) => article.tags.contains(_selectedTag)).toList();
                    if (_accountInfo?.isAdmin == true) {
                      _articles.insertAll(0, _unpublishedArticles.where((article) => article.tags.contains(_selectedTag)).toList());
                    }
                  }
                  _updateUi((){});
                },
              ),
            ),
            Container(
              width: barHeight - padding*2,
              height: barHeight - padding*2,
              decoration: ShapeDecoration(
                color: Color(theme.bgColor),
                shape: CircleBorder(side: BorderSide(color: Color(theme.borderColor), width: 1)),
              ),
              child: CustomPopupMenu(
                controller: _popupMenuController,
                menuBuilder: () {
                  return Container(
                    width: menuItemWidth,
                    height: menuItemHeight,
                    decoration: BoxDecoration(
                      color: Color(theme.bgColor),
                      borderRadius: const BorderRadius.all(Radius.circular(10)),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: ListView.builder(
                      itemCount: menuItems.length,
                      itemBuilder: (context, index) {
                        final item = menuItems[index];
                        return Material(
                          type: MaterialType.transparency,
                          child: ListTile(
                            leading: Icon(item.icon, size: iconSize, color: Color(theme.iconColor)),
                            minLeadingWidth: iconSize,
                            title: Text(item.toLocalizedString(_localization), style: menuTextStyle),
                            hoverColor: Color((~theme.bgColor & 0x00FFFFFFFF) | 0x36000000),
                            onTap: () {
                              switch (item) {
                                case PopupMenuItems.login:
                                  _login();
                                case PopupMenuItems.settings:
                                  _showSettings();
                                case PopupMenuItems.logout:
                                  _logout();
                                case PopupMenuItems.newArticle:
                                  _showNewArticleEditor();
                              }
                              _popupMenuController.hideMenu();
                            },
                          ),
                        );
                      },
                    ),
                  );
                },
                barrierColor: Colors.transparent,
                pressType: PressType.singleClick,
                arrowColor: Color(theme.bgColor),
                child: ClipRRect(
                  borderRadius: BorderRadius.all(Radius.circular(barHeight/2)),
                  child: (_accountInfo?.photo?.isNotEmpty ?? false) ? Image.memory(
                    _accountInfo!.photo!,
                    fit: BoxFit.cover,
                  ) : Icon(
                    Icons.person_outline,
                    size: iconSize,
                    color: Color(theme.iconColor),
                  ),
                ),
              ),
            ),
            SizedBox(
              width: widgetWidth,
              child: TextFormField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                autofocus: false,
                enableIMEPersonalizedLearning: true,
                cursorColor: Color(theme.textColor),
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 15),
                  hintStyle: TextStyle(color: Color(theme.textColor)),
                  border: OutlineInputBorder(borderSide: BorderSide(color: Color(theme.borderColor), width: 1), borderRadius: BorderRadius.circular(barHeight - padding * 2)),
                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(theme.borderColor), width: 1), borderRadius: BorderRadius.circular(barHeight - padding * 2)),
                  focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(theme.borderColor), width: 1), borderRadius: BorderRadius.circular(barHeight - padding * 2)),
                  disabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(theme.borderColor), width: 1), borderRadius: BorderRadius.circular(barHeight - padding * 2)),
                  fillColor: Color(theme.bgColor),
                  filled: true,
                  prefixIcon:  Icon(Icons.search, size: iconSize, color: Color(theme.iconColor)),
                  suffixIcon: ValueListenableBuilder<bool>(
                    valueListenable: _isSearchEmpty,
                    builder: (context, currentState, child) {
                      return currentState ? const SizedBox(width: 0, height: 0) : Material(
                        type: MaterialType.transparency,
                        shape: const CircleBorder(),
                        clipBehavior: Clip.antiAlias,
                        child: IconButton(
                          alignment: Alignment.center,
                          padding: EdgeInsets.zero,
                          icon: Icon(Icons.cancel_outlined, size: iconSize, color: Color(theme.iconColor)),
                          onPressed: () {
                            _searchController.clear();
                            _isSearchEmpty.value = true;
                            if (!_searchFocusNode.hasFocus) {
                              _articles = _allArticles;
                              _updateUi(() { });
                            }
                          },
                        ),
                      );
                    },
                  ),
                ),
                style: TextStyle(fontSize: 16, color: Color(theme.textColor)),
                onChanged: (value) {
                  _isSearchEmpty.value = value.isEmpty;
                },
                onTapOutside: (event) {
                  if (_searchFocusNode.hasFocus) {
                    FocusScope.of(context).requestFocus(FocusNode());
                    _articles = _searchArticles(keyword: _searchController.text);
                    _updateUi(() { });
                  }
                },
                onFieldSubmitted: (value) {
                  final keyword = value;
                  FocusScope.of(context).requestFocus(FocusNode());
                  _articles = _searchArticles(keyword: keyword);
                  _updateUi(() { });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _getProfileWidget({required Article aboutMe, required Article introduction, required WebsiteTheme theme}) {
    bool isMobile = ResponsiveBreakpoints.of(context).isMobile;
    bool isTablet = false;
    double picAreaWidth;
    double padding;
    double gap;
    bool isLargerOrEqualToDesktop = ResponsiveBreakpoints.of(context).largerOrEqualTo(DESKTOP);
    if (isLargerOrEqualToDesktop) {
      picAreaWidth = 400;
      padding = 40;
      gap = 15;
    } else if (isMobile) { // MOBILE
      picAreaWidth = MediaQuery.of(context).size.width / 2;
      padding = 20;
      gap = 0;
    } else { // TABLET
      isTablet = true;
      picAreaWidth = 300;
      padding = 20;
      gap = 0;
    }
    double width = MediaQuery.of(context).size.width;
    if (!isMobile && (picAreaWidth > (width / 3))) {
      picAreaWidth = width / 3;
    }
    double height = picAreaWidth * (6/4);
    double picWidth = picAreaWidth - (padding * 2);
    double picHeight = height - (padding * (isMobile ? 1.5 : 2));
    double nameBoxHeight = picHeight / 7;
    final ValueNotifier<bool> isNameBoxHovered = ValueNotifier(false);
    final ValueNotifier<bool> isDescriptionBoxHovered = ValueNotifier(false);

    if (!aboutMe.isPublished && (_accountInfo?.isAdmin != true)) {
      aboutMe = _defaultAboutMe;
    }
    final aboutMeTheme = aboutMe.theme ?? theme.articleTheme;
    String imagePath = aboutMeTheme.coverImage?.split('\n').last ?? 'avatar-1.png';
    dynamic portraitImage = imagePath.startsWith('http') ? NetworkImage(imagePath) : ImageAssets(imagePath);
    Widget pWidget = Container(
      width: picAreaWidth,
      height: height,
      decoration: isLargerOrEqualToDesktop ? BoxDecoration(
        color: Color(aboutMeTheme.bgColor),
        borderRadius: const BorderRadius.all(Radius.circular(10)),
        border: Border.all(
          color: Color(aboutMeTheme.borderColor),
          width: 5,
        ),
      ) : null,
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.all(Radius.circular(10)),
            child: Container(
              width: picAreaWidth,
              height: height,
              padding: isLargerOrEqualToDesktop ? EdgeInsets.all(padding) : EdgeInsets.only(left: padding, right: isMobile ? padding : padding/2, top: isMobile ? padding/2 : padding, bottom: isMobile ? padding/2 : padding),
              decoration: isLargerOrEqualToDesktop ? BoxDecoration(
                image: DecorationImage(
                  image: portraitImage,
                  fit: BoxFit.cover,
                ),
              ) : null,
              child: BackdropFilter(
                filter: isLargerOrEqualToDesktop ? ImageFilter.blur(sigmaX: 5, sigmaY: 5) : ImageFilter.blur(sigmaX: 0, sigmaY: 0),
                child: Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    Container(
                      width: picWidth,
                      height: picHeight,
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.all(Radius.circular(10)),
                        image: DecorationImage(
                          image: portraitImage,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.all(10),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(nameBoxHeight),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                          child: InkResponse(
                            onTapUp: aboutMe.content.isEmpty ? null : (details) {
                              showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder: (context) {
                                  return ArticleViewerDialog(
                                    localization: _localization,
                                    article: aboutMe,
                                    defaultTheme: aboutMeTheme,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    onGetPrevious: (current) => (current == aboutMe) ? null : aboutMe,
                                    onGetNext: (current) => (current == aboutMe) ? introduction : null,
                                  );
                                },
                              );
                            },
                            onHover: (value) {
                              isNameBoxHovered.value = value;
                            },
                            child: ValueListenableBuilder<bool>(
                              valueListenable: isNameBoxHovered,
                              builder: (context, currentState, child) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 24),
                                  decoration: ShapeDecoration(
                                    shape: const StadiumBorder(),
                                    //shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
                                    color: Color(currentState ? aboutMeTheme.summaryBoxHoverColor : aboutMeTheme.summaryBoxColor),
                                  ),
                                  child: AutoSizeText(
                                    aboutMe.title,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      height: 1.5,
                                      fontSize: 20,
                                      color: Color(aboutMeTheme.summaryTextColor),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_accountInfo?.isAdmin == true) Row(
            children: [
              if (!aboutMe.isPublished) Container(
                height: 32,
                margin: isLargerOrEqualToDesktop ? null : EdgeInsets.only(top: 25, left: isMobile ? 25 : 30),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                alignment: Alignment.center,
                decoration: ShapeDecoration(
                  color: Colors.orange,
                  shape: StadiumBorder(side: BorderSide(color: Color(aboutMeTheme.fgColor))),
                ),
                child: Text(
                  _localization.unpublished,
                  style: TextStyle(fontSize: 14, color: Color(aboutMeTheme.fgColor)),
                ),
              ),
              const Spacer(),
              Container(
                width: 32,
                height: 32,
                margin: isLargerOrEqualToDesktop ? null : EdgeInsets.only(top: 25, right: isMobile ? 25 : 20),
                decoration: ShapeDecoration(
                  color: Color(aboutMeTheme.fgColor),
                  shape: const CircleBorder(),
                ),
                child: Material(
                  type: MaterialType.transparency,
                  shape: const CircleBorder(),
                  clipBehavior: Clip.antiAlias,
                  child: IconButton(
                    onPressed: () {
                      _showProfileEditor(article: aboutMe, onFinish: (article) {
                        if (article != null) {
                          _aboutMe = article;
                          _updateUi(() { });
                        }
                      });
                    },
                    color: Color(aboutMeTheme.bgColor),
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
    Widget pictureWidget = aboutMe.isUncopiable ? pWidget : SelectionArea(child: pWidget);

    if (!introduction.isPublished && (_accountInfo?.isAdmin != true)) {
      introduction = _defaultIntroduction;
    }
    final introductionTheme = introduction.theme ?? theme.articleTheme;
    imagePath = introductionTheme.landscapeCoverImage?.split('\n').last ?? 'bg-landscape-1.png';
    dynamic bgImage = imagePath.startsWith('http') ? NetworkImage(imagePath) : ImageAssets(imagePath);
    Widget iWidget = Stack(
      children: [
        Container(
          width: isMobile ? width : null,
          height: height,
          padding: isLargerOrEqualToDesktop ? EdgeInsets.all(padding) : EdgeInsets.only(left: isMobile ? padding : padding/2, right: padding, top: isMobile ? padding/2 : padding, bottom: padding),
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.all(Radius.circular(10)),
            border: isLargerOrEqualToDesktop ? Border.all(color: Color(introductionTheme.borderColor), width: 5) : null,
            color: isLargerOrEqualToDesktop ? Color(introductionTheme.borderColor) : Colors.transparent,
            image: isLargerOrEqualToDesktop ? DecorationImage(image: bgImage, fit: BoxFit.cover) : null,
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.all(Radius.circular(10)),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: InkResponse(
                onTapUp: introduction.content.isEmpty ? null : (details) {
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) {
                      return ArticleViewerDialog(
                        localization: _localization,
                        article: introduction,
                        defaultTheme: introductionTheme,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        onGetPrevious: (current) => (current == aboutMe) ? null : aboutMe,
                        onGetNext: (current) => (current == aboutMe) ? introduction : null,
                      );
                    },
                  );
                },
                onHover: (value) {
                  isDescriptionBoxHovered.value = value;
                },
                child: ValueListenableBuilder<bool>(
                  valueListenable: isDescriptionBoxHovered,
                  builder: (context, currentState, child) {
                    return Container(
                      width: double.maxFinite,
                      //height: height,
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.all(Radius.circular(10)),
                        color: currentState ? Color(introductionTheme.summaryBoxHoverColor) : Color(introductionTheme.summaryBoxColor),
                      ),
                      child: SingleChildScrollView(
                        padding: EdgeInsets.all(padding),
                        child: ArticleTypesExt.fromName(introduction.summaryType).getWidget(context, introduction.summary, textColor: Color(introductionTheme.summaryTextColor)),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
        if (_accountInfo?.isAdmin == true) Row(
          children: [
            if (!introduction.isPublished) Container(
              height: 32,
              margin: isTablet ? const EdgeInsets.only(top: 25, left: 15) : EdgeInsets.only(top: isMobile ? 15 : 5, left: isMobile ? 25 : 5),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.center,
              decoration: ShapeDecoration(
                color: Colors.orange,
                shape: StadiumBorder(side: BorderSide(color: Color(introductionTheme.fgColor))),
              ),
              child: Text(
                _localization.unpublished,
                style: TextStyle(fontSize: 14, color: Color(introductionTheme.fgColor)),
              ),
            ),
            const Spacer(),
            Container(
              width: 32,
              height: 32,
              margin: isTablet ? const EdgeInsets.only(top: 25, right: 25) : EdgeInsets.only(top: isMobile ? 15 : 5, right: isMobile ? 25 : 5),
              decoration: ShapeDecoration(
                color: Color(introductionTheme.fgColor),
                shape: const CircleBorder(),
              ),
              child: Material(
                type: MaterialType.transparency,
                shape: const CircleBorder(),
                clipBehavior: Clip.antiAlias,
                child: IconButton(
                  onPressed: () {
                    _showArticleEditor(article: introduction, isDeletable: false, onFinish: (article) {
                      if (article != null) {
                        _introduction = article;
                        _updateUi(() { });
                      }
                    });
                  },
                  color: Color(introductionTheme.bgColor),
                  iconSize: 16,
                  icon: const Icon(Icons.edit),
                ),
              ),
            ),
          ],
        ),
      ],
    );
    Widget introductionWidget = introduction.isUncopiable ? iWidget : SelectionArea(child: iWidget);

    return Column(
      children: [
        Card(
          color: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: isLargerOrEqualToDesktop ? null : RoundedRectangleBorder(
            side: BorderSide(
              color: Color(introductionTheme.borderColor),
              width: 5,
            ),
            borderRadius: const BorderRadius.all(Radius.circular(10)),
          ),
          child: Container(
            decoration: isLargerOrEqualToDesktop ? null : BoxDecoration(
              borderRadius: const BorderRadius.all(Radius.circular(10)),
              border: Border.all(color: Color(introductionTheme.borderColor), width: 5),
              image: DecorationImage(image: bgImage, fit: BoxFit.cover),
            ),
            child: ResponsiveRowColumn(
              layout: isMobile ? ResponsiveRowColumnType.COLUMN : ResponsiveRowColumnType.ROW,
              children: [
                ResponsiveRowColumnItem(child: pictureWidget),
                if (isLargerOrEqualToDesktop) ResponsiveRowColumnItem(child: SizedBox(width: gap, height: gap)),
                ResponsiveRowColumnItem(child: isMobile ? introductionWidget : Expanded(child: introductionWidget)),
              ],
            ),
          ),
        ),
        SizedBox(height: isLargerOrEqualToDesktop ? 8 : 4),
        ValueListenableBuilder(
          valueListenable: _isAppBarOnTop,
          builder: (context, currentState, child) {
            final renderBox = _appBarKey.currentContext?.findRenderObject() as RenderBox?;
            return currentState ? SizedBox(
              key: _appBarAnchorKey,
              height: renderBox?.size.height,
            ) : _getAppBar(key: _appBarKey, theme: theme.toolbarTheme);
          },
        ),
      ],
    );
  }

  void _onArticlePressed(BuildContext context, Article article) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return ArticleViewerDialog(
          localization: _localization,
          article: article,
          defaultTheme: _websiteTheme!.articleTheme,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          onGetPrevious: (current) {
            Article? article;
            int index = _articles.indexOf(current);
            while (article == null && index > 0) {
              if (_articles[index - 1].content.isNotEmpty) {
                article = _articles[index - 1];
              }
              index --;
            }
            return article;
          },
          onGetNext: (current) {
            Article? article;
            int index = _articles.indexOf(current);
            while (article == null && index >= 0 && index < (_articles.length - 1)) {
              if (_articles[index + 1].content.isNotEmpty) {
                article = _articles[index + 1];
              }
              index++;
            }
            return article;
          },
        );
      },
    );
  }

  void _handleUri() {
    final baseUri = Uri.base;
    try {
      final article = _allArticles.firstWhere((element) => baseUri.path.contains(element.path ?? ''), orElse: () {
        if (baseUri.path.contains(_aboutMe?.path ?? '')) {
          return _aboutMe!;
        } else if (baseUri.path.contains(_introduction?.path ?? '')) {
          return _introduction!;
        } else {
          throw Exception('Not found');
        }
      });
      Future.delayed(const Duration(milliseconds: 500), () => showDialog(
        context: context,
        builder: (context) {
          return ArticleViewerDialog(
            localization: _localization,
            article: article,
            defaultTheme: _websiteTheme!.articleTheme,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            onGetPrevious: null,
            onGetNext: null,
          );
        },
      ));
    } catch (err) {
      // do nothing
    } finally {
      html.window.history.replaceState({}, '', baseUri.origin);
    }
  }

  @override
  void initState() {
    super.initState();
    SettingsDB.instance.get().then((value) {
      _websiteSettings = value;
    }).catchError((err) {
      '$err'.log();
      _websiteSettings = WebsiteSettings.defaultSettings;
    }).whenComplete(() {
      _updateTheme();
    });
    _defaultAboutMe = Article(
      title: _localization.yourName,
      summary: '',
      content: _localization.describeYourself,
      summaryType: ArticleTypes.text.name,
      contentType: ArticleTypes.text.name,
      tags: [],
      creatingTime: DateTime.now().secondsSinceEpoch,
      editingTime: DateTime.now().secondsSinceEpoch,
      publishingTime: DateTime.now().secondsSinceEpoch,
      isPublished: true,
    );
    ProfileDB.instance.getAboutMe(defaultArticle: _defaultAboutMe).then((value) {
      _aboutMe = value;
      _aboutMe ??= _defaultAboutMe;
      _updateUi(() { });
    }).catchError((err) {
      '$err'.log();
      html.window.location.reload();
    });
    _defaultIntroduction = Article(
      title: _localization.websiteName,
      summary: _localization.introduceYourselfOrWebite,
      content: _localization.introduceYourselfOrWebsiteMoreDetail,
      summaryType: ArticleTypes.text.name,
      contentType: ArticleTypes.text.name,
      tags: [],
      creatingTime: DateTime.now().secondsSinceEpoch,
      editingTime: DateTime.now().secondsSinceEpoch,
      publishingTime: DateTime.now().secondsSinceEpoch,
      isPublished: true,
    );
    ArticlesDB.instance.getIntroduction(defaultArticle: _defaultIntroduction).then((value) {
      _introduction = value;
      _introduction ??= _defaultIntroduction;
      _updateUi(() { });
    }).catchError((err) {
      '$err'.log();
      html.window.location.reload();
    });
    ArticlesDB.instance.get().then((articles) {
      _allArticles = articles;
      _articles = articles;
      _updateTags(articles);
      _updateUi(() { });
    }).catchError((err) {
      '$err'.log();
      html.window.location.reload();
    });
    UserAccount.instance.getUserInfo().then((info) {
      if (info == null) {
        return;
      }
      _accountInfo = info;
      if (_accountInfo?.isAdmin == true) {
        ArticlesDB.instance.get(unpublished: true).then((value) {
          _unpublishedArticles = value;
          if (_unpublishedArticles.isNotEmpty) {
            _updateUi(() {});
          }
        }).catchError((err) {
          '$err'.log();
        });
      }
      _updateUi(() {});
    }).catchError((err) {
      '$err'.log();
    });
    _scrollController.addListener(() {
      final lvRenderBox = _listViewKey.currentContext?.findRenderObject() as RenderBox?;
      final apRenderBox = _appBarKey.currentContext?.findRenderObject() as RenderBox?;
      final anRenderBox = _appBarAnchorKey.currentContext?.findRenderObject() as RenderBox?;
      bool isAppBarOnTop = _isAppBarOnTop.value;
      if (isAppBarOnTop && lvRenderBox != null && anRenderBox != null) {
        double lvY = lvRenderBox.localToGlobal(Offset.zero).dy;
        double anY = anRenderBox.localToGlobal(Offset.zero).dy;
        isAppBarOnTop = lvY > anY;
      } else if (!isAppBarOnTop && lvRenderBox != null && apRenderBox != null) {
        double lvY = lvRenderBox.localToGlobal(Offset.zero).dy;
        double apY = apRenderBox.localToGlobal(Offset.zero).dy;
        isAppBarOnTop = lvY > apY;
      }
      if (_isAppBarOnTop.value != isAppBarOnTop) {
        _isAppBarOnTop.value = isAppBarOnTop;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    _isMobile = ResponsiveBreakpoints.of(context).isMobile;
    _isPhoneOrTablet = PlatformExt.isPhoneOrTablet;
    double padding;
    if (ResponsiveBreakpoints.of(context).largerOrEqualTo(DESKTOP)) {
      padding = 20;
    } else if (ResponsiveBreakpoints.of(context).largerOrEqualTo(TABLET)) {
      padding = 10;
    } else { // MOBILE
      padding = 5;
    }

    return Localizations.override(
      context: context,
      locale: context.watch<LocaleChangeNotifier>().locale,
      child: Builder(
        builder: (BuildContext context) {
          _localization = AppLocalizations.of(context) ?? AppLocalizationsEn();
          if (!_isInitDone) {
            Future.delayed(const Duration(seconds: 10), () {
              if (!_isInitDone) {
                html.window.location.reload();
              }
            });
            return Scaffold(
              body: Container(
                color: Colors.grey,
                alignment: Alignment.center,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _localization.loading,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const SizedBox(
                      width: 50,
                      height: 50,
                      child: CircularProgressIndicator(color: Colors.blue),
                    ),
                  ],
                ),
              ),
            );
          }
          final websiteSettings = _websiteSettings!;
          final websiteTheme = _websiteTheme!;
          final aboutMe = _aboutMe!;
          final introduction = _introduction!;
          bool adultCheckEnabled = websiteSettings.adultOnly ? ((_isAdult != true) && !(_accountInfo?.isAdmin ?? false)) : false;
          if (!adultCheckEnabled) {
            _handleUri();
          }
          return Title(
            title: websiteSettings.title,
            color: Colors.black,
            child: Stack(
              children: [
                MaxWidthBox(
                  maxWidth: double.maxFinite,
                  background: Container(color: Color(websiteTheme.bgColor)),
                  child: Container(
                    alignment: Alignment.center,
                    margin: EdgeInsets.all(padding),
                    decoration: BoxDecoration(
                      color: Color(websiteTheme.bgBoxColor),
                      borderRadius: const BorderRadius.all(Radius.circular(10)),
                    ),
                    child: ValueListenableBuilder<bool>(
                      valueListenable: _isAppBarOnTop,
                      builder: (context, currentState, child) {
                        return Scaffold(
                          backgroundColor: Colors.transparent,
                          body: Stack(
                            children: [
                              Container(
                                alignment: Alignment.center,
                                child: Column(
                                  children: [
                                    Expanded(
                                      child: ListView.builder(
                                        key: _listViewKey,
                                        controller: _scrollController,
                                        padding: EdgeInsets.all(padding),
                                        itemCount: 1 + _articles.length,
                                        itemBuilder: (context, index) {
                                          if (index == 0) {
                                            return _getProfileWidget(aboutMe: aboutMe, introduction: introduction, theme: websiteTheme);
                                          }

                                          int articleIndex = index - 1;
                                          int rowArticleNumber = ResponsiveBreakpoints.of(context).largerOrEqualTo(DESKTOP) ? 3 : (ResponsiveBreakpoints.of(context).largerOrEqualTo(TABLET) ? 2 : 1);
                                          Widget? listItem;
                                          if ((rowArticleNumber == 3) && (articleIndex*rowArticleNumber < _articles.length)) {
                                            if ((articleIndex * 3) >= _articles.length) {
                                              return null;
                                            }
                                            final articles = _articles.sublist(articleIndex * rowArticleNumber, min((articleIndex + 1) * rowArticleNumber, _articles.length));
                                            listItem = ThreeArticlesListItem(
                                              localization: _localization,
                                              theme: websiteTheme.articleTheme,
                                              type: ThreeArticlesLayoutTypes.values[articleIndex%ThreeArticlesLayoutTypes.values.length],
                                              articles: articles,
                                              isAdmin: _accountInfo?.isAdmin ?? false,
                                              onItemPressed: _onArticlePressed,
                                              onEditingPressed: (article) => _showArticleEditor(article: article, onFinish: (newArticle) {
                                                _updateArticle(article, newArticle);
                                                _updateUi(() { });
                                              }),
                                            );
                                          } else if ((rowArticleNumber == 2) && (articleIndex*rowArticleNumber < _articles.length)) {
                                            final articles = _articles.sublist(articleIndex * rowArticleNumber, min((articleIndex + 1) * rowArticleNumber, _articles.length));
                                            listItem = TwoArticlesListItem(
                                              localization: _localization,
                                              theme: websiteTheme.articleTheme,
                                              type: TwoArticlesLayoutTypes.values[articleIndex%TwoArticlesLayoutTypes.values.length],
                                              articles: articles,
                                              isAdmin: _accountInfo?.isAdmin ?? false,
                                              onItemPressed: _onArticlePressed,
                                              onEditingPressed: (article) => _showArticleEditor(article: article, onFinish: (newArticle) {
                                                _updateArticle(article, newArticle);
                                                _updateUi(() { });
                                              }),
                                            );
                                          } else if (rowArticleNumber == 1) { // MOBILE
                                            final articles = _articles.sublist(articleIndex, articleIndex + 1);
                                            listItem = SingleArticleListItem(
                                              localization: _localization,
                                              theme: websiteTheme.articleTheme,
                                              articles: articles,
                                              isAdmin: _accountInfo?.isAdmin ?? false,
                                              onItemPressed: _onArticlePressed,
                                              onEditingPressed: (article) => _showArticleEditor(article: article, onFinish: (newArticle) {
                                                _updateArticle(article, newArticle);
                                                _updateUi(() { });
                                              }),
                                            );
                                          }
                                          return listItem;
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (currentState) _getAppBar(theme: websiteTheme.toolbarTheme, isOnTop: true, hMargin: padding),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
                if (adultCheckEnabled) BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(
                    alignment: Alignment.center,
                    color: PlatformExt.isIOS ? Colors.black : Colors.black38, // NOTE: blur doesn't work on iOS
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.eighteen_up_rating_outlined,
                              size: 50,
                              color: Colors.redAccent,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              _localization.adultsOnly,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 36,
                                decoration: TextDecoration.none,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Text(
                          _localization.adultContentDesc,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            decoration: TextDecoration.none,
                          ),
                        ),
                        const SizedBox(height: 40),
                        ResponsiveRowColumn(
                          layout: _isMobile ? ResponsiveRowColumnType.COLUMN : ResponsiveRowColumnType.ROW,
                          rowMainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ResponsiveRowColumnItem(
                              child: TextButton(
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.all(16),
                                  backgroundColor: Colors.redAccent,
                                  foregroundColor: Colors.white,
                                  side: const BorderSide(color: Colors.white),
                                ),
                                onPressed: () {
                                  _isAdult = true;
                                  _updateUi(() { });
                                },
                                child: Text(
                                  _localization.overAge,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    decoration: TextDecoration.none,
                                  ),
                                ),
                              ),
                            ),
                            const ResponsiveRowColumnItem(
                              child: SizedBox(width: 40, height: 40),
                            ),
                            ResponsiveRowColumnItem(
                              child: TextButton(
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.all(16),
                                  foregroundColor: Colors.white,
                                  side: const BorderSide(color: Colors.white),
                                ),
                                onPressed: () {
                                  html.window.history.back();
                                },
                                child: Text(
                                  _localization.underAge,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    decoration: TextDecoration.none,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

extension on PopupMenuItems {
  IconData get icon {
    switch (this) {
      case PopupMenuItems.login:
        return Icons.login;
      case PopupMenuItems.logout:
        return Icons.logout;
      case PopupMenuItems.settings:
        return Icons.settings_outlined;
      case PopupMenuItems.newArticle:
        return Icons.note_add_outlined;
    }
  }

  String toLocalizedString(AppLocalizations localization) {
    switch (this) {
      case PopupMenuItems.login:
        return localization.login;
      case PopupMenuItems.logout:
        return localization.logout;
      case PopupMenuItems.settings:
        return localization.settings;
      case PopupMenuItems.newArticle:
        return localization.newArticle;
    }
  }
}
