import 'dart:html' as html;
import 'dart:math';

import 'package:firebase_blog_template/firebase/ArticlesDB.dart';
import 'package:firebase_blog_template/util/DateTimeExtension.dart';
import 'package:firebase_blog_template/util/PlatformExtension.dart';
import 'package:firebase_blog_template/util/StringExtension.dart';
import 'package:firebase_blog_template/util/notifications.dart';
import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:flutter/material.dart';

import 'package:flutter_html/flutter_html.dart';

import 'package:flutter_gen/gen_l10n/web_localizations.dart';
import 'package:flutter_gen/gen_l10n/web_localizations_en.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:responsive_framework/responsive_breakpoints.dart';

import '../firebase/ImagesDB.dart';
import '../models/Article.dart';
import '../models/ArticleTheme.dart';
import '../models/ImageMetadata.dart';
import '../models/WebsiteImage.dart';
import '../util/ImageAssets.dart';

enum ArticleEditorTabs {
  edit,
  theme,
  settings,
}

enum ArticleThemeTypes {
  defaultTheme,
  customized,
}

class ArticleEditorDialog extends StatelessWidget {
  AppLocalizations localization = AppLocalizationsEn();
  ArticleTheme defaultTheme;
  Article? article;
  bool isDeletable;
  void Function(Article?)? onFinish;
  Color? backgroundColor;
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
  ArticleEditorTabs _currentTab = ArticleEditorTabs.edit;
  late Size _currentSize;
  bool _isMobile = false;
  bool _isPhoneOrTablet = false;
  bool _changesSaved = false;
  final ValueNotifier<bool> _articleChanged = ValueNotifier(false);
  final ValueNotifier<bool> _themeChanged = ValueNotifier(false);
  final ValueNotifier<bool> _settingsChanged = ValueNotifier(false);
  final ValueNotifier<bool> _uncopiable = ValueNotifier(false);
  final ValueNotifier<bool> _publishing = ValueNotifier(false);
  final ValueNotifier<ArticleThemeTypes> _selectedThemeType = ValueNotifier(ArticleThemeTypes.defaultTheme);
  final ValueNotifier<ArticleTypes> _summaryFormat = ValueNotifier(ArticleTypes.text);
  final ValueNotifier<ArticleTypes> _contentFormat = ValueNotifier(ArticleTypes.text);
  late ArticleTheme _customizedTheme;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _tagsController = TextEditingController();
  final TextEditingController _summaryController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  List<ImageMetadata> _dbImages = [];

