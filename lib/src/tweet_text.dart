import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:html_unescape/html_unescape_small.dart';
import 'package:tweet_ui/models/api/entieties/hashtag_entity.dart';
import 'package:tweet_ui/models/api/entieties/mention_entity.dart';
import 'package:tweet_ui/models/api/entieties/symbol_entity.dart';
import 'package:tweet_ui/models/api/entieties/url_entity.dart';
import 'package:tweet_ui/models/viewmodels/tweet_vm.dart';
import 'package:tweet_ui/src/url_launcher.dart';

class TweetText extends StatelessWidget {
  TweetText(
    this.tweetVM, {
    Key key,
    this.textStyle,
    this.clickableTextStyle,
  }) : super(key: key);

  final TweetVM tweetVM;
  final TextStyle textStyle;
  final TextStyle clickableTextStyle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width,
      child: RichText(
        textAlign: TextAlign.start,
        text: TextSpan(
          children: _getSpans(context),
        ),
      ),
    );
  }

  List<TextSpan> _getSpans(BuildContext context) {
    List<TextSpan> spans = [];
    int boundary = 0;
    var unescape = new HtmlUnescape();

    if (tweetVM.allEntities.isEmpty) {
      spans.add(TextSpan(
        text: unescape.convert(tweetVM.text),
      ));
    } else {
      if (tweetVM.allEntities.length > 1) {
        tweetVM.allEntities.asMap().forEach((index, entity) {
          if (index == tweetVM.allEntities.length - 1) {
            return;
          }
          // look for the next match
          final startIndex = entity.start;

          // add any plain text before the next entity
          if (startIndex > boundary) {
            spans.add(TextSpan(
              text: unescape.convert(String.fromCharCodes(tweetVM.textRunes, boundary, startIndex)),
              style: textStyle,
            ));
          }

          if (entity.runtimeType == UrlEntity) {
            UrlEntity urlEntity = (entity as UrlEntity);
            final spanText = unescape.convert(urlEntity.displayUrl);
            spans.add(TextSpan(
              text: spanText,
              style: clickableTextStyle,
              recognizer: TapGestureRecognizer()
                ..onTap = () async {
                  openUrl(urlEntity.url);
                },
            ));
          } else {
            final spanText = unescape.convert(
              String.fromCharCodes(tweetVM.textRunes, startIndex, entity.end),
            );
            spans.add(TextSpan(
              text: spanText,
              style: clickableTextStyle,
              recognizer: TapGestureRecognizer()
                ..onTap = () async {
                  if (entity.runtimeType == MentionEntity) {
                    MentionEntity mentionEntity = (entity as MentionEntity);
                    openUrl("https://twitter.com/${mentionEntity.screenName}");
                  } else if (entity.runtimeType == SymbolEntity) {
                    SymbolEntity symbolEntity = (entity as SymbolEntity);
                    openUrl("https://twitter.com/search?q=${symbolEntity.text}");
                  } else if (entity.runtimeType == HashtagEntity) {
                    HashtagEntity hashtagEntity = (entity as HashtagEntity);
                    openUrl("https://twitter.com/hashtag/${hashtagEntity.text}");
                  }
                },
            ));
          }

          // update the boundary to know from where to start the next iteration
          boundary = entity.end;
        });

        spans.add(TextSpan(
          text: unescape.convert(String.fromCharCodes(tweetVM.textRunes, boundary, tweetVM.allEntities.last.start)),
          style: textStyle,
        ));
      } else {
        spans.add(TextSpan(
          text: unescape.convert(String.fromCharCodes(tweetVM.textRunes, 0, tweetVM.allEntities.first.start)),
          style: textStyle,
        ));
      }
    }

    return spans;
  }
}
