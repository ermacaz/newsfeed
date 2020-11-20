namespace :db do
  desc 'Fill database with sources'
  task populate: :environment do
    Rake::Task["db:reset"].invoke
    NewsSource.create(name: 'Reddit',
                      url: 'https://reddit.com',
                      feed_url: 'https://www.reddit.com/.rss')
    NewsSource.create(name: 'Google News',
                      url: 'https://news.google.com',
                      feed_url: 'https://news.google.com/?output=rss')
    NewsSource.create(name: 'New York Times',
                      url: 'https://nytimes.com',
                      feed_url: 'http://feeds.feedburner.com/nytimes/QwEB')
    NewsSource.create(name: 'Washington Post',
                      url: "https://washingtonpost.com",
                      feed_url: "http://feeds.washingtonpost.com/rss/world")
    NewsSource.create(name: 'Huffington Post',
                      url: 'https://huffingtonpost.com',
                      feed_url: 'https://www.huffingtonpost.com/feeds/index.xml')
    NewsSource.create(name: 'Slashdot',
      url: 'https://slashdot.org',
      feed_url: 'http://rss.slashdot.org/Slashdot/slashdot/to')
    NewsSource.create(name: 'Hacker News',
      url: 'https://news.ycombinator.com',
      feed_url: 'https://news.ycombinator.com/rss')
    NewsSource.create(name: 'Kotaku',
                      url: 'https://kotaku.com',
                      feed_url: 'https://kotaku.com/rss')
    NewsSource.create(name: 'PC GAMER',
                      url: 'https://www.pcgamer.com/',
                      feed_url: 'https://www.pcgamer.com/rss/')
    NewsSource.create(name: 'The Verge',
                      url: 'https://www.theverge.com',
                      feed_url: 'https://www.theverge.com/rss/frontpage')
    NewsSource.create(name: 'No Recipes',
                      url: 'https://norecipes.com',
                      feed_url: 'https://norecipes.com/feed')
    NewsSource.create(name: 'Just One Cookbook',
                      url: 'https://www.justonecookbook.com',
                      feed_url: 'https://www.justonecookbook.com/rss')
    NewsSource.create(name: 'NHK EasyNews',
                      url: 'https://www3.nhk.or.jp/news/easy/index.html',
                      feed_url: 'https://www.reddit.com/r/NHKEasyNews/.rss')
  end 
end