  ArticleEditorDialog({
    Key? key,
    required this.localization,
    required this.defaultTheme,
    this.article,
    this.isDeletable = true,
    this.onFinish,
    this.backgroundColor,
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

  void _resetEditing() {
    _titleController.text = article!.title;
    _summaryController.text = article!.summary;
    _contentController.text = article!.content;
    _summaryFormat.value = ArticleTypes.values.byName(article!.summaryType);
    _contentFormat.value = ArticleTypes.values.byName(article!.contentType);
    _tagsController.text = article!.tags.join(', ');
    _articleChanged.value = false;
  }

  void _resetTheme() {
    _selectedThemeType.value = (article!.theme == null) ? ArticleThemeTypes.defaultTheme : ArticleThemeTypes.customized;
    _customizedTheme = article!.theme ?? ArticleTheme.fromJson(defaultTheme.toJson());
    _themeChanged.value = false;
  }

  void _resetSettings() {
    _uncopiable.value = article!.isUncopiable;
    _publishing.value = article!.isPublished;
    _settingsChanged.value = false;
  }

  void _saveEditing(BuildContext context) {
    article!.title = _titleController.text;
    article!.summary = _summaryController.text;
    article!.content = _contentController.text;
    article!.summaryType = _summaryFormat.value.name;
    article!.contentType = _contentFormat.value.name;
    article!.tags = _tagsController.text.split(',').map((e) => e.trim()).toList();
    final now = DateTime.now().secondsSinceEpoch;
    article!.editingTime = now;
    if (article!.creatingTime == 0) {
      article!.creatingTime = now;
    }
    if (article!.publishingTime == 0 && article!.isPublished) {
      article!.publishingTime = now;
    }
    final dismiss = localization.saving.asLoadingIndicator(context: context);
    bool success = true;
    String errMsg = '';
    ArticlesDB.instance.set(article!).then((value) {
      article = value;
    }).catchError((err) {
      '$err'.log();
      success = false;
      errMsg = err.toString();
    }).whenComplete(() {
      dismiss();
      if (success) {
        _articleChanged.value = false;
        _changesSaved = true;
      } else {
        showErrorNotification(context: context, description: errMsg);
      }
    });
  }

  void _saveTheme(BuildContext context) {
    article!.theme = (_selectedThemeType.value == ArticleThemeTypes.defaultTheme) ? null : _customizedTheme;
    final dismiss = localization.saving.asLoadingIndicator(context: context);
    bool success = true;
    String errMsg = '';
    ArticlesDB.instance.set(article!).then((value) {
      article = value;
    }).catchError((err) {
      '$err'.log();
      success = false;
      errMsg = err.toString();
    }).whenComplete(() {
      dismiss();
      if (success) {
        _themeChanged.value = false;
        _changesSaved = true;
      } else {
        showErrorNotification(context: context, description: errMsg);
      }
    });
  }

  void _saveSettings(BuildContext context) {
    article!.isUncopiable = _uncopiable.value;
    article!.isPublished = _publishing.value;
    final dismiss = localization.saving.asLoadingIndicator(context: context);
    bool success = true;
    String errMsg = '';
    ArticlesDB.instance.set(article!).then((value) {
      article = value;
    }).catchError((err) {
      '$err'.log();
      success = false;
      errMsg = err.toString();
    }).whenComplete(() {
      dismiss();
      if (success) {
        _settingsChanged.value = false;
        _changesSaved = true;
      } else {
        showErrorNotification(context: context, description: errMsg);
      }
    });
  }

  void _deleteArticle(BuildContext context) {
    final dismiss = localization.saving.asLoadingIndicator(context: context);
    ArticlesDB.instance.delete(article!).then((value) {
      _changesSaved = true;
      dismiss();
      Navigator.of(context).pop();
      onFinish?.call(null);
    }).catchError((err) {
      '$err'.log();
      dismiss();
      showErrorNotification(context: context, description: err.toString());
    });
  }

  void _showColorPickerDialog({required BuildContext context, Color currentColor = Colors.white, void Function(Color)? onPicked}) {
    Color selectedColor = currentColor;
    ColorPicker(
      color: currentColor,
      onColorChanged: (color) {
        selectedColor = color;
      },
      width: 40,
      height: 40,
      borderRadius: 4,
      spacing: 5,
      runSpacing: 5,
      wheelDiameter: 155,
      heading: Text(
        localization.selectColor,
        style: Theme
            .of(context)
            .textTheme
            .titleSmall,
      ),
      subheading: Text(
        localization.selectColorShade,
        style: Theme
            .of(context)
            .textTheme
            .titleSmall,
      ),
      wheelSubheading: Text(
        localization.selectedColorAndShades,
        style: Theme
            .of(context)
            .textTheme
            .titleSmall,
      ),
      showMaterialName: true,
      showColorName: true,
      showColorCode: true,
      copyPasteBehavior: const ColorPickerCopyPasteBehavior(
        longPressMenu: true,
      ),
      materialNameTextStyle: Theme
          .of(context)
          .textTheme
          .bodySmall,
      colorNameTextStyle: Theme
          .of(context)
          .textTheme
          .bodySmall,
      colorCodeTextStyle: Theme
          .of(context)
          .textTheme
          .bodySmall,
      pickersEnabled: const <ColorPickerType, bool>{
        ColorPickerType.both: false,
        ColorPickerType.primary: true,
        ColorPickerType.accent: true,
        ColorPickerType.bw: false,
        ColorPickerType.custom: true,
        ColorPickerType.wheel: true,
      },
      actionButtons: ColorPickerActionButtons(
        dialogOkButtonLabel: localization.ok,
        dialogCancelButtonLabel: localization.cancel,
      ),
    ).showPickerDialog(
      context,
      barrierDismissible: false,
      // New in version 3.0.0 custom transitions support.
      transitionBuilder: (BuildContext context,
          Animation<double> a1,
          Animation<double> a2,
          Widget widget) {
        final double curvedValue =
            Curves.easeInOutBack.transform(a1.value) - 1.0;
        return Transform(
          transform: Matrix4.translationValues(
              0.0, curvedValue * 200, 0.0),
          child: Opacity(
            opacity: a1.value,
            child: widget,
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 400),
      constraints: const BoxConstraints(minHeight: 460, minWidth: 300, maxWidth: 320),
    ).then((value) => (value && onPicked != null) ? onPicked!(selectedColor) : null);
  }

  void _showImagePickerDialog({required BuildContext context, required String currentPath, void Function(String)? onPicked}) {
    final emptyImage = WebsiteImage(name: '', url: '', locationType: ImageLocationTypes.internal.name);
    List<WebsiteImage> websiteImages = [emptyImage];
    ValueNotifier<WebsiteImage> currentImage = ValueNotifier(emptyImage);
    websiteImages = _dbImages.map((e) => WebsiteImage(name: e.name ?? '', url: e.url ?? '', locationType: ImageLocationTypes.cloudStorage.name)).toList();
    websiteImages.insertAll(0, ImageAssets.all);
    const textStyle = TextStyle(fontSize: 18, color: Colors.black, overflow: TextOverflow.ellipsis);
    final menuItemHeight = websiteImages.map((e) {
      final height = e.name.calculateTextSize(context: context, style: textStyle).height;
      return height;
    }).reduce(max);
    currentImage.value = websiteImages.firstWhere((element) {
      switch (ImageLocationTypes.values.byName(element.locationType)) {
        case ImageLocationTypes.internal:
          return (currentPath == element.name);
        case ImageLocationTypes.cloudStorage:
          return (currentPath == element.url);
        case ImageLocationTypes.external:
          return (currentPath == element.url);
        case _:
          return false;
      }
    }, orElse: () {
      websiteImages.insert(0, emptyImage);
      return emptyImage;
    });
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: ValueListenableBuilder<WebsiteImage>(
            valueListenable: currentImage,
            builder: (context, currentState, child) {
              dynamic image = currentState.image;
              return Container(
                width: 400,
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(localization.image, textAlign: TextAlign.center, style: textStyle),
                    const SizedBox(height: 20),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image(
                        image: image,
                        width: 300,
                        fit: BoxFit.fitWidth,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      height: menuItemHeight * 2,
                      alignment: Alignment.center,
                      decoration: const ShapeDecoration(
                        color: Colors.white,
                        shape: StadiumBorder(
                          side: BorderSide(color: Colors.black, width: 1),
                        ),
                      ),
                      child: DropdownButton<WebsiteImage>(
                        value: currentImage.value,
                        style: const TextStyle(fontSize: 18, color: Colors.black),
                        alignment: AlignmentDirectional.center,
                        dropdownColor: Colors.white,
                        focusColor: Colors.transparent,
                        iconEnabledColor: Colors.black,
                        borderRadius: BorderRadius.circular(10),
                        underline: Container(),
                        items: websiteImages.map<DropdownMenuItem<WebsiteImage>>((e) =>
                            DropdownMenuItem(
                              value: e,
                              child: Container(
                                padding: const EdgeInsets.only(left: 0, right: 8),
                                child: Row(
                                  children: [
                                    Image(image: e.image, width: menuItemHeight * 2, height: menuItemHeight * 2),
                                    const SizedBox(width: 8),
                                    Text(e.name, textAlign: TextAlign.left, maxLines: 1)
                                  ],
                                ),
                              ),
                            )).toList(),
                        onChanged: (value) {
                          if (value == null) {
                            return;
                          }
                          currentImage.value = value;
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.black,
                            //backgroundColor: ,
                            shape: const StadiumBorder(side: BorderSide(color: Colors.black)),
                          ),
                          child: Text(localization.cancel),
                        ),
                        const SizedBox(width: 20),
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            if (onPicked != null) {
                              onPicked((currentState.locationType == ImageLocationTypes.internal.name) ? currentState.name : '${currentState.name}\n${currentState.url}');
                            }
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: Colors.black,
                            shape: const StadiumBorder(side: BorderSide(color: Colors.black)),
                          ),
                          child: Text(localization.ok),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _getContentWidget(ArticleTypes type, String content, Color textColor) {
    Widget widget;
    if (type == ArticleTypes.html) {
      widget = Html(
        data: content,
        onLinkTap: (url, _, __) {
          if (url != null) {
            html.window.open(url, '');
          }
        },
      );
    } else if (type == ArticleTypes.markdown) {
      widget = MarkdownBody(data: content);
    } else { // text
      widget = Text(
        content,
        style: TextStyle(
          color: textColor,
          fontSize: 18,
        ),
      );
    }
    return widget;
  }

  void _showPreviewDialog(BuildContext context, ArticleTypes type, String content, Color backgroundColor, Color textColor) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: backgroundColor,
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
          child: SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.all(20),
              child: _getContentWidget(type, content, textColor),
            ),
          ),
        );
      },
    );
  }

  Widget _getSideMenu(BuildContext context, {bool isIndependent = false}) {
    const double headerPadding = 16;
    final headerText = localization.article;
    const headerTextStyle = TextStyle(
      color: Colors.white,
      fontSize: 20,
      fontWeight: FontWeight.bold,
      decoration: TextDecoration.none,
    );
    final headerSize = headerText.calculateTextSize(context: context, style: headerTextStyle);
    final headerWidth = headerSize.width + headerPadding * 2;
    final headerHeight = headerSize.height + (isIndependent ? -headerPadding / 2 : headerPadding * 2);

    const double itemPadding = 4;
    double listHeight = _currentSize.height - itemPadding * 2 - headerHeight;
    List<ArticleEditorTabs> items = ArticleEditorTabs.values;
    const itemTextStyle = TextStyle(
      color: Colors.black,
      fontSize: 18,
      fontWeight: FontWeight.bold,
    );
    double itemWidth = items.map((e) {
      final width = e
          .toLocalizedString(localization)
          .calculateTextSize(context: context, style: itemTextStyle)
          .width;
      return width;
    }).reduce(max) + itemPadding * 2 + headerPadding * 2 + 20 * 2;

    final width = max(itemWidth, headerWidth);

    return Container(
      width: width,
      decoration: BoxDecoration(
        border: isIndependent ? null : const Border(right: BorderSide(color: Colors.black45)),
      ),
      child: Column(
        children: [
          Expanded(
            child: Container(
              height: headerHeight,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.only(topLeft: Radius.circular(isIndependent ? 0 : 10), topRight: Radius.circular(isIndependent ? 10 : 0)),
              ),
              child: Text(
                localization.article,
                style: headerTextStyle,
              ),
            ),
          ),
          SizedBox(
            height: listHeight,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: itemPadding),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                final isSelected = (_currentTab == item);
                return Material(
                  type: MaterialType.transparency,
                  child: ListTile(
                    selected: isSelected,
                    hoverColor: Colors.black12,
                    selectedTileColor: Colors.black38,
                    title: Text(
                      item.toLocalizedString(localization),
                      textAlign: TextAlign.center,
                      style: itemTextStyle.copyWith(color: isSelected ? Colors.white : Colors.black),
                    ),
                    onTap: () {
                      _currentTab = item;
                      _updateUi();
                      if (_isMobile) {
                        Navigator.of(context).pop();
                      }
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showSideMenu(BuildContext context) {
    Size size = MediaQuery
        .of(context)
        .size;
    showDialog(
      context: context,
      builder: (context) {
        return ValueListenableBuilder<int>(
          valueListenable: _updateUiCount,
          builder: (context, currentState, child) {
            return Container(
              width: size.width,
              height: size.height,
              alignment: Alignment.centerLeft,
              decoration: const BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.all(Radius.circular(10)),
              ),
              child: Row(
                children: [
                  Container(
                    height: size.height,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.horizontal(right: Radius.circular(10)),
                    ),
                    child: _getSideMenu(context, isIndependent: true),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTapUp: (details) {
                        Navigator.of(context).pop();
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _getEditTab(BuildContext context) {
    const textStyle = TextStyle(fontSize: 18, color: Colors.black, overflow: TextOverflow.ellipsis);
    final menuItemWidth = ArticleTypes.values.map((e) {
      final width = e.toLocalizedString(localization).calculateTextSize(context: context, style: textStyle).width;
      return width;
    }).reduce(max);
    final menuItemHeight = ArticleTypes.values.map((e) {
      final height = e.toLocalizedString(localization).calculateTextSize(context: context, style: textStyle).height;
      return height;
    }).reduce(max);

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(localization.title, style: const TextStyle(fontSize: 14, color: Colors.black)),
                const SizedBox(height: 4),
                SizedBox(
                  height: 35,
                  child: TextFormField(
                    controller: _titleController,
                    autofocus: false,
                    textCapitalization: TextCapitalization.none,
                    enableIMEPersonalizedLearning: false,
                    style: const TextStyle(fontSize: 18, color: Colors.black),
                    decoration: const InputDecoration(
                      contentPadding: EdgeInsets.symmetric(horizontal: 8),
                      border: OutlineInputBorder(borderSide: BorderSide(color: Colors.black45, width: 1)),
                    ),
                    onChanged: (value) {
                      _articleChanged.value = true;
                    },
                  ),
                ),
                const SizedBox(height: 20),
                Text(localization.tags, style: const TextStyle(fontSize: 14, color: Colors.black)),
                const SizedBox(height: 4),
                SizedBox(
                  height: 60,
                  child: TextFormField(
                    controller: _tagsController,
                    autofocus: false,
                    textCapitalization: TextCapitalization.none,
                    enableIMEPersonalizedLearning: false,
                    style: const TextStyle(fontSize: 18, color: Colors.black),
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                      border: const OutlineInputBorder(borderSide: BorderSide(color: Colors.black45, width: 1)),
                      helperText: localization.tagsDesc,
                      helperMaxLines: 1,
                      helperStyle: const TextStyle(fontSize: 14, color: Colors.black),
                    ),
                    onChanged: (value) {
                      _articleChanged.value = true;
                    },
                  ),
                ),
                const SizedBox(height: 30),
                const Divider(height: 1, color: Colors.black45),
                const SizedBox(height: 20),
                Text(localization.summaryFormat, style: const TextStyle(fontSize: 14, color: Colors.black)),
                const SizedBox(height: 4),
                ValueListenableBuilder<ArticleTypes>(
                  valueListenable: _summaryFormat,
                  builder: (context, currentState, child) {
                    return Container(
                      width: menuItemWidth + 16*2 + 24,
                      height: menuItemHeight + 5 * 2,
                      alignment: Alignment.center,
                      decoration: const ShapeDecoration(
                        color: Colors.white,
                        shape: StadiumBorder(
                          side: BorderSide(color: Colors.black, width: 1),
                        ),
                      ),
                      child: DropdownButton<ArticleTypes>(
                        value: currentState,
                        style: textStyle,
                        alignment: AlignmentDirectional.center,
                        dropdownColor: Colors.white,
                        focusColor: Colors.transparent,
                        iconEnabledColor: Colors.black,
                        borderRadius: BorderRadius.circular(10),
                        underline: Container(),
                        items: ArticleTypes.values.map<DropdownMenuItem<ArticleTypes>>((e) =>
                            DropdownMenuItem(
                              value: e,
                              child: Container(
                                padding: const EdgeInsets.only(left: 16, right: 8),
                                child: Text(e.toLocalizedString(localization), textAlign: TextAlign.left, maxLines: 1),
                              ),
                            )).toList(),
                        onChanged: (value) {
                          if (value == null) {
                            return;
                          }
                          _summaryFormat.value = value;
                          _articleChanged.value = true;
                        },
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),
                Text(localization.summary, style: const TextStyle(fontSize: 14, color: Colors.black)),
                const SizedBox(height: 4),
                Stack(
                  children: [
                    TextField(
                      controller: _summaryController,
                      autofocus: false,
                      textCapitalization: TextCapitalization.none,
                      enableIMEPersonalizedLearning: false,
                      keyboardType: TextInputType.multiline,
                      maxLines: null,
                      style: const TextStyle(fontSize: 18, color: Colors.black),
                      decoration: const InputDecoration(
                        contentPadding: EdgeInsets.all(8),
                        border: OutlineInputBorder(borderSide: BorderSide(color: Colors.black45, width: 1)),
                      ),
                      onChanged: (value) {
                        _articleChanged.value = true;
                      },
                    ),
                    Container(
                      alignment: Alignment.topRight,
                      child: Material(
                        type: MaterialType.transparency,
                        shape: const CircleBorder(),
                        clipBehavior: Clip.antiAlias,
                        child: IconButton(
                          icon: const Icon(Icons.preview),
                          iconSize: 24,
                          color: Colors.black,
                          onPressed: () {
                            _showPreviewDialog(context, _summaryFormat.value, _summaryController.text, Colors.grey[300]!, Color(_customizedTheme.summaryTextColor));
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                const Divider(height: 1, color: Colors.black45),
                const SizedBox(height: 20),
                Text(localization.contentFormat, style: const TextStyle(fontSize: 14, color: Colors.black)),
                const SizedBox(height: 4),
                ValueListenableBuilder<ArticleTypes>(
                  valueListenable: _contentFormat,
                  builder: (context, currentState, child) {
                    return Container(
                      width: menuItemWidth + 16*2 + 24,
                      height: menuItemHeight + 5 * 2,
                      alignment: Alignment.center,
                      decoration: const ShapeDecoration(
                        color: Colors.white,
                        shape: StadiumBorder(
                          side: BorderSide(color: Colors.black, width: 1),
                        ),
                      ),
                      child: DropdownButton<ArticleTypes>(
                        value: currentState,
                        style: textStyle,
                        alignment: AlignmentDirectional.center,
                        dropdownColor: Colors.white,
                        focusColor: Colors.transparent,
                        iconEnabledColor: Colors.black,
                        borderRadius: BorderRadius.circular(10),
                        underline: Container(),
                        items: ArticleTypes.values.map<DropdownMenuItem<ArticleTypes>>((e) =>
                            DropdownMenuItem(
                              value: e,
                              child: Container(
                                padding: const EdgeInsets.only(left: 16, right: 8),
                                child: Text(e.toLocalizedString(localization), textAlign: TextAlign.left, maxLines: 1),
                              ),
                            )).toList(),
                        onChanged: (value) {
                          if (value == null) {
                            return;
                          }
                          _contentFormat.value = value;
                          _articleChanged.value = true;
                        },
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),
                Text(localization.content, style: const TextStyle(fontSize: 14, color: Colors.black)),
                const SizedBox(height: 4),
                Stack(
                  children: [
                    TextField(
                      controller: _contentController,
                      autofocus: false,
                      textCapitalization: TextCapitalization.none,
                      enableIMEPersonalizedLearning: false,
                      keyboardType: TextInputType.multiline,
                      maxLines: null,
                      style: const TextStyle(fontSize: 18, color: Colors.black),
                      decoration: const InputDecoration(
                        contentPadding: EdgeInsets.all(8),
                        border: OutlineInputBorder(borderSide: BorderSide(color: Colors.black45, width: 1)),
                      ),
                      onChanged: (value) {
                        _articleChanged.value = true;
                      },
                    ),
                    Container(
                      alignment: Alignment.topRight,
                      child: Material(
                        type: MaterialType.transparency,
                        shape: const CircleBorder(),
                        clipBehavior: Clip.antiAlias,
                        child: IconButton(
                          icon: const Icon(Icons.preview),
                          iconSize: 24,
                          color: Colors.black,
                          onPressed: () {
                            _showPreviewDialog(context, _contentFormat.value, _contentController.text, Color(_customizedTheme.contentBgColor), Color(_customizedTheme.contentTextColor));
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        ValueListenableBuilder<bool>(
          valueListenable: _articleChanged,
          builder: (context, currentState, child) {
            return Container(
              padding: EdgeInsets.symmetric(vertical: _isPhoneOrTablet ? 10 : 20, horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: !currentState ? null : () {
                      localization.resetEditingConfirmation.asAlertDialog(
                        context: context,
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.of(context);
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.black,
                              backgroundColor: Colors.white,
                              disabledForegroundColor: Colors.black45,
                              disabledBackgroundColor: Colors.white,
                              shape: const StadiumBorder(side: BorderSide(color: Colors.black)),
                              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                            ),
                            child: Text(
                              localization.no,
                              style: const TextStyle(fontSize: 18),
                            ),
                          ),
                          const SizedBox(width: 5),
                          TextButton(
                            onPressed: () {
                              _resetEditing();
                              Navigator.of(context).pop();
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.white,
                              backgroundColor: Colors.black,
                              disabledForegroundColor: Colors.black45,
                              disabledBackgroundColor: Colors.white,
                              shape: const StadiumBorder(side: BorderSide(color: Colors.black)),
                              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                            ),
                            child: Text(
                              localization.yes,
                              style: const TextStyle(fontSize: 18),
                            ),
                          ),
                        ],
                      );
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.black,
                      backgroundColor: Colors.white,
                      disabledForegroundColor: Colors.black45,
                      disabledBackgroundColor: Colors.white,
                      shape: const StadiumBorder(side: BorderSide(color: Colors.black)),
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    ),
                    child: Text(
                      localization.reset,
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                  const SizedBox(width: 20),
                  TextButton(
                    onPressed: !currentState ? null : () {
                      _saveEditing(context);
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.black,
                      disabledForegroundColor: Colors.black45,
                      disabledBackgroundColor: Colors.white,
                      shape: const StadiumBorder(side: BorderSide(color: Colors.black)),
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    ),
                    child: Text(
                      article!.isPublished ? localization.publish : localization.save,
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _getThemeTab(BuildContext context) {
    const textStyle = TextStyle(fontSize: 18, color: Colors.black, overflow: TextOverflow.ellipsis);
    final themeTypes = [ArticleThemeTypes.defaultTheme, ArticleThemeTypes.customized];
    final menuItemHeight = themeTypes.map((e) {
      final height = e.toLocalizedString(localization).calculateTextSize(context: context, style: textStyle).height;
      return height;
    }).reduce(max);

    List<(String, String, dynamic Function(), void Function(dynamic))> themeColors = [
      (localization.articleBgColor, localization.articleBgColorDesc, () => Color(_customizedTheme.bgColor), (color) {
        _customizedTheme.bgColor = color.value;
        _customizedTheme.summaryBoxColor = (color.value & 0x00FFFFFF) | 0x7F000000;
        _customizedTheme.summaryBoxHoverColor = (color.value & 0x00FFFFFF) | 0xAA000000;
        _customizedTheme.contentBgColor = color.value;
      }),
      (localization.articleFgColor, localization.articleFgColorDesc, () => Color(_customizedTheme.fgColor), (color) {
        _customizedTheme.fgColor = color.value;
        _customizedTheme.borderColor = color.value;
        _customizedTheme.summaryTextColor = color.value;
        _customizedTheme.contentTextColor = color.value;
      }),
      (localization.articleBorderColor, localization.articleBorderColorDesc, () => Color(_customizedTheme.borderColor), (color) =>
      _customizedTheme.borderColor = color.value),
      (localization.articleSummaryBoxColor, localization.articleSummaryBoxColorDesc, () => Color(_customizedTheme.summaryBoxColor), (color) =>
      _customizedTheme.summaryBoxColor = color.value),
      (localization.articleSummaryBoxHoverColor, localization.articleSummaryBoxHoverColorDesc, () => Color(_customizedTheme.summaryBoxHoverColor), (color) =>
      _customizedTheme.summaryBoxHoverColor = color.value),
      (localization.articleSummaryTextColor, localization.articleSummaryTextColorDesc, () => Color(_customizedTheme.summaryTextColor), (color) =>
      _customizedTheme.summaryTextColor = color.value),
      (localization.articleContentBgColor, localization.articleContentBgColorDesc, () => Color(_customizedTheme.contentBgColor), (color) =>
      _customizedTheme.contentBgColor = color.value),
      (localization.articleContentTextColor, localization.articleContentTextColorDesc, () => Color(_customizedTheme.contentTextColor), (color) =>
      _customizedTheme.contentTextColor = color.value),
    ];
    List<(String, String, dynamic Function(), void Function(dynamic))> themeImages = [
      (localization.articleCoverImage, localization.articleCoverImageDesc, () => _customizedTheme.coverImage ?? '', (path) {
        _customizedTheme.coverImage = path;
        _customizedTheme.portraitCoverImage = path;
        _customizedTheme.landscapeCoverImage = path;
      }),
      (localization.articlePortraitCoverImage, localization.articlePortraitCoverImageDesc, () => _customizedTheme.portraitCoverImage ?? '', (path) =>
      _customizedTheme.portraitCoverImage = path),
      (localization.articleLandscapeCoverImage, localization.articleLandscapeCoverImageDesc, () => _customizedTheme.landscapeCoverImage ?? '', (path) =>
      _customizedTheme.landscapeCoverImage = path),
    ];

    const double minItemWidth = 410;
    const double itemHeight = 110;
    const double itemPadding = 20;
    const itemConstraints = BoxConstraints(minWidth: minItemWidth);
    final itemDecoration = BoxDecoration(
      border: Border.all(
        color: Colors.black45,
      ),
      borderRadius: const BorderRadius.all(Radius.circular(10)),
    );
    const helperIcon = Icon(Icons.help_outline, size: 24, color: Colors.black);
    const disabledHelperIcon = Icon(Icons.help_outline, size: 24, color: Colors.black45);

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.black45))
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text(localization.websiteTheme, style: textStyle),
                      const SizedBox(width: 20),
                      Tooltip(
                        message: localization.websiteThemeDesc,
                        child: helperIcon,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ValueListenableBuilder<ArticleThemeTypes>(
                    valueListenable: _selectedThemeType,
                    builder: (context, currentState, child) {
                      return Container(
                        height: menuItemHeight + 5 * 2,
                        alignment: Alignment.center,
                        decoration: const ShapeDecoration(
                          color: Colors.white,
                          shape: StadiumBorder(
                            side: BorderSide(color: Colors.black, width: 1),
                          ),
                        ),
                        child: DropdownButton<ArticleThemeTypes>(
                          value: _selectedThemeType.value,
                          style: const TextStyle(fontSize: 18, color: Colors.black),
                          alignment: AlignmentDirectional.center,
                          dropdownColor: Colors.white,
                          focusColor: Colors.transparent,
                          iconEnabledColor: Colors.black,
                          borderRadius: BorderRadius.circular(10),
                          underline: Container(),
                          items: ArticleThemeTypes.values.map<DropdownMenuItem<ArticleThemeTypes>>((e) =>
                              DropdownMenuItem(
                                value: e,
                                child: Container(
                                  padding: const EdgeInsets.only(left: 16, right: 8),
                                  child: Text(e.toLocalizedString(localization), textAlign: TextAlign.left, maxLines: 1),
                                ),
                              )).toList(),
                          onChanged: (type) {
                            if (type == null) {
                              return;
                            }
                            if (type == ArticleThemeTypes.defaultTheme) {
                              _customizedTheme = ArticleTheme.fromJson(defaultTheme.toJson());
                            }
                            _selectedThemeType.value = type;
                            _themeChanged.value = true;
                          },
                        ),
                      );
                    },
                  ),
                ],
              ),
              const Spacer(),
              ValueListenableBuilder<bool>(
                valueListenable: _themeChanged,
                builder: (context, currentState, child) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: !currentState ? null : () {
                          _saveTheme(context);
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: Colors.black,
                          disabledForegroundColor: Colors.black45,
                          disabledBackgroundColor: Colors.white,
                          shape: const StadiumBorder(side: BorderSide(color: Colors.black)),
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                        ),
                        child: Text(
                          localization.save,
                          style: const TextStyle(fontSize: 18),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: !currentState ? null : () {
                          _resetTheme();
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.black,
                          backgroundColor: Colors.white,
                          disabledForegroundColor: Colors.black45,
                          disabledBackgroundColor: Colors.white,
                          shape: const StadiumBorder(side: BorderSide(color: Colors.black)),
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                        ),
                        child: Text(
                          localization.reset,
                          style: const TextStyle(fontSize: 18),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              //final height = constraints.maxHeight;
              const double spacing = 20;
              final columnNumber = (width / (minItemWidth + spacing + 50)).round();
              ValueNotifier<int> themeChangedCount = ValueNotifier(0);
              return GridView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: themeColors.length + themeImages.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columnNumber,
                  childAspectRatio: (width / columnNumber - itemPadding * 2) / itemHeight,
                  mainAxisSpacing: spacing,
                  crossAxisSpacing: spacing,
                ),
                itemBuilder: (context, index) {
                  final isColor = (index < themeColors.length);
                  final themeItem = isColor ? themeColors[index] : themeImages[index - themeColors.length];
                  final title = themeItem.$1;
                  final desc = themeItem.$2;
                  final get = themeItem.$3;
                  final set = themeItem.$4;
                  TextEditingController textEditingController = TextEditingController();
                  return ValueListenableBuilder<ArticleThemeTypes>(
                    valueListenable: _selectedThemeType,
                    builder: (context, currentState, child) {
                      final isCustomized = (currentState == ArticleThemeTypes.customized);
                      return Container(
                        padding: const EdgeInsets.all(itemPadding),
                        constraints: itemConstraints,
                        decoration: itemDecoration,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  title,
                                  style: isCustomized ? textStyle : textStyle.copyWith(color: Colors.black45),
                                ),
                                const SizedBox(width: 10),
                                const Spacer(),
                                Tooltip(
                                  message: desc,
                                  child: isCustomized ? helperIcon : disabledHelperIcon,
                                ),
                              ],
                            ),
                            const Spacer(),
                            ValueListenableBuilder(
                              valueListenable: themeChangedCount,
                              builder: (context, currentState, child) {
                                Widget widget;
                                if (isColor) {
                                  Color currentColor = get();
                                  widget = TextButton(
                                    onPressed: !isCustomized ? null : () {
                                      _showColorPickerDialog(
                                        context: context,
                                        currentColor: get(),
                                        onPicked: (color) {
                                          set(color);
                                          themeChangedCount.value++;
                                          _themeChanged.value = true;
                                        },
                                      );
                                    },
                                    style: TextButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(horizontal: 0),
                                      disabledForegroundColor: Colors.black45,
                                      primary: Colors.black,
                                      textStyle: textStyle,
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      mainAxisAlignment: MainAxisAlignment.start,
                                      children: [
                                        Icon(Icons.square, size: 24, color: currentColor),
                                        const SizedBox(width: 10),
                                        Text(currentColor.hexAlpha),
                                      ],
                                    ),
                                  );
                                } else {
                                  String fileName = (get() as String).split('\n').first;
                                  String filePath = (get() as String).split('\n').last;
                                  textEditingController.text = fileName;
                                  widget = Row(
                                    children: [
                                      Expanded(
                                        child: SizedBox(
                                          height: 30,
                                          child: TextFormField(
                                            controller: textEditingController,
                                            //initialValue: filePath,
                                            autofocus: false,
                                            readOnly: true,
                                            textCapitalization: TextCapitalization.none,
                                            enableIMEPersonalizedLearning: false,
                                            style: TextStyle(fontSize: 18, color: isCustomized ? Colors.black : Colors.black45),
                                            decoration: const InputDecoration(
                                              contentPadding: EdgeInsets.symmetric(horizontal: 15),
                                              border: OutlineInputBorder(borderSide: BorderSide(color: Colors.black45, width: 1)),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Material(
                                        type: MaterialType.transparency,
                                        shape: const CircleBorder(),
                                        clipBehavior: Clip.antiAlias,
                                        child: IconButton(
                                          onPressed: !isCustomized ? null : () {
                                            _showImagePickerDialog(context: context, currentPath: filePath, onPicked: (path) {
                                              set(path);
                                              themeChangedCount.value++;
                                              _themeChanged.value = true;
                                            });
                                          },
                                          icon: Icon(Icons.more_horiz, size: 24, color: isCustomized ? Colors.black : Colors.black45),
                                        ),
                                      ),
                                    ],
                                  );
                                }
                                return widget;
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _getSettingsTab() {
    const double minItemWidth = 410;
    const double itemHeight = 110;
    const double itemPadding = 20;
    const itemConstraints = BoxConstraints(minWidth: minItemWidth);
    final itemDecoration = BoxDecoration(
      border: Border.all(
        color: Colors.black45,
      ),
      borderRadius: const BorderRadius.all(Radius.circular(10)),
    );
    const itemTextStyle = TextStyle(fontSize: 18, color: Colors.black, overflow: TextOverflow.ellipsis);
    const helperIcon = Icon(Icons.help_outline, size: 24, color: Colors.black);
    List<Widget> items = [
      Container(
        padding: const EdgeInsets.all(itemPadding),
        constraints: itemConstraints,
        decoration: itemDecoration,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Text(
                  localization.replicability,
                  style: itemTextStyle,
                ),
                const SizedBox(width: 10),
                const Spacer(),
                Tooltip(
                  message: localization.replicabilityDesc,
                  child: helperIcon,
                ),
              ],
            ),
            const Spacer(),
            Row(
              children: [
                Text(
                  localization.uncopiable,
                  style: itemTextStyle,
                ),
                const Spacer(),
                ValueListenableBuilder<bool>(
                  valueListenable: _uncopiable,
                  builder: (context, currentState, child) {
                    return Theme(
                      data: ThemeData(
                        useMaterial3: true,
                      ),
                      child: Switch(
                        value: currentState,
                        activeColor: Colors.blue,
                        inactiveTrackColor: Colors.black12,
                        inactiveThumbColor: Colors.black,
                        trackOutlineColor: MaterialStateProperty.all(Colors.black45),
                        onChanged: (value) {
                          _settingsChanged.value = true;
                          _uncopiable.value = value;
                        },
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
      if (isDeletable) Container(
        padding: const EdgeInsets.all(itemPadding),
        constraints: itemConstraints,
        decoration: itemDecoration,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Text(
                  localization.publishingState,
                  style: itemTextStyle,
                ),
                const SizedBox(width: 10),
                const Spacer(),
                Tooltip(
                  message: localization.publishingStateDesc,
                  child: helperIcon,
                ),
              ],
            ),
            const Spacer(),
            Row(
              children: [
                Text(
                  localization.published,
                  style: itemTextStyle,
                ),
                const Spacer(),
                ValueListenableBuilder<bool>(
                  valueListenable: _publishing,
                  builder: (context, currentState, child) {
                    return Theme(
                      data: ThemeData(
                        useMaterial3: true,
                      ),
                      child: Switch(
                        value: currentState,
                        activeColor: Colors.red,
                        inactiveTrackColor: Colors.black12,
                        inactiveThumbColor: Colors.black,
                        trackOutlineColor: MaterialStateProperty.all(Colors.black45),
                        onChanged: (value) {
                          _settingsChanged.value = true;
                          _publishing.value = value;
                        },
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    ];

    return Column(
      children: [
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              //final height = constraints.maxHeight;
              const double spacing = 20;
              final columnNumber = (width / (minItemWidth + spacing + 50)).round();
              return GridView.count(
                padding: const EdgeInsets.all(20),
                crossAxisCount: columnNumber,
                childAspectRatio: (width / columnNumber - itemPadding * 2) / itemHeight,
                mainAxisSpacing: spacing,
                crossAxisSpacing: spacing,
                children: items,
              );
            },
          ),
        ),
        ValueListenableBuilder<bool>(
          valueListenable: _settingsChanged,
          builder: (context, currentState, child) {
            return Container(
              padding: EdgeInsets.symmetric(vertical: _isPhoneOrTablet ? 10 : 20, horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (isDeletable) TextButton(
                    onPressed: () {
                      if (_publishing.value) {
                        localization.changeUnpublishedFirst.asAlertDialog(
                          context: context,
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.white,
                                backgroundColor: Colors.black,
                                disabledForegroundColor: Colors.black45,
                                disabledBackgroundColor: Colors.white,
                                shape: const StadiumBorder(side: BorderSide(color: Colors.black)),
                                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                              ),
                              child: Text(localization.ok, style: const TextStyle(fontSize: 18)),
                            ),
                          ],
                        );
                        return;
                      }
                      localization.articleDeletingConfirmation.asAlertDialog(
                        context: context,
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.black,
                              backgroundColor: Colors.white,
                              disabledForegroundColor: Colors.black45,
                              disabledBackgroundColor: Colors.white,
                              shape: const StadiumBorder(side: BorderSide(color: Colors.black)),
                              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                            ),
                            child: Text(localization.no, style: const TextStyle(fontSize: 18)),
                          ),
                          const SizedBox(width: 5),
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                              _deleteArticle(context);
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.white,
                              backgroundColor: Colors.red,
                              disabledForegroundColor: Colors.black45,
                              disabledBackgroundColor: Colors.white,
                              shape: const StadiumBorder(side: BorderSide(color: Colors.red)),
                              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                            ),
                            child: Text(localization.yes, style: const TextStyle(fontSize: 18)),
                          ),
                        ],
                      );
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red,
                      backgroundColor: Colors.white,
                      disabledForegroundColor: Colors.black45,
                      disabledBackgroundColor: Colors.white,
                      shape: const StadiumBorder(side: BorderSide(color: Colors.red)),
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    ),
                    child: Text(
                      localization.delete(1),
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                  if (isDeletable) const Spacer(),
                  TextButton(
                    onPressed: !currentState ? null : () {
                      _resetSettings();
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.black,
                      backgroundColor: Colors.white,
                      disabledForegroundColor: Colors.black45,
                      disabledBackgroundColor: Colors.white,
                      shape: const StadiumBorder(side: BorderSide(color: Colors.black)),
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    ),
                    child: Text(
                      localization.reset,
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                  const SizedBox(width: 20),
                  TextButton(
                    onPressed: !currentState ? null : () {
                      _saveSettings(context);
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.black,
                      disabledForegroundColor: Colors.black45,
                      disabledBackgroundColor: Colors.white,
                      shape: const StadiumBorder(side: BorderSide(color: Colors.black)),
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    ),
                    child: Text(
                      localization.save,
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    _isPhoneOrTablet = PlatformExt.isPhoneOrTablet;
    double iconSize = _isPhoneOrTablet ? 20 : 24;
    if (_dbImages.isEmpty) {
      ImagesDB.instance.getAll().then((value) => _dbImages = value);
    }
    article ??= Article(
      title: '',
      summary: '',
      content: '',
      summaryType: ArticleTypes.text.name,
      contentType: ArticleTypes.text.name,
      tags: [],
      creatingTime: DateTime.now().secondsSinceEpoch,
      editingTime: 0,
      publishingTime: 0,
      isPublished: true,
    );
    _resetEditing();
    _resetTheme();
    _resetSettings();
    return ValueListenableBuilder<int>(
      valueListenable: _updateUiCount,
      builder: (context, currentState, child) {
        _isMobile = ResponsiveBreakpoints.of(context).isMobile;
        Size size = MediaQuery.of(context).size;
        double margin = _isMobile ? 20 : 40 ;
        double width = size.width - margin*2;
        double height = size.height - margin*2;
        double barHeight = 48;
        _currentSize = Size(width, height);
        return Dialog(
          backgroundColor: backgroundColor,
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
              color: Colors.white,
              shape: shape ?? RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Row(
              children: [
                if (!_isMobile) _getSideMenu(context),
                Expanded(
                  child: Column(
                    children: [
                      Container(
                        height: barHeight,
                        decoration: const BoxDecoration(
                          border: Border(bottom: BorderSide(color: Colors.black45)),
                        ),
                        child: Row(
                          children: [
                            if (_isMobile) Material(
                              type: MaterialType.transparency,
                              shape: const CircleBorder(),
                              clipBehavior: Clip.antiAlias,
                              child: IconButton(
                                onPressed: () {
                                  _showSideMenu(context);
                                },
                                icon: Icon(
                                  Icons.menu,
                                  size: iconSize,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                            const Spacer(),
                            Material(
                              type: MaterialType.transparency,
                              shape: const CircleBorder(),
                              clipBehavior: Clip.antiAlias,
                              child: IconButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                  if (_changesSaved) {
                                    onFinish?.call(article!);
                                  }
                                },
                                icon: Icon(
                                  Icons.cancel_outlined,
                                  size: iconSize,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        height: height - barHeight,
                        child: switch (_currentTab) {
                          ArticleEditorTabs.edit => _getEditTab(context),
                          ArticleEditorTabs.theme => _getThemeTab(context),
                          ArticleEditorTabs.settings => _getSettingsTab(),
                        },
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

extension on ArticleEditorTabs {
  String toLocalizedString(AppLocalizations localization) {
    switch (this) {
      case ArticleEditorTabs.edit:
        return localization.edit;
      case ArticleEditorTabs.theme:
        return localization.theme;
      case ArticleEditorTabs.settings:
        return localization.settings;
    }
  }
}

extension on ArticleThemeTypes {
  String toLocalizedString(AppLocalizations localization) {
    switch (this) {
      case ArticleThemeTypes.defaultTheme:
        return localization.defaultTheme;
      case ArticleThemeTypes.customized:
        return localization.customized;
    }
  }
}

extension on ArticleTypes {
  String toLocalizedString(AppLocalizations localization) {
    switch (this) {
      case ArticleTypes.text:
        return localization.text;
      case ArticleTypes.html:
        return localization.html;
      case ArticleTypes.markdown:
        return localization.markdown;
    }
  }
}
