class NewsSource < ApplicationRecord
  scope :active, -> {where(:enabled=>true)}
  
  attr_accessor :feed
  
  def feed
    unless @feed
      if self.multiple_feeds
        feed_urls = self.feed_url.split(";")
        feeds = []
        feed_urls.each do |feed_url|
          feeds << (SimpleRSS.parse URI.open(feed_url, 'User-Agent'=>'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/94.0.4606.61 Safari/537.36') rescue nil)
        end
        @feed = feeds.map {|f| f.entries.first(25)}.flatten.uniq {|x| x[:title]}.sort {|x,y| y[:pubDate] <=> x[:pubDate]}.first(25)
      else
        if self.name == 'No Recipes'
          @feed = (SimpleRSS.parse HTTParty.get(self.feed_url, :headers=>{'User-agent'=>'ermacaz'}) rescue nil)
        else
          @feed = (SimpleRSS.parse URI.open(self.feed_url, 'User-Agent'=>'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/94.0.4606.61 Safari/537.36') rescue nil)
        end
      end
      if @feed.nil?
        @feed = (SimpleRSS.parse HTTParty.get(self.feed_url, :headers=>{'User-agent'=>'ermacaz'}) rescue nil)
      end
    end
    @feed
  end
end
