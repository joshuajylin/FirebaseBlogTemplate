import 'dart:html' as html;
import 'dart:math';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:firebase_blog_template/Constants.dart';
import 'package:firebase_blog_template/firebase/ImagesDB.dart';
import 'package:firebase_blog_template/models/ImageMetadata.dart';
import 'package:firebase_blog_template/models/WebsiteSettings.dart';
import 'package:firebase_blog_template/util/StringExtension.dart';
import 'package:firebase_blog_template/util/notifications.dart';
import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:flutter/material.dart';

import 'package:flutter_gen/gen_l10n/web_localizations.dart';
import 'package:flutter_gen/gen_l10n/web_localizations_en.dart';
import 'package:responsive_framework/responsive_breakpoints.dart';
import 'package:responsive_framework/responsive_framework.dart';

import '../firebase/SettingsDB.dart';
import '../firebase/ThemesDB.dart';
import '../models/WebsiteImage.dart';
import '../models/WebsiteTheme.dart';
import '../util/ImageAssets.dart';
import '../util/PlatformExtension.dart';

enum SettingsTabs {
  common,
  theme,
  images,
  about,
}

class SettingsDialog extends StatelessWidget {
  AppLocalizations localization = AppLocalizationsEn();
  WebsiteSettings settings;
  void Function(WebsiteSettings)? onFinish;
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
  SettingsTabs _currentTab = SettingsTabs.common;
  late Size _currentSize;
  final TextEditingController _pageTitleController = TextEditingController();
  final ValueNotifier<bool> _adultsOnly = ValueNotifier(false);
  final ValueNotifier<bool> _settingsChanged = ValueNotifier(false);
  late ValueNotifier<WebsiteThemeTypes> _selectedThemeType;
  late WebsiteThemeTypes _websiteThemeType;
  late WebsiteTheme _websiteTheme;
  late WebsiteTheme _customizedTheme;
  final ValueNotifier<String> _imageName = ValueNotifier('');
  final ValueNotifier<bool> _uploading = ValueNotifier(false);
  final ValueNotifier<double> _uploadingProgress = ValueNotifier(0);
  final TextEditingController _imageNameController = TextEditingController();
  final ValueNotifier<int> _dbImagesChanged = ValueNotifier(0);
  List<ImageMetadata> _dbImages = [];
  Uint8List? _imageData;
  void Function()? _cancelUploading;
  bool _isMobile = false;
  bool _isPhoneOrTablet = false;
  bool _settingsSaved = false;

  SettingsDialog({
    Key? key,
    required this.localization,
    required this.settings,
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
  }) : super(key: key) {
    try {
      _websiteThemeType = WebsiteThemeTypes.values.byName(settings.theme);
    } catch (err) {
      _websiteThemeType = WebsiteThemeTypes.light;
    }
    _selectedThemeType = ValueNotifier(_websiteThemeType);
    _websiteTheme = WebsiteTheme.defaultTheme;
    _customizedTheme = _websiteTheme;
    ThemesDB.instance.getTheme(_websiteThemeType.name).then((value) {
      _websiteTheme = value;
      _customizedTheme = _websiteTheme;
    }).catchError((err) {
      '$err'.log();
    });
  }

  void _updateUi() {
    _updateUiCount.value++;
  }

  void _resetSettings() {
    _pageTitleController.text = settings.title;
    _adultsOnly.value = settings.adultOnly;
    _selectedThemeType.value = _websiteThemeType;
    _customizedTheme = _websiteTheme;
    _settingsChanged.value = false;
  }

  void _resetImageUploading() {
    _imageData = null;
    _imageNameController.text = '';
    _imageName.value = '';
    _uploading.value = false;
    _uploadingProgress.value = 0;
    _cancelUploading = null;
  }

