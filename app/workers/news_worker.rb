class NewsWorker
  require 'simple-rss'
  require 'open-uri'
  require 'nokogiri'
  require 'cgi'
  def scrape
    set = []
    NewsSource.active.each do |source|
      puts source.name
      if source.name == 'No Recipes'
        feed = (SimpleRSS.parse HTTParty.get(source.feed_url, :headers=>{'User-agent'=>'ermacaz'}) rescue nil)
      else
        feed = (SimpleRSS.parse open(source.feed_url, 'User-Agent'=>'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/94.0.4606.61 Safari/537.36') rescue nil)
      end
      # if feed.nil?
      #   feed =  (SimpleRSS.parse`curl -L -H 'Referer: http://css-tricks.com/forums/topic/font-face-in-base64-is-cross-browser-compatible/' #{feed.url}` rescue nil)
      # end
      next if feed.nil?
      entry_set = {:source_name=>source.name, :source_url=>source.url, :stories=>[]}
      feed.entries.first(25).each do |entry|
        story = {}
        entry.keys.each do |key|
          case key.to_s
          when 'title'
            story['title'] = entry[key].truncate(125).encode('UTF-8', invalid: :replace, undef: :replace, replace: '?').html_safe
          when 'link'
            story['link'] = entry[key].encode('UTF-8', invalid: :replace, undef: :replace, replace: '?').html_safe.gsub('reddit.com','teddit.net')
          when 'description', 'content'
            case source.name
            when 'Just One Cookbook'
              story['media_url'] = (Nokogiri.HTML(entry[key]).xpath('//img').first.attr('src').encode('UTF-8', invalid: :replace, undef: :replace, replace: '?').html_safe rescue nil)
              story['description'] =  CGI.unescapeHTML((Nokogiri.HTML(entry[key]).xpath("//p")[1].content.truncate(1000).encode('UTF-8', invalid: :replace, undef: :replace, replace: '?').html_safe rescue nil))
            when 'No Recipes'
              story['description'] =  CGI.unescapeHTML((Nokogiri.HTML(entry[key]).xpath("//p").first.content.truncate(1000).encode('UTF-8', invalid: :replace, undef: :replace, replace: '?').html_safe rescue nil))
            when 'Kotaku'
              story['description'] =  CGI.unescapeHTML((Nokogiri.HTML(entry[key]).xpath("//p").first.content.truncate(1000).encode('UTF-8', invalid: :replace, undef: :replace, replace: '?').html_safe rescue nil))
            else
              unless source.name.match?(/Google|Slashdot|Hacker/)
                story['description'] = CGI.unescapeHTML(entry[key].truncate(1000).encode('UTF-8', invalid: :replace, undef: :replace, replace: '?').html_safe)
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