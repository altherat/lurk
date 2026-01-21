import 'dart:ui';

enum Platform {
  
  reddit(
    color: Color(0xFFFF4500),
    communityLabel: 'subreddit',
    communityPrefix: 'r/',
    communityHome: 'popular',
    userPrefix: 'u/',
    postSorts: [
      Sort('Hot', 'hot'),
      Sort('New', 'new'),
      Sort('Top', 'top', _redditTimeRanges),
      Sort('Rising', 'rising'),
      Sort('Controversial', 'controversial', _redditTimeRanges)
    ],
    commentSorts: [
      Sort('Best', 'best'),
      Sort('Top', 'top'),
      Sort('New', 'new'),
      Sort('Controversial', 'controversial'),
      Sort('Old', 'old'),
      Sort('Q&A', 'qa')
    ],
  ),

  digg(
    color: Color(0xFF1F65DB),
    communityLabel: 'community',
    communityPrefix: '/',
    userPrefix: '@',
    postSorts: [
      Sort('Trending', 'TRENDING'),
      Sort('Most dugg', 'MOST_DUGG'),
      Sort('Latest', 'RECENT'),
      Sort('Heating up', 'HEATING_UP'),
    ],
    commentSorts: [
      Sort('Most dugg', {'score': 'DESC'}),
      Sort('Most buried', {'score': 'ASC'}),
      Sort('Newest', {'createdDate': 'DESC'}),
      Sort('Oldest', {'createdDate': 'ASC'})
    ]
  );

  final Color color;
  final String communityLabel;
  final String communityPrefix;
  final String? communityHome;
  final String userPrefix;
  final List<Sort> postSorts;
  final List<Sort> commentSorts;

  const Platform({
    required this.color,
    required this.communityLabel,
    required this.communityPrefix,
    this.communityHome,
    required this.userPrefix,
    required this.postSorts,
    required this.commentSorts
  });
  
}

const _redditTimeRanges = [
  TimeRange('Hour', 'past hour', 'hour'),
  TimeRange('Day', 'past day', 'day'),
  TimeRange('Week', 'past week', 'week'),
  TimeRange('Month', 'past month', 'month'),
  TimeRange('Year', 'past year', 'year'),
  TimeRange('All time', 'all time', 'all')
];

abstract class FeedOption {

  final String label;
  final dynamic apiValue;

  const FeedOption(
    this.label,
    this.apiValue
  );
}

class Sort extends FeedOption {

  final List<TimeRange> timeRanges;

  const Sort(
    super.label,
    super.apiValue,
    [this.timeRanges = const []]
  );

}

class TimeRange extends FeedOption {

  final String description;

  const TimeRange(
    super.label,
    this.description,
    super.apiValue
  );

}