  void _saveSettings(BuildContext context) async {
    settings.title = _pageTitleController.text.trim();
    settings.adultOnly = _adultsOnly.value;
    _websiteThemeType = WebsiteThemeTypes.values.byName(_selectedThemeType.value.name);
    settings.theme = _websiteThemeType.name;
    switch (_websiteThemeType) {
      case WebsiteThemeTypes.light:
        _websiteTheme = WebsiteTheme.light;
      case WebsiteThemeTypes.dark:
        _websiteTheme = WebsiteTheme.dark;
      case WebsiteThemeTypes.customized:
        _websiteTheme = _customizedTheme;
        ThemesDB.instance.set(_websiteTheme).catchError((err) {
          '$err'.log();
          _settingsChanged.value = true;
          showErrorNotification(context: context, description: err.toString());
        });
    }
    final dismiss = localization.saving.asLoadingIndicator(context: context);
    bool success = true;
    String errMsg = '';
    await SettingsDB.instance.set(settings).catchError((err) {
      '$err'.log();
      success = false;
      errMsg = err.toString();
    }).whenComplete(() {
      dismiss();
      if (success) {
        _settingsChanged.value = false;
        _settingsSaved = true;
      } else {
        showErrorNotification(context: context, description: errMsg);
      }
    });
  }

