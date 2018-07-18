class TweetPresenter
  def self.from_json(json)
    new(Twitter::Tweet.new(json))
  end

  def self.load_keyword_list(name)
    File.readlines(name).map do |pattern|
      pattern.strip!
      if pattern =~ /^"(.*)"$/
        # double quotes mean don't ignore case
        /\b#{$1}\b/
      elsif pattern =~ /^\/(.*)\/$/
        # slashes mean use pattern directly without wrapping in \b
        /#{$1}/
      else
        /\b#{pattern}\b/i
      end
    end
  end

  def self.reload_blacklists
    @whitelist = @blacklist = nil
  end

  def self.keywords_whitelist
    @whitelist ||= load_keyword_list('keywords_whitelist.txt')
  end

  def self.keywords_blacklist
    @blacklist ||= load_keyword_list('keywords_blacklist.txt')
  end

  def self.user_awesomeness_threshold(user)
    # this is a completely non-scientific formula calculated by trial and error
    # in order to set the bar higher for users that get retweeted a lot (@dhh, @rails).
    # should be around 20 for most people and then raise to ~30 for @rails and 50+ for @dhh.
    # the idea is that if you have an army of followers, everything you write gets retweeted and favorited

    17.5 + (user.followers_count ** 1.25) * 25 / 1_000_000
  end

  def initialize(tweet)
    @tweet = tweet
  end

  [:id, :attrs, :created_at, :retweet_count, :text, :urls, :user].each do |method|
    define_method(method) do
      @tweet.send(method)
    end
  end

  def reply?
    text.start_with?('@')
  end

  def retweetable?
    !retweeted? && interesting?
  end

  def interesting?
    matches_whitelist? && !matches_blacklist? && above_threshold?
  end

  def above_threshold?
    (activity_count >= user_awesomeness_threshold) && retweet_count > 0
  end

  def retweeted?
    @tweet.retweeted
  end

  def matches_whitelist?
    self.class.keywords_whitelist.any? { |k| expanded_text =~ k }
  end

  def matches_blacklist?
    return true if user.screen_name == 'sgrif' && expanded_text.downcase =~ /ruby/   # not *that* Ruby

    self.class.keywords_blacklist.any? { |k| expanded_text =~ k }
  end

  def activity_count
    retweet_count + favorite_count
  end

  def favorite_count
    # overwrite the alias favorite_count -> @attrs[:favoriters_count] from twitter gem
    @tweet.attrs[:favorite_count]
  end

  def user_awesomeness_threshold
    self.class.user_awesomeness_threshold(user)
  end

  def expanded_text
    unless @expanded_text
      @expanded_text = text.clone
      urls.each { |entity| @expanded_text[entity.url] = entity.display_url }
    end

    @expanded_text
  end
end
