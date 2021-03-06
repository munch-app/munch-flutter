import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:munch_app/api/api.dart';
import 'package:munch_app/api/authentication.dart';
import 'package:munch_app/api/file_api.dart';
import 'package:munch_app/api/munch_data.dart';
import 'package:munch_app/components/dialog.dart';
import 'package:munch_app/pages/places/cards/rip_card.dart';
import 'package:munch_app/pages/places/cards/rip_card_gallery.dart';
import 'package:munch_app/pages/places/rip_footer.dart';
import 'package:munch_app/pages/places/rip_header.dart';
import 'package:munch_app/pages/places/rip_image_loader.dart';
import 'package:munch_app/pages/places/rip_image_page.dart';
import 'package:munch_app/utils/munch_analytic.dart';
import 'package:munch_app/utils/user_defaults_key.dart';

class RIPPage extends StatefulWidget {
  final Place place;
  final CreditedImage focusedImage;

  const RIPPage({Key key, this.place, this.focusedImage}) : super(key: key);

  @override
  State<StatefulWidget> createState() => RIPPageState();

  static Future<T> push<T extends Object>(BuildContext context, Place place, {CreditedImage focusedImage}) {
    return Navigator.push(
      context,
      MaterialPageRoute(
        builder: (c) => RIPPage(place: place, focusedImage: focusedImage),
        settings: const RouteSettings(name: '/places'),
      ),
    );
  }
}

class RIPPageState extends State<RIPPage> {
  ScrollController controller;
  RIPImageLoader _imageLoader;
  bool _clear = true;

  PlaceData data;
  CreditedImage focusedImage;

  List<Widget> widgets = RIPCardDelegator.loading;
  List<PlaceImage> images;

  @override
  void initState() {
    super.initState();
//  Crashlytics.sharedInstance().setObjectValue(placeId, forKey: "RIPController.placeId")
    MunchApi.instance.get('/places/${widget.place.placeId}').then((res) => PlaceData.fromJson(res.data)).then(_start,
        onError: (error) {
      MunchDialog.showError(context, error);
    });

    controller = ScrollController();
    controller.addListener(_scrollListener);

    MunchAnalytic.logEvent("rip_view");
    UserDefaults.instance.count(UserDefaultsKey.countViewRip);
  }


  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  _start(PlaceData placeData) {
    this.focusedImage = widget.focusedImage;
    if (this.focusedImage == null && placeData.images.length > 0) {
      final image = placeData.images[0];

      if (image.instagram != null) {
        final instagram = image.instagram;
        this.focusedImage = CreditedImage(sizes: image.sizes, name: instagram.username, link: instagram.link);
      } else if (image.article != null) {
        final article = image.article;
        this.focusedImage = CreditedImage(sizes: image.sizes, name: article.domain.name, link: article.url);
      } else {
        this.focusedImage = CreditedImage(sizes: image.sizes);
      }
    }

    setState(() {
      this.data = placeData;
      this.images = placeData.images;
      this.widgets = RIPCardDelegator.delegate(placeData, this);
    });

    _imageLoader = RIPImageLoader();
    _imageLoader.start(placeData.place.placeId, placeData.images).listen(
      (images) {
        setState(() {
          this.images = images;
        });
      },
      onError: (error) {
        MunchDialog.showError(context, error);
      },
    );

    Authentication.instance.isAuthenticated().then((auth) {
      if (!auth) return;
      MunchApi.instance.put('/users/recent/places/${placeData.place.placeId}').catchError(
        (error) {
          MunchDialog.showError(context, error);
        },
      );
    });
  }

  _scrollListener() {
    // Check if to Load More
    if (_imageLoader.more) {
      final position = controller.position;
      if (position.pixels > position.maxScrollExtent - 100) {
        _imageLoader.append();
      }
    }

    if (controller.offset > 120) {
      if (!_clear) return;
      setState(() {
        _clear = false;
      });
    } else {
      if (_clear) return;
      setState(() {
        _clear = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> slivers = [];

    widgets.forEach((widget) {
      slivers.add(SliverToBoxAdapter(child: widget));
    });

    // If Images is loaded
    if (_imageLoader != null) {
      slivers.add(SliverPadding(
        padding: const EdgeInsets.only(top: 12, left: 24, right: 24),
        sliver: SliverStaggeredGrid.countBuilder(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          staggeredTileBuilder: (i) => StaggeredTile.fit(1),
          itemBuilder: (context, i) => RIPGalleryImageCard(image: images[i], onPressed: () => onImage(i)),
          itemCount: images.length,
        ),
      ));

      if (images.length > 0) {
        slivers.add(SliverToBoxAdapter(
          child: RIPGalleryFooterCard(loading: _imageLoader?.more ?? false),
        ));
      }
    }

    return Scaffold(
      body: Stack(children: [
        CustomScrollView(
          controller: controller,
          slivers: slivers,
        ),
        header,
      ]),
      bottomNavigationBar: RIPFooter(placeData: data),
    );
  }

  Widget get header {
    if (_clear && (data?.images?.isEmpty ?? true)) {
      return Container();
    }
    return RIPHeader(placeData: data, clear: _clear);
  }

  void onImage(int i) {
    RIPImagePage.push(
      context,
      index: i,
      imageLoader: _imageLoader,
      place: data.place,
    );
  }
}
