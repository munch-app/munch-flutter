import 'package:flutter/material.dart';
import 'package:munch_app/api/search_api.dart';
import 'package:munch_app/api/user_api.dart';
import 'package:munch_app/main.dart';
import 'package:munch_app/pages/search/search_card_list.dart';
import 'package:munch_app/pages/search/search_header.dart';
import 'package:munch_app/styles/munch_bottom_dialog.dart';
import 'package:munch_app/utils/munch_analytic.dart';
import 'package:munch_app/utils/recent_database.dart';
import 'package:munch_app/utils/user_defaults_key.dart';
import 'package:url_launcher/url_launcher.dart';

class SearchPage extends StatefulWidget with TabWidget {
  static SearchPageState state = SearchPageState();

  @override
  State<StatefulWidget> createState() => state;

  @override
  void didTabAppear(TabParent parent) {
    Future.delayed(const Duration(milliseconds: 2000), () async {
      final context = state?.context;
      if (context == null) return;
      if (parent.tab != MunchTab.search) return;

      final defaults = UserDefaults.instance;

      showGiveFeedback() {
        MunchAnalytic.logEvent("notify_show_feedback");

        showBottomDialog(
          context: context,
          title: "Feed us with feedback",
          message: "Take a minute to tell us how to better serve you.",
          buttonTitle: "Give Feedback",
          buttonCallback: () async {
            String url = "https://airtable.com/shrp2EgmOUwshSZ3a";

            if (await canLaunch(url)) {
              MunchAnalytic.logEvent("notify_click_feedback");
              defaults.count(UserDefaultsKey.countGiveFeedback);
              await launch(url);
            }
          },
        );
      }

      final int openApp = await defaults.getCount(UserDefaultsKey.countOpenApp);

      if (openApp > 2) {
        defaults.notify(UserDefaultsKey.notifyGiveFeedbackV1, showGiveFeedback);

        Future.delayed(const Duration(milliseconds: 2000), () async {
          final int countFeedback = await defaults.getCount(UserDefaultsKey.countGiveFeedback);
          if (openApp > 4 && countFeedback == 0) {
            defaults.notify(UserDefaultsKey.notifyGiveFeedbackV2, showGiveFeedback);
          }
        });
      }
    });
  }
}

typedef void EditSearchQuery(SearchQuery query);

class SearchPageState extends State<SearchPage> with WidgetsBindingObserver {
  List<SearchQuery> histories = [];

  RecentSearchQueryDatabase _recentSearchQueryDatabase = RecentSearchQueryDatabase();

  SearchQuery get searchQuery {
    if (histories.isEmpty) return SearchQuery.feature(SearchFeature.Home);
    return histories.last;
  }

  SearchCardList _cardList = SearchCardList();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    UserSearchPreference.get().whenComplete(() {
      push(SearchQuery.feature(SearchFeature.Home));
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (DateTime.now().millisecondsSinceEpoch - pausedDateTime.millisecondsSinceEpoch > 1000 * 60 * 60) {
        this.reset();
      }
    }
  }

  void push(SearchQuery searchQuery) {
    histories.add(searchQuery);
    if (!searchQuery.isSimple) {
      _recentSearchQueryDatabase.put(searchQuery);
    }

    _search(searchQuery);
  }

  void edit(EditSearchQuery _edit) {
    var last = histories.last;
    if (last == null) return;

    _edit(last);
    push(last);
  }

  bool pop() {
    if (histories.length <= 1) return false;

    histories.removeLast();
    _search(searchQuery);
    return true;
  }

  void _search(SearchQuery searchQuery) {
    setState(() => {});
    _cardList.search(histories.last);
    MunchAnalytic.logSearchQuery(searchQuery: searchQuery);
  }

  void reset() {
    histories.clear();
    push(SearchQuery.feature(SearchFeature.Home));
  }

  /// Whether it is already on top
  bool scrollToTop() {
    return _cardList.state.scrollToTop();
  }

  /// Scroll to a uniqueId
  void scrollTo(String uniqueId) {
    _cardList.state.scrollTo(uniqueId);
  }

  String get qid => _cardList.state.manager?.qid;

  @override
  Widget build(BuildContext context) {
    final body = SafeArea(child: _cardList);

    return WillPopScope(
      child: Scaffold(
        backgroundColor: Colors.white,
        resizeToAvoidBottomPadding: false,
        appBar: SearchAppBar(searchQuery),
        body: body,
      ),
      onWillPop: () async {
        return !pop();
      },
    );
  }
}
