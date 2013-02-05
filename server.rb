require 'sinatra/base'

class Server < Sinatra::Base
  enable :logging, :sessions, :static
  set :port, ENV['PORT'] || 3000

  private_class_method :run!

  def self.start(retweeter, data = nil)
    @@retweeter = retweeter
    @@tweets = {}
    @@live = !data
    @@users = retweeter.followed_users

    if data
      data.each do |login, tweets_json|
        @@tweets[login.to_s] = tweets_json.map { |t| Twitter::Tweet.new(t) }
      end
    end

    run!
  end

  helpers do
    def live?
      @@live
    end

    def users
      @@users
    end

    def highlight(text)
      highlighted = text.clone

      @@retweeter.keywords_whitelist.each do |k|
        highlighted.gsub!(k, "<mark>\\0</mark>")
      end

      highlighted.gsub!(/\b(https?:\/\/\S*[^,.])(\s|$)/, "<a href=\"\\1\">\\1</a>\\2")

      highlighted
    end

    def interesting_tweet?(tweet)
      @@retweeter.interesting_tweet?(tweet)
    end

    def below_threshold?(tweet)
      @@retweeter.tweet_activity_count(tweet) < @@retweeter.awesomeness_threshold(tweet.user)
    end

    def awesomeness_threshold(user)
      sprintf("%.2f", @@retweeter.awesomeness_threshold(user))
    end
  end

  before do
    @sort = session[:sort] = params[:sort] || session[:sort] || 'time'
  end

  get '/' do
    @@tweets[nil] ||= @@live ? @@retweeter.load_home_timeline : @@tweets.values.flatten

    index(@@tweets[nil])
  end

  get '/user/:login' do |login|
    @@tweets[params[:login]] ||= @@retweeter.load_user_timeline(login)

    index(@@tweets[params[:login]])
  end

  def index(tweets)
    selected_tweets = tweets.reject { |t| t.text.start_with?('@') && t.retweet_count == 0 }

    if @sort == 'time'
      selected_tweets.sort_by! { |t| -t.created_at.to_i }
    else
      selected_tweets.sort_by! { |t| -(t.retweet_count + t.favoriters_count.to_i) }
    end

    erb :tweets, :locals => {
      :tweets => selected_tweets,
      :user_data => params[:login] && tweets.first ? tweets.first.user : nil
    }
  end
end