class NewsWorker
  require 'simple-rss'
  require 'open-uri'
  require 'nokogiri'
  def scrape
    set = []
    NewsSource.all.each do |source|
      feed = SimpleRSS.parse open(source.feed_url, 'User-Agent'=>'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:82.0) Gecko/20100101 Firefox/82.0')
      entry_set = {:source_name=>source.name, :source_url=>source.url, :stories=>[]}
      feed.entries.first(25).each do |entry|
        story = {}
        entry.keys.each do |key|
          case key.to_s
          when 'title'
            story['title'] = entry[key].truncate(125).encode('UTF-8', invalid: :replace, undef: :replace, replace: '?').html_safe
          when 'link'
            story['link'] = entry[key].encode('UTF-8', invalid: :replace, undef: :replace, replace: '?').html_safe
          when 'description'
            case source.name
            when 'Just One Cookbook'
              story['media_url'] = (Nokogiri.HTML(entry[key]).xpath('//img').first.attr('src').encode('UTF-8', invalid: :replace, undef: :replace, replace: '?').html_safe rescue nil)
              story['description'] = (Nokogiri.HTML(entry[key]).xpath("//p")[1].content.truncate(250).encode('UTF-8', invalid: :replace, undef: :replace, replace: '?').html_safe rescue nil)
            when 'No Recipes'
              story['description'] = (Nokogiri.HTML(entry[key]).xpath("//p").first.content.truncate(250).encode('UTF-8', invalid: :replace, undef: :replace, replace: '?').html_safe rescue nil)
            when 'Kotaku'
              story['media_url'] = (Nokogiri.HTML(entry[key]).xpath('//img').first.attr('src').encode('UTF-8', invalid: :replace, undef: :replace, replace: '?').html_safe rescue nil)
              story['description'] = (Nokogiri.HTML(entry[key]).xpath("//p").first.content.truncate(250).encode('UTF-8', invalid: :replace, undef: :replace, replace: '?').html_safe rescue nil)
            else
              unless source.name.match?(/Google|Slashdot|Hacker/)
                story['description'] = entry[key].truncate(250).encode('UTF-8', invalid: :replace, undef: :replace, replace: '?').html_safe
              end
            end
          when 'media_content_url', 'media_thumbnail_url'
            story['media_url'] = entry[key].encode('UTF-8', invalid: :replace, undef: :replace, replace: '?').html_safe
          end
        end
        entry_set[:stories] << story
      end
      set << entry_set
    end
    REDIS.call("SET", "newsfeed", set.to_json)
    ActionCable.server.broadcast 'news_sources_channel', JSON.parse(REDIS.call('get', 'newsfeed'))
    return true
  end
end