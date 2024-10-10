import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class PhotoPage extends StatefulWidget {
  final String title;
  final String url;
  const PhotoPage({super.key, required this.url, required this.title});

  @override
  _PhotoPageState createState() => _PhotoPageState();
}

class _PhotoPageState extends State<PhotoPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Text(widget.title),
      ),
      body: InkWell(
        onTap: () {
          Navigator.pop(context);
        },
        child: Center(
          child: CachedNetworkImage(
            imageUrl: widget.url,
            errorWidget: (context, v, d) {
              return Image.asset("assets/images/sharshara.png");
            },
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}
