import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/mysettings.dart';

class PhotoInfoPage extends StatefulWidget {
  final String title;
  final String url;
  const PhotoInfoPage({super.key, required this.url, required this.title});

  @override
  PhotoInfoPageState createState() => PhotoInfoPageState();
}

class PhotoInfoPageState extends State<PhotoInfoPage> with SingleTickerProviderStateMixin {
  final TransformationController _transformationController = TransformationController();
  TapDownDetails _doubleTapDetails = TapDownDetails();
  bool _zoomed = false;

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  void _handleDoubleTap() {
    if (_zoomed) {
      _transformationController.value = Matrix4.identity();
      _zoomed = false;
    } else {
      final position = _doubleTapDetails.localPosition;
      const double scale = 2.0;

      _transformationController.value = Matrix4.identity()
        ..translate(-position.dx * (scale - 1), -position.dy * (scale - 1))
        ..scale(scale);

      _zoomed = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<MySettings>(context);
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Text(widget.title),
      ),
      body: GestureDetector(
        onTapDown: (details) {
          _doubleTapDetails = details;
        },
        onDoubleTap: _handleDoubleTap,
        child: Center(
          child: InteractiveViewer(
            transformationController: _transformationController,
            panEnabled: true,
            scaleEnabled: true,
            child: CachedNetworkImage(
              imageUrl: getLocalizedImageUrl(widget.url, settings.locale.languageCode),
              fit: BoxFit.contain,
              placeholder: (context, url) => const CircularProgressIndicator(),
              errorWidget: (context, v, d) {
                return Image.asset("assets/images/no_image.jpg");
              },
            ),
          ),
        ),
      ),
    );
  }

  String getLocalizedImageUrl(String url, String languageCode) {
    const language = ['ru', 'en', 'uz', 'ar'];
    if (language.contains(languageCode)) {
      return url.replaceFirst('/pics/', '/pics/${languageCode}_');
    }
    return url;
  }

}
