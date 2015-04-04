# Rails Retweeter Bot

This is the source of the bot tweeting at [@rails_bot](https://twitter.com/rails_bot). I'm putting it here in case someone wants to reuse it to make another bot, or offer suggestions to tweak @rails_bot.

## The idea

The are a lot of people in the Ruby/Rails community that I'd like to follow. However, in order to read their interesting tweets I'd also have to agree to read all the other things they tweet, and then I wouldn't do anything else than read tweets all day.

Basically, I want to read this:

<blockquote class="twitter-tweet"><p>Thanks @<a href="https://twitter.com/steveklabnik">steveklabnik</a> for reminding me about this article. Every programmer should read it: <a href="http://t.co/1CgfnckT" title="http://www.kalzumeus.com/2010/06/17/falsehoods-programmers-believe-about-names/">kalzumeus.com/2010/06/17/fal…</a></p>&mdash; Aaron Patterson (@tenderlove) <a href="https://twitter.com/tenderlove/status/241645297019801602" data-datetime="2012-08-31T21:15:03+00:00">August 31, 2012</a></blockquote>
<script async src="//platform.twitter.com/widgets.js" charset="utf-8"></script>

But not this:

<blockquote class="twitter-tweet tw-align-left" width="350"><p>Just saw a poo that looked like a starfish.</p>&mdash; Aaron Patterson (@tenderlove) <a href="https://twitter.com/tenderlove/status/257938626736971776" data-datetime="2012-10-15T20:18:55+00:00">October 15, 2012</a></blockquote>

(sorry, Aaron...)

What I need is someone that would follow all these people, read all their tweets and retweet only what seems important. This bot is my attempt at creating such filter.

## How it works

The basic idea was that the best tweets get retweeted a lot, so I made the bot select tweets with a high number of retweets. Adding favorites improved things further, because a lot of tweets get many favorites but not many retweets (especially some useful but not funny tweets from [@ruby_news](https://twitter.com/ruby_news) or [@rubyflow](https://twitter.com/rubyflow) - the funny ones get retweeted the most). I've ignored the tweets of people from outside the selected group retweeted by people in the group, because almost all of them were off topic.

Now I had most of the interesting tweets marked to be retweeted, but most of the top tweets were still not relevant - funny tweets about random things, tweets about politics, current news, Apple, Microsoft, startups, religion, etc. So then I've added a keyword whitelist - I went through the top tweets and I've prepared a list of keywords that would only match the tweets I'd like to see retweeted. Later I've also added a blacklist in order to ignore tweets that matched some "good" words, but also included some "bad" words too (a blacklist match trumps a whitelist match). (Note: I'm using the words good/bad/whitelist/blacklist only to refer to being relevant or irrelevant to what I want to see the bot tweet about - I realize that a lot of blacklisted topics are important, I simply want this bot to focus only on purely technical content, since that's easiest to judge algorithmically.)

I've also made the minimum number of retweets+favorites depend on the author - those with a high number of followers get much more retweets on average, so a post with 30 retweets by [@spastorino](https://twitter.com/spastorino) (3871 followers) will usually be more interesting than a post with 30 retweets by [@dhh](https://twitter.com/dhh) (72141 followers).

The end result is that even though some good tweets are ignored and some off topic tweets get retweeted, the filter works surprisingly well in most cases. It should retweet about 4 tweets per day on average, which sounds like an acceptable number.

## How to use

First, you need a Twitter account to tweet from. You'll want a fresh account only for that purpose. The bot selects the tweets to retweet from what it sees on its home timeline, so the list of people to be observed and retweeted is simply the bot account's "following" list. Log in as the bot's account and follow any people that you'd like to see retweeted.

Next, clone the repository and run `bundle install`. Create a `config.yml` file based on the example file. Go to Twitter's developer site and register an application there (it doesn't technically have to be owned by the bot), then copy the first two keys to the config. Then use the `oauth_generator.rb` script to get the other two keys (here you need to sign in with the bot's account!).

Then you can use any of these:

### ./bot retweet

Loads 200 last tweets from the timeline (ignoring retweets) and retweets the ones that match the filter and weren't retweeted yet. 200 last tweets includes tweets from the last 2 days on average in @rails_bot's case (I think most tweets will get most of their retweets and favorites in the first 2 days anyway).

### ./bot fetch data.json

Downloads last 3 months of tweets from each of the followed people and saves them as a JSON file.

### ./bot cached data.json

Starts a web UI that you can use to tweak the filter and see which tweets get marked. Uses the JSON file created above. This is useful for tweaking whitelists, blacklists, followed user list etc. - you can easily test which tweets are matched and which aren't without having to redownload the data constantly. This is important because there are pretty strict usage limits in Twitter's API, and if you load too much within an hour, you will be blocked until the next hour.

### ./bot live

Starts a web UI, downloading tweets on demand. This is useful for checking new profiles to see if it's worth adding them to the list.

## How to customize the bot

To make the bot useful for you, apart from the followed user list you will probably need to tweak some of its parameters like keywords and threshold values to make it focus on the specific content you're interested in.

### Edit keywords that will not be retweeted in 'keywords_blacklist.txt'

These are the words that you DO NOT want included in any of your retweets. If any of those words and expressions match, the tweet will not be retweeted regardless of what else is in it, who tweeted it or how popular it is. Use the original list as an example of how the patterns should look and prepare a list that will work for you.

The file is basically a list of Ruby regular expression patterns, each on a separate line, without any opening and closing symbols. As you can see from the original list, it can include things like alternative or optional parts, wildcards etc. Also, a word break symbol is automatically added at the beginning and end of the pattern, so they only match full words, not parts of words.

Two additional exceptions: a pattern in quotes (`"FOO"`) means that the pattern is case-sensitive, and a pattern in slashes (`/foo/`) means that it will be used as is without adding the word break symbols.

### Edit words that will be retweeted in 'keywords_whitelist.txt'

The list of words in this text file are the words that you DO want included in your retweets. Matching a word from this list is a requirement, i.e. a tweet will only be considered at all if it matches something on this list. Technically the list is built in the same way as the blacklist. Again, use the example list from @rails_bot to prepare a list of words that are relevant for you and that you want included in your retweets.

### Change retweet threshold in 'tweet_presenter.rb'  

If you look in `tweet_presenter.rb` and find the `user_awesomeness_threshold` function, you can customize the threshold values that determine which retweets get retweeted. The way the threshold works is that if the number of retweets + the number of favorites on a given tweet is greater than or equal to a threshold (which depends on the number of followers its author has), then that tweet will be retweeted.

The function currently uses a pretty strange expression that was simply created by trial and error to fit the specific user list that @rails_bot follows, but it might not work for other lists, so you might need to change not only the specific values, but also the whole function. E.g. you could use a simpler function like `user.followers_count / 1000 + 3` - then for a person with 6000 followers their tweets will need to have at least 9 retweets+favorites to be considered for retweeting (as long as they match the whitelist and don't match the blacklist), and a person with almost no followers will still need at least 3. Do some experiments and see what works for you - make sure that both popular and relatively unknown people don't get retweeted regardless of what they say or not retweeted at all.

## Credits

Created by [Kuba Suder](http://mackuba.eu) ([@kuba_suder](https://twitter.com/kuba_suder)), licensed under MIT License.
