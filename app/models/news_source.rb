class NewsSource < ApplicationRecord
  scope :active, -> {where(:enabled=>true)}
  
  before_save :set_slug
  def set_slug
    self.slug = self.name.downcase.gsub(' ', '_')
  end
  
  attr_accessor :feed
  
  def feed
    unless @feed
      begin
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
      rescue Exception=>e
        Rails.logger.error("Error getting feed for source #{self.name}")
        Rails.logger.error(e.message)
        @feed =nil
      end
    end
    @feed
  end

  def self.clear_all_caches
    current_caches = REDIS.smembers("newsfeed_caches")
    current_caches.each do |caches_key|
      current_cached_stories = REDIS.hkeys(caches_key)
      REDIS.multi do |r|
        current_cached_stories.each do |link_hash|
          r.hdel(caches_key, link_hash)
          StoryImage.where(:link_hash=>link_hash).each(&:purge)
          StoryVideo.where(:link_hash=>link_hash).each(&:purge)
        end
      end
    end
  end
  
  def get_cached_stories
    REDIS.hgetall(cache_key)
  end
  
  def get_cached_story_keys
    REDIS.hkeys(cache_key)
  end
  
  def delete_cached_stories
    current_cached_stories = REDIS.hkeys(self.cache_key)
    REDIS.multi do |r|
      current_cached_stories.each do |link_hash|
        r.hdel(self.cache_key, link_hash)
        begin
          StoryImage.where(:link_hash=>link_hash).each(&:purge)
          StoryVideo.where(:link_hash=>link_hash).each(&:purge)
        rescue
        end
      end
    end
  end
  
  def get_cached_story(link_hash)
    store = REDIS.hget(self.cache_key, link_hash)
    if store
      JSON.parse(store)
    else
      nil
    end
  end

  def cache_key
    "cached_stories:#{self.name.downcase.gsub(' ','_')}"
  end
  
  def self.build_index
    full_set = []
    NewsSource.find_each do |source|
      set = {:source_name=>source.name, :source_url=>source.url, :stories=>[]}
      cached_feed = source.get_cached_stories
      if cached_feed
        cached_feed.each do |story|
          set[:stories] << JSON.parse(story[1]).except('content')
        end
      end
      full_set << set
    end
    full_set
  end
end
