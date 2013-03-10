require 'sinatra/base'
require_relative 'tweet_presenter'

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
        @@tweets[login.to_s] = tweets_json.map { |t| TweetPresenter.from_json(t) }
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

      TweetPresenter.keywords_whitelist.each do |k|
        highlighted.gsub!(k, "<mark>\\0</mark>")
      end

      TweetPresenter.keywords_blacklist.each do |k|
        highlighted.gsub!(k, "<del>\\0</del>")
      end

      highlighted.gsub!(/\b(https?:\/\/\S*[^,.])(\s|$)/, "<a href=\"\\1\">\\1</a>\\2")

      highlighted
    end

    def awesomeness_threshold(user)
      sprintf("%.2f", TweetPresenter.user_awesomeness_threshold(user))
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
    selected_tweets = tweets.reject { |t| t.reply? && t.retweet_count == 0 }

    if @sort == 'time'
      selected_tweets.sort_by! { |t| -t.created_at.to_i }
    else
      selected_tweets.sort_by! { |t| -t.activity_count }
    end

    erb :tweets, :locals => {
      :tweets => selected_tweets,
      :user_data => params[:login] && tweets.first ? tweets.first.user : nil
    }
  end
end