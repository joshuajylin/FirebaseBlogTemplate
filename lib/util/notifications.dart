import 'package:elegant_notification/elegant_notification.dart';
import 'package:flutter/cupertino.dart';

void showErrorNotification({required BuildContext context, required String description, String? title}) {
  ElegantNotification.error(
    title: (title != null) ? Text(title) : null,
    description: Text(description),
  ).show(context);
}