  Widget _getSideMenu(BuildContext context, {bool isIndependent = false}) {
    const double headerPadding = 16;
    final headerText = localization.settings;
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
    const items = SettingsTabs.values;
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
                localization.settings,
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
    const textStyle = TextStyle(fontSize: 18, color: Colors.black, overflow: TextOverflow.ellipsis);
    var menuItemHeight = ImageAssets.all.map((e) {
      final height = e.name.calculateTextSize(context: context, style: textStyle).height;
      return height;
    }).reduce(max);
    final emptyImage = WebsiteImage(name: '', url: '', locationType: ImageLocationTypes.internal.name);
    List<WebsiteImage> websiteImages = [emptyImage];
    ValueNotifier<WebsiteImage> currentImage = ValueNotifier(emptyImage);
    websiteImages = _dbImages.map((e) => WebsiteImage(name: e.name ?? '', url: e.url ?? '', locationType: ImageLocationTypes.cloudStorage.name)).toList();
    websiteImages.insertAll(0, ImageAssets.all);
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

  Widget _getCommonTab() {
    _resetSettings();
    _pageTitleController.text = settings.title;
    _adultsOnly.value = settings.adultOnly;

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
                  localization.pageTitle,
                  style: itemTextStyle,
                ),
                const SizedBox(width: 10),
                const Spacer(),
                Tooltip(
                  message: localization.pageTitleDesc,
                  child: helperIcon,
                ),
              ],
            ),
            const Spacer(),
            SizedBox(
              height: 30,
              child: TextFormField(
                controller: _pageTitleController,
                autofocus: false,
                textCapitalization: TextCapitalization.none,
                enableIMEPersonalizedLearning: false,
                style: const TextStyle(fontSize: 18, color: Colors.black),
                decoration: const InputDecoration(
                  contentPadding: EdgeInsets.symmetric(horizontal: 8),
                  border: OutlineInputBorder(borderSide: BorderSide(color: Colors.black45, width: 1)),
                ),
                onChanged: (value) {
                  _settingsChanged.value = true;
                },
              ),
            ),
          ],
        ),
      ),
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
                  localization.contentRating,
                  style: itemTextStyle,
                ),
                const SizedBox(width: 10),
                const Spacer(),
                Tooltip(
                  message: localization.contentRatingDesc,
                  child: helperIcon,
                ),
              ],
            ),
            const Spacer(),
            Row(
              children: [
                Text(
                  localization.adultsOnly,
                  style: itemTextStyle,
                ),
                const Spacer(),
                ValueListenableBuilder<bool>(
                  valueListenable: _adultsOnly,
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
                          _adultsOnly.value = value;
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

  Widget _getThemeTab(BuildContext context) {
    _resetSettings();

    const textStyle = TextStyle(fontSize: 18, color: Colors.black, overflow: TextOverflow.ellipsis);
    final menuItemHeight = WebsiteThemeTypes.values.map((e) {
      final height = e
          .toLocalizedString(localization)
          .calculateTextSize(context: context, style: textStyle)
          .height;
      return height;
    }).reduce(max);

    List<(String, String, dynamic Function(), void Function(dynamic))> themeColors = [
      (localization.bgColor, localization.bgColor, () => Color(_customizedTheme.bgColor), (color) => _customizedTheme.bgColor = color.value),
      (localization.bgBoxColor, localization.bgBoxColor, () => Color(_customizedTheme.bgBoxColor), (color) => _customizedTheme.bgBoxColor = color.value),

      (localization.toolbarColor, localization.toolbarColor, () => Color(_customizedTheme.toolbarTheme.barColor), (color) => _customizedTheme.toolbarTheme.barColor = color.value),
      (localization.toolbarBgColor, localization.toolbarBgColor, () => Color(_customizedTheme.toolbarTheme.bgColor), (color) => _customizedTheme.toolbarTheme.bgColor = color.value),
      (localization.toolbarFgColor, localization.toolbarFgColor, () => Color(_customizedTheme.toolbarTheme.fgColor), (color) {
        _customizedTheme.toolbarTheme.fgColor = color.value;
        _customizedTheme.toolbarTheme.borderColor = color.value;
        _customizedTheme.toolbarTheme.iconColor = color.value;
        _customizedTheme.toolbarTheme.textColor = color.value;
      }),
      (localization.toolbarBorderColor, localization.toolbarBorderColorDesc, () => Color(_customizedTheme.toolbarTheme.borderColor), (color) =>
      _customizedTheme.toolbarTheme.borderColor = color.value),
      (localization.toolbarIconColor, localization.toolbarIconColorDesc, () => Color(_customizedTheme.toolbarTheme.iconColor), (color) => _customizedTheme.toolbarTheme.iconColor = color.value),
      (localization.toolbarTextColor, localization.toolbarTextColorDesc, () => Color(_customizedTheme.toolbarTheme.textColor), (color) => _customizedTheme.toolbarTheme.textColor = color.value),

      (localization.articleBgColor, localization.articleBgColorDesc, () => Color(_customizedTheme.articleTheme.bgColor), (color) {
        _customizedTheme.articleTheme.bgColor = color.value;
        _customizedTheme.articleTheme.summaryBoxColor = (color.value & 0x00FFFFFF) | 0x7F000000;
        _customizedTheme.articleTheme.summaryBoxHoverColor = (color.value & 0x00FFFFFF) | 0xAA000000;
        _customizedTheme.articleTheme.contentBgColor = color.value;
      }),
      (localization.articleFgColor, localization.articleFgColorDesc, () => Color(_customizedTheme.articleTheme.fgColor), (color) {
        _customizedTheme.articleTheme.fgColor = color.value;
        _customizedTheme.articleTheme.borderColor = color.value;
        _customizedTheme.articleTheme.summaryTextColor = color.value;
        _customizedTheme.articleTheme.contentTextColor = color.value;
      }),
      (localization.articleBorderColor, localization.articleBorderColorDesc, () => Color(_customizedTheme.articleTheme.borderColor), (color) =>
      _customizedTheme.articleTheme.borderColor = color.value),
      (localization.articleSummaryBoxColor, localization.articleSummaryBoxColorDesc, () => Color(_customizedTheme.articleTheme.summaryBoxColor), (color) =>
      _customizedTheme.articleTheme.summaryBoxColor = color.value),
      (localization.articleSummaryBoxHoverColor, localization.articleSummaryBoxHoverColorDesc, () => Color(_customizedTheme.articleTheme.summaryBoxHoverColor), (color) =>
      _customizedTheme.articleTheme.summaryBoxHoverColor = color.value),
      (localization.articleSummaryTextColor, localization.articleSummaryTextColorDesc, () => Color(_customizedTheme.articleTheme.summaryTextColor), (color) =>
      _customizedTheme.articleTheme.summaryTextColor = color.value),
      (localization.articleContentBgColor, localization.articleContentBgColorDesc, () => Color(_customizedTheme.articleTheme.contentBgColor), (color) =>
      _customizedTheme.articleTheme.contentBgColor = color.value),
      (localization.articleContentTextColor, localization.articleContentTextColorDesc, () => Color(_customizedTheme.articleTheme.contentTextColor), (color) =>
      _customizedTheme.articleTheme.contentTextColor = color.value),
    ];
    List<(String, String, dynamic Function(), void Function(dynamic))> themeImages = [
      (localization.articleCoverImage, localization.articleCoverImageDesc, () => _customizedTheme.articleTheme.coverImage ?? '', (path) {
        _customizedTheme.articleTheme.coverImage = path;
        _customizedTheme.articleTheme.portraitCoverImage = path;
        _customizedTheme.articleTheme.landscapeCoverImage = path;
      }),
      (localization.articlePortraitCoverImage, localization.articlePortraitCoverImageDesc, () => _customizedTheme.articleTheme.portraitCoverImage ?? '', (path) =>
      _customizedTheme.articleTheme.portraitCoverImage = path),
      (localization.articleLandscapeCoverImage, localization.articleLandscapeCoverImageDesc, () => _customizedTheme.articleTheme.landscapeCoverImage ?? '', (path) =>
      _customizedTheme.articleTheme.landscapeCoverImage = path),
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
                  ValueListenableBuilder<WebsiteThemeTypes>(
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
                        child: DropdownButton<WebsiteThemeTypes>(
                          value: _selectedThemeType.value,
                          style: const TextStyle(fontSize: 18, color: Colors.black),
                          alignment: AlignmentDirectional.center,
                          dropdownColor: Colors.white,
                          focusColor: Colors.transparent,
                          iconEnabledColor: Colors.black,
                          borderRadius: BorderRadius.circular(10),
                          underline: Container(),
                          items: WebsiteThemeTypes.values.map<DropdownMenuItem<WebsiteThemeTypes>>((e) =>
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
                            ThemesDB.instance.getTheme(type.name, defaultTheme: _customizedTheme).then((value) {
                              _customizedTheme = value;
                              _selectedThemeType.value = type;
                              _settingsChanged.value = true;
                            }).catchError((err) {
                              '$err'.log();
                            });
                          },
                        ),
                      );
                    },
                  ),
                ],
              ),
              const Spacer(),
              ValueListenableBuilder<bool>(
                valueListenable: _settingsChanged,
                builder: (context, currentState, child) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
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
                      const SizedBox(height: 8),
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
                  return ValueListenableBuilder<WebsiteThemeTypes>(
                    valueListenable: _selectedThemeType,
                    builder: (context, currentState, child) {
                      final isCustomized = (currentState == WebsiteThemeTypes.customized);
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
                                          _settingsChanged.value = true;
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
                                              contentPadding: EdgeInsets.symmetric(horizontal: 8),
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
                                              _settingsChanged.value = true;
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

  Widget _getImagesTab(BuildContext context) {
    const textStyle = TextStyle(fontSize: 18, color: Colors.black, overflow: TextOverflow.ellipsis);
    final buttonWidth = [localization.select, localization.upload].map((e) {
      final width = e.calculateTextSize(context: context, style: textStyle).width;
      return width;
    }).reduce(max) + 16*2;
    final buttonHeight = [localization.select, localization.upload].map((e) {
      final height = e.calculateTextSize(context: context, style: textStyle).height;
      return height;
    }).reduce(max) + (_isPhoneOrTablet ? 8*2 : 4*2);
    MenuController menuController = MenuController();

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final width = constraints.maxWidth;
        //final height = constraints.maxHeight;
        const double padding = 20;
        const double imageSize = 100;
        double pathWidth = width - padding - buttonWidth - padding + 0 - padding - imageSize - padding;
        bool isColumnType = false;
        if (pathWidth < 200) {
          isColumnType = true;
          pathWidth += imageSize + padding;
        }

        const double itemPadding = 20;
        const double itemImgSize = 200;
        const double minItemWidth = itemImgSize + itemPadding*2;
        const double itemHeight = minItemWidth + 40;
        const itemConstraints = BoxConstraints(minWidth: minItemWidth);
        final itemDecoration = BoxDecoration(
          border: Border.all(
            color: Colors.black45,
          ),
          borderRadius: const BorderRadius.all(Radius.circular(10)),
        );
        const helperIcon = Icon(Icons.help_outline, size: 24, color: Colors.black);
        const disabledHelperIcon = Icon(Icons.help_outline, size: 24, color: Colors.black45);
        const double spacing = 20;
        final columnNumber = (width / (minItemWidth + spacing + 50)).round();
        return Column(
          children: [
            Container(
              padding: const EdgeInsets.all(padding),
              decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: Colors.black45))
              ),
              child: ValueListenableBuilder<String>(
                valueListenable: _imageName,
                builder: (context, currentState, child) {
                  return ResponsiveRowColumn(
                    layout: isColumnType ? ResponsiveRowColumnType.COLUMN : ResponsiveRowColumnType.ROW,
                    children: [
                      ResponsiveRowColumnItem(
                        child: Column(
                          children: [
                            Row(
                              children: [
                                SizedBox(
                                  width: buttonWidth,
                                  height: buttonHeight,
                                  child: ValueListenableBuilder<bool>(
                                    valueListenable: _uploading,
                                    builder: (context, currentState, child) {
                                      return TextButton(
                                        onPressed: currentState ? null : () {
                                          FilePicker.platform.pickFiles().then((value) {
                                            if (value != null) {
                                              _imageData = value.files.first.bytes;
                                              final fileName = value.files.first.name;
                                              _imageNameController.text = fileName;
                                              _imageName.value = fileName;
                                            }
                                          });
                                        },
                                        style: TextButton.styleFrom(
                                          foregroundColor: Colors.black,
                                          backgroundColor: Colors.white,
                                          disabledForegroundColor: Colors.black45,
                                          disabledBackgroundColor: Colors.white,
                                          shape: const StadiumBorder(side: BorderSide(color: Colors.black)),
                                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                                          textStyle: textStyle,
                                        ),
                                        child: Text(localization.select),
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(width: padding),
                                SizedBox(
                                  width: pathWidth,
                                  height: buttonHeight,
                                  child: TextFormField(
                                    controller: _imageNameController,
                                    autofocus: false,
                                    readOnly: true,
                                    textCapitalization: TextCapitalization.none,
                                    enableIMEPersonalizedLearning: false,
                                    style: textStyle,
                                    decoration: const InputDecoration(
                                      contentPadding: EdgeInsets.symmetric(horizontal: 8),
                                      border: OutlineInputBorder(borderSide: BorderSide(color: Colors.black45, width: 1)),
                                    ),
                                  ),
                                ),
                                if (!isColumnType) const SizedBox(width: padding),
                              ],
                            ),
                            const SizedBox(height: padding),
                            Row(
                              children: [
                                SizedBox(
                                  width: buttonWidth,
                                  height: buttonHeight,
                                  child: ValueListenableBuilder<bool>(
                                    valueListenable: _uploading,
                                    builder: (context, currentState, child) {
                                      return TextButton(
                                        onPressed: (_imageData == null || _imageName.value.isEmpty) ? null : () {
                                          if (currentState) {
                                            _cancelUploading?.call();
                                          } else {
                                            _uploading.value = true;
                                            _cancelUploading = ImagesDB.instance.upload(
                                              imageData: _imageData!,
                                              fileName: _imageName.value,
                                              onFailure: (isCancelled) {
                                                _resetImageUploading();
                                                if (!isCancelled) {
                                                  showErrorNotification(context: context, description: localization.failedToUploadImage);
                                                }
                                              },
                                              onSuccess: (image) {
                                                _resetImageUploading();
                                                _dbImages.add(image);
                                                _dbImagesChanged.value++;
                                              },
                                              onProgress: (progress) {
                                                _uploadingProgress.value = progress;
                                              },
                                            );
                                          }
                                        },
                                        style: TextButton.styleFrom(
                                          foregroundColor: Colors.black,
                                          backgroundColor: Colors.white,
                                          disabledForegroundColor: Colors.black45,
                                          disabledBackgroundColor: Colors.white,
                                          shape: const StadiumBorder(side: BorderSide(color: Colors.black)),
                                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                                          textStyle: textStyle,
                                        ),
                                        child: Text(currentState ? localization.cancel : localization.upload),
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(width: padding),
                                SizedBox(
                                  width: pathWidth,
                                  child: ValueListenableBuilder<double>(
                                    valueListenable: _uploadingProgress,
                                    builder: (context, currentState, child) {
                                      return LinearProgressIndicator(
                                        minHeight: buttonHeight,
                                        value: currentState,
                                      );
                                    },
                                  ),
                                ),
                                if (!isColumnType) const SizedBox(width: padding),
                              ],
                            ),
                          ],
                        ),
                      ),
                      if (isColumnType) const ResponsiveRowColumnItem(child: SizedBox(height: padding)),
                      ResponsiveRowColumnItem(
                        child: SizedBox(
                          width: imageSize,
                          height: imageSize,
                          child: (_imageData != null) ? Image.memory(_imageData!, fit: BoxFit.contain) : Image.asset('images/transparent.png', fit: BoxFit.fitWidth),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            Expanded(
              child: ValueListenableBuilder<int>(
                valueListenable: _dbImagesChanged,
                builder: (context, currentState, child) {
                  return GridView.builder(
                    padding: const EdgeInsets.all(padding),
                    itemCount: _dbImages.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columnNumber,
                      childAspectRatio: (width / columnNumber - itemPadding * 2) / itemHeight,
                      mainAxisSpacing: spacing,
                      crossAxisSpacing: spacing,
                    ),
                    itemBuilder: (context, index) {
                      final imageMetadata = _dbImages[index];
                      final imageUrl = imageMetadata.url ?? '';
                      final imageName = imageMetadata.name ?? '';
                      return Container(
                        constraints: itemConstraints,
                        decoration: itemDecoration,
                        child: Stack(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(itemPadding),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Align(
                                    alignment: Alignment.center,
                                    child: Image.network(imageUrl, width: itemImgSize, height: itemImgSize, fit: BoxFit.contain),
                                  ),
                                  Text(imageName, textAlign: TextAlign.center, style: textStyle),
                                ],
                              ),
                            ),
                            Align(
                              alignment: Alignment.topRight,
                              child: Material(
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
                                        html.window.navigator.clipboard?.writeText(imageUrl);
                                      },
                                    ),
                                    MenuItemButton(
                                      child: Row(
                                        children: [
                                          const Icon(Icons.delete_outline, size: 24, color: Colors.red),
                                          const SizedBox(width: 8),
                                          Text(localization.delete(0), style: const TextStyle(fontSize: 16, color: Colors.red)),
                                        ],
                                      ),
                                      onPressed: () {
                                        localization.deleteImageConfirmation(imageName).asAlertDialog(
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
                                              child: Text(
                                                localization.no,
                                                style: const TextStyle(fontSize: 18),
                                              ),
                                            ),
                                            const SizedBox(width: 5),
                                            TextButton(
                                              onPressed: () {
                                                Navigator.of(context).pop();
                                                _dbImages.remove(imageMetadata);
                                                _dbImagesChanged.value++;
                                                ImagesDB.instance.delete(imageMetadata).then((value) {
                                                  '$imageName deleted.'.log();
                                                }).catchError((err) {
                                                  '$err'.log();
                                                });
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
                                    icon: const Icon(
                                      Icons.more_vert,
                                      size: 24,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _getAboutTab() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Align(
        alignment: Alignment.topLeft,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(localization.productDesc, style: const TextStyle(fontSize: 18, color: Colors.black)),
            const SizedBox(height: 20),
            Text(localization.versionDesc(Constants.version), style: const TextStyle(fontSize: 18, color: Colors.black)),
            const SizedBox(height: 20),
            Text(localization.authorDesc, style: const TextStyle(fontSize: 18, color: Colors.black)),
            const SizedBox(height: 20),
            Text(localization.emailDesc, style: const TextStyle(fontSize: 18, color: Colors.black)),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    _isPhoneOrTablet = PlatformExt.isPhoneOrTablet;
    double iconSize = _isPhoneOrTablet ? 20 : 24;
    if (_dbImages.isEmpty) {
      ImagesDB.instance.getAll().then((value) => _dbImages = value);
    }
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
                                  if (_settingsSaved) {
                                    onFinish?.call(settings);
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
                          SettingsTabs.common => _getCommonTab(),
                          SettingsTabs.theme => _getThemeTab(context),
                          SettingsTabs.images => _getImagesTab(context),
                          SettingsTabs.about => _getAboutTab(),
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

extension on SettingsTabs {
  String toLocalizedString(AppLocalizations localization) {
    switch (this) {
      case SettingsTabs.common:
        return localization.common;
      case SettingsTabs.theme:
        return localization.theme;
      case SettingsTabs.images:
        return localization.images;
      case SettingsTabs.about:
        return localization.about;
    }
  }
}
