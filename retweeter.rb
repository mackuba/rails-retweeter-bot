class Retweeter
  # below this retweet count we don't even check favorites count to save API calls
  MIN_RETWEET_COUNT = 5
  DAY = 86400
  THREE_MONTHS = 90 * DAY

  def initialize(twitter)
    @twitter = twitter
  end

  def retweet_new_tweets
    puts "Retweeting..."
    tweets = load_home_timeline
    tweets.select { |t| retweetable_tweet?(t) }.each { |t| retweet(t) }
  end

  def print_retweetable_tweets
    puts "./bot retweet would retweet these tweets:"
    tweets = load_home_timeline
    tweets.select { |t| retweetable_tweet?(t) }.each { |t| p t }
  end

  def fetch_all_users_json(options = {})
    users = followed_users
    users |= options[:extra_users] if options[:extra_users]
    days = options[:days]

    tweets_json = users.map { |u| load_user_timeline(u, days).map(&:attrs) }

    Hash[users.zip(tweets_json)]
  end

  def followed_users
    @twitter.following.map(&:screen_name).sort
  end

  def load_home_timeline
    with_activity_data(load_timeline(:home_timeline))
  end

  def load_user_timeline(login, days = nil)
    interval = days ? (days * DAY) : THREE_MONTHS
    starting_date = Time.now - interval

    $stderr.print "@#{login} ."
    tweets = load_timeline(:user_timeline, login)

    while tweets.last.created_at > starting_date
      $stderr.print '.'
      batch = load_timeline(:user_timeline, login, :max_id => tweets.last.id - 1)
      break if batch.empty?
      tweets.concat(batch)
    end

    $stderr.print '*'
    tweets = with_activity_data(tweets.reject { |t| t.created_at < starting_date })

    $stderr.puts
    tweets
  end

  def load_timeline(timeline, *args)
    options = args.last.is_a?(Hash) ? args.pop : {}
    @twitter.send(timeline, *args, { :count => 200, :include_rts => false }.merge(options))
  end

  def with_activity_data(tweets)
    tweets.tap do |tt|
      selected = tt.select { |t| t.retweet_count > MIN_RETWEET_COUNT }
      activities = @twitter.statuses_activity(selected.map(&:id))

      selected.zip(activities).each do |t, a|
        t.attrs.update(a.attrs)
      end
    end
  end

  def retweet(tweet)
    @twitter.retweet(tweet.id)
  end

  def interesting_tweet?(tweet)
    matches_keywords?(tweet) && tweet_activity_count(tweet) >= awesomeness_threshold(tweet.user)
  end

  def retweetable_tweet?(tweet)
    !tweet.retweeted && interesting_tweet?(tweet)
  end

  def matches_keywords?(tweet)
    keywords_whitelist.any? { |k| tweet.text =~ k }
  end

  def keywords_whitelist
    @whitelist ||= File.readlines('keywords_whitelist.txt').map { |k| /\b#{k.strip}\b/i }
  end

  def tweet_activity_count(tweet)
    tweet.retweet_count + tweet.favoriters_count.to_i
  end

  def awesomeness_threshold(user)
    # this is a completely non-scientific formula calculated by trial and error
    # in order to set the bar higher for users that get retweeted a lot (@dhh, @rails).
    # should be around 20 for most people and then raise to ~30 for @rails and 50+ for @dhh.
    # the idea is that if you have an army of followers, everything you write gets retweeted and favorited

    17.5 + (user.followers_count ** 1.25) * 25 / 1_000_000
  end
end
