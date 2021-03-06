require 'twitter'

namespace :twitter do
  desc "tweet"
  task :tweet => :environment do
    recent_articles = Article.where(created_at: (Time.now-60*60)..Time.now)
    i = 0
    while i < 5 do
      article = recent_articles.sample
      next if article.tweeted?
      tweet = article.tweet_text
      article.update(tweeted: true)
      update(get_twitter_client, tweet)
      i += 1
    end
  end

  desc "follow"
  task :follow => :environment do
    follow(get_twitter_client)
  end

  desc "unfollow"
  task :unfollow => :environment do
    unfollow(get_twitter_client)
  end

  desc "searching"
  task :searching => :environment do
    searching(get_twitter_client)
  end
end

def get_twitter_client
  client = Twitter::REST::Client.new do |config|
    config.consumer_key        = Settings.consumer_key
    config.consumer_secret     = Settings.consumer_secret
    config.access_token        = Settings.access_token
    config.access_token_secret = Settings.access_token_secret
  end
  client
end

def update(client, tweet)
  begin
    tweet = (tweet.length > 140) ? tweet[0..139].to_s : tweet
    client.update(tweet.chomp)
  rescue => e
    Rails.logger.error "<<twitter.rake::tweet.update ERROR : #{e.message}>>"
  end
end

def follow(client)
  followers = []
  cnt_retry = 0
  begin
    client.follower_ids.each_slice(100) do |ids|
      followers.concat client.users(ids)
    end
    client.follow(followers)
  rescue Twitter::Error::TooManyRequests => error
    sleep(15*60)
    cnt_retry += 1
    retry if cnt_retry < 2
  end
end

def unfollow(client)
  friends = []
  cnt_retry = 0
  begin
    friends =
      client.friend_ids.select{|friend_id| !client.follower_ids.include?(friend_id) }
    client.unfollow(friends)
  rescue Twitter::Error::TooManyRequests => error
    sleep(15*60)
    cnt_retry += 1
    retry if cnt_retry < 2
  end
end

def searching(client)
  keywords = ["バイト", "相互", "学校"]
  keywords.each do |keyword|
    user_ids = client.search(keyword).take(5).map{|tweet| tweet.user.id }
    cnt_retry = 0
    begin
      client.follow(user_ids)
    rescue Twitter::Error::TooManyRequests => error
      sleep(15*60)
      cnt_retry += 1
      retry if cnt_retry < 2
    end
  end
end
