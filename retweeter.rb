require_relative 'tweet_presenter'

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
    tweets.select(&:retweetable?).each { |t| retweet(t) }
  end

  def print_retweetable_tweets
    puts "./bot retweet would retweet these tweets:"
    tweets = load_home_timeline
    tweets.select(&:retweetable?).each { |t| p t }
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
    tweets = @twitter.send(timeline, *args, { :count => 200, :include_rts => false }.merge(options))
    tweets.map { |t| TweetPresenter.new(t) }
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
end
