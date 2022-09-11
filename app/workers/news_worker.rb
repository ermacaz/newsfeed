class NewsWorker
  require 'simple-rss'
  require 'open-uri'
  require 'nokogiri'
  require 'cgi'
  def scrape
    # get current hashes of cached stories. we will just pull from these if they are still in the list
    current_cached_stores = REDIS.hkeys("newsfeed_cached_stories")
    set = []
    NewsSource.active.each do |source|
      puts source.name
      if source.name == 'No Recipes'
        feed = (SimpleRSS.parse HTTParty.get(source.feed_url, :headers=>{'User-agent'=>'ermacaz'}) rescue nil)
      else
        feed = (SimpleRSS.parse URI.open(source.feed_url, 'User-Agent'=>'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/94.0.4606.61 Safari/537.36') rescue nil)
      end
      # if feed.nil?
      #   feed =  (SimpleRSS.parse`curl -L -H 'Referer: http://css-tricks.com/forums/topic/font-face-in-base64-is-cross-browser-compatible/' #{feed.url}` rescue nil)
      # end
      next if feed.nil?
      entry_set = {:source_name=>source.name, :source_url=>source.url, :stories=>[]}
      feed.entries.first(25).each do |entry|
        story = {}
        story['link'] = entry[:link].encode('UTF-8', invalid: :replace, undef: :replace, replace: '?').html_safe.gsub('reddit.com','teddit.net')
        link_hash = Digest::MD5.hexdigest story['link']
        if current_cached_stores.include?(link_hash)
          store = REDIS.hget("newsfeed_cached_stories", link_hash)
          story = JSON.parse(store)
          current_cached_stores = current_cached_stores - [link_hash]
        else
          entry.keys.each do |key|
            case key.to_s
            when 'title'
              story['title'] = entry[key].truncate(125).encode('UTF-8', invalid: :replace, undef: :replace, replace: '?').html_safe
            when 'link'
              story['link'] ||= entry[key].encode('UTF-8', invalid: :replace, undef: :replace, replace: '?').html_safe.gsub('reddit.com','teddit.net')
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
          begin
            article = Nokogiri.HTML(HTTParty.get(story['link'], :headers=>{'User-agent'=>'ermacaz'}).body)
            parts = nil
            case source.name
            when 'Ars Technica'
              parts = article.css('.article-content').first.xpath("//p").map(&:content).drop(4)
              comment_part = parts.select {|a| a.match?(/^You must login or create an account to comment/)}.first
              if comment_part # everything here and after is removable
                index = parts.index(comment_part)
                parts = parts.reverse.drop(parts.length-index).reverse
              end
            when 'New York Times', 'Washington Post'
              parts = article.xpath("//p").map(&:content).reject {|b| b.match?(/^Advertisement$|^Supported by$|^Send any friend a story$/)}
            when 'Phoenix New Times'
              parts = article.css('.fdn-content-body').first.content.strip.split("\n\n")
            when 'PC GAMER'
              parts = article.css('#article-body').first.xpath("//p").map(&:content).map {|a| a.gsub('(opens in new tab)','')}.reject {|a| a.match?(/^PC Gamer is part of Future US Inc|^PC Gamer is supported by its audience|Future US, Inc. Full 7th Floor/)}
            when 'Slashdot'
              parts = article.css('.body').first.content.strip.split("\n\n")
            when 'The Verge'
              parts = article.css('.c-entry-content').first.xpath("//p").map(&:content).reject {|a| a.match?(/^PC Gamer is part of Future US Inc|^PC Gamer is supported by its audience|Future US, Inc. Full 7th Floor/)}
            when 'Kotaku'
              parts = article.css('.js_post-content').first.content.gsub(/AdvertisementScreenshot: [A-z]+ \/ KotakuAdvertisement/, ' ').split("\n\t\n\t\t\n\t\t\t\n\t\t\n\t\n").map {|a| a.split('Advertisement')}.flatten
            else
              1==1
            end
            if parts
              parts = parts.map(&:strip).reject(&:blank?).reject {|a| a.length < 5 || a.match?(/^Credit\.\.\.$|^Photographs by|10 gift articles to give each month/)}
              story['content'] = parts if parts.any?
            end
          rescue Exception=>e
            1==1
          end
          REDIS.hset("newsfeed_cached_stories", link_hash=>story.to_json)
        end
        entry_set[:stories] << story
      end
      set << entry_set
    end
    REDIS.call("SET", "newsfeed", set.to_json)
    # remove any stores not found when researching
    REDIS.multi do |r|
      current_cached_stores.each {|c| r.hdel("newsfeed_cached_stories", c)}
    end
    ActionCable.server.broadcast 'news_sources_channel', JSON.parse(REDIS.call('get', 'newsfeed'))
    return true
  end
end