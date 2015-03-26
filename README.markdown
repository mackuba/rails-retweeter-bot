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

The basic idea was that the best tweets get retweeted a lot, so I made the bot select tweets with a high number of retweets. Adding favorites improved things further, because a lot of tweets get many favorites but not many retweeets (especially some useful but not funny tweets from [@ruby_news](https://twitter.com/ruby_news) or [@rubyflow](https://twitter.com/rubyflow) - the funny ones get retweeted the most). I've ignored retweets because almost all of them were off topic.

Now I had most of the interesting tweets marked to be retweeted, but most of the top tweets were still not relevant - funny tweets about random things, tweets about politics, current news, Apple, Microsoft, startups, religion, etc. So then I've added a keyword whitelist - I went through the top tweets and I've prepared a list of keywords that would only match the tweets I'd like to see retweeted.

I've also made the minimum number of retweets+favorites depend on the author - those with a high number of followers get much more retweets on average, so a post with 30 retweets by [@spastorino](https://twitter.com/spastorino) (3871 followers) will usually be more interesting than a post with 30 retweets by [@dhh](https://twitter.com/dhh) (72141 followers).

The end result is that even though some good tweets are ignored and some off topic tweets get retweeted, the filter works surprisingly well in most cases. It should retweet about 4 tweets per day on average, which sounds like an acceptable number.

##First steps for non ruby pros

First, you need to set up the proper libraries and bundles. You can do this through installing brew, ruby and ruby on rails (you don't actually need this, it's just useful in general), at these three links respectively: http://brew.sh, http://rubyinstaller.org, http://installrails.com. 

All of the commands are commands you have to type into terminal, such as `bundle install`, or `ruby oauth_generator.rb`. By the way, to run a ruby file make sure to put `ruby` before hand. Next, make sure you've set up an app on Twitter to use for this project. 

Lastly, when running ./bot live and ./bot cached data.json you can find those web UIs by typing "localhost:3000" into Safari. 

Good luck! 

## How to use

Obviously, start with `bundle install`.

Create a `config.yml` file based on the example file. Sign up for an app on Twitter and copy the first two keys to the config. Then use the `oauth_generator.rb` script to get the other two keys (sign in with the account that will be retweeting!).

Then you can use any of these:

### ./bot retweet

Loads 200 last tweets from the timeline (ignoring retweets) and retweets the ones that match the filter and weren't retweeted yet. This means that only tweets from people that the bot is following will be analyzed.

200 last tweets includes tweets from the last 2 days on average (I think most tweets will get most of their retweets and favorites in the first 2 days anyway).

### ./bot fetch data.json

Downloads last 3 months of tweets from each of the followed people and saves them as a JSON file.

### ./bot cached data.json

Starts a web UI that you can use to tweak the filter and see which tweets get marked. Uses the JSON file created above.

### ./bot live

Starts a web UI, downloading tweets on demand. This is useful for checking new profiles to see if it's worth adding them to the list.

## Credits

Created by [Jakub Suder](http://psionides.eu) ([@psionides](https://twitter.com/psionides)), licensed under MIT License.
