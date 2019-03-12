import 'package:munch_app/components/shimmer_image.dart';
import 'package:munch_app/pages/search/search_card.dart';
import 'package:munch_app/api/file_api.dart' as file_api;

class SearchCardClaimVoucher extends SearchCardWidget {
  final file_api.Image image;

  SearchCardClaimVoucher(SearchCard card)
      : image = file_api.Image.fromJson(card['image']),
        super(card);

  @override
  Widget buildCard(BuildContext context) {
    final width = (MediaQuery.of(context).size.width - 24 - 24);

    return AspectRatio(
      aspectRatio: 1 / 0.625,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(3),
        child: ShimmerSizeImage(
          minWidth: width,
          sizes: image.sizes,
        ),
      ),
    );
  }
}