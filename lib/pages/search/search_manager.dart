import 'dart:async';
import 'package:flutter/foundation.dart';

import 'package:munch_app/api/api.dart';
import 'package:munch_app/api/search_api.dart';
import 'package:munch_app/api/structured_exception.dart';
import 'package:munch_app/pages/search/cards/search_card_local.dart';
import 'package:munch_app/utils/munch_analytic.dart';
import 'package:munch_app/utils/munch_location.dart';

class SearchManager {
  static const MunchApi _api = MunchApi.instance;

  final SearchQuery searchQuery;

  String _qid;
  int _page = 0;

  List<SearchCard> _cards = [];

  /// Whether this card manager is currently loading more content
  bool _loading = false;

  bool get loading => _loading;

  /// Whether this card manager still contains more content to be loaded  bool more = true;
  bool _more = true;

  bool get more => _more;

  String get qid => _qid;

  StreamController<List<SearchCard>> _controller;

  SearchManager(this.searchQuery);

  Stream<List<SearchCard>> stream() {
    _controller = StreamController<List<SearchCard>>();
    _controller.add([
      SearchCard.cardId("SearchCardShimmer"),
      SearchCard.cardId("SearchCardShimmer"),
      SearchCard.cardId("SearchCardShimmer"),
    ]);
    return _controller.stream;
  }

  void dispose() {
    _controller.close();
  }

  /// Start the stream of cards,
  /// The stream output the entire list.
  Future start() async {
    return MunchLocation.instance.request().then(
      (latLng) {
        if (_cards.length == 1 && _cards[0]?.cardId == 'SearchCardError') {
          _cards = [];
        }
      },
      onError: (error) {
        debugPrint(error);
        _controller.addError('LocationError');
      },
    ).whenComplete(() {
      return _search();
    });
  }

  Future append() {
    return _search();
  }

  Future _search() {
    if (_loading || !_more) return Future.value();

    _loading = true;
    var body = searchQuery.toJson();
    return _api.post('/search?page=$_page', body: body).then((res) {
      if (_page == 0) {
        _qid = res['qid'];
      }

      List<dynamic> list = res.data;
      var cards = list.map((data) => SearchCard(data));
      return cards.toList(growable: false);
    }).then((List<SearchCard> cards) {
      // Append parsed cards
      this._append(cards);
      this._more = cards.isNotEmpty;
      this._page += 1;

      MunchAnalytic.logSearchQueryAppend(searchQuery: searchQuery, cards: _cards, page: _page);
    }, onError: (error) {
      if (error is DeprecatedException) {
        _append([SearchCard.cardId("SearchCardUnsupported")]);
      } else if (error is StructuredException) {
        _append([SearchCardError.error(error)]);
      } else {
        _append([SearchCardError.error(error)]);
      }
      this._more = false;
    }).whenComplete(() {
      this._loading = false;
      _controller.add(_cards);
    });
  }

  void _append(List<SearchCard> cards) {
    cards.forEach((card) {
      if (_cards.contains(card)) return;
      _cards.add(card);
    });
  }
}
