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
      if source.multiple_feeds
        feed_urls = source.feed_url.split(";")
        feeds = []
        feed_urls.each do |feed_url|
          feeds << (SimpleRSS.parse URI.open(feed_url, 'User-Agent'=>'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/94.0.4606.61 Safari/537.36') rescue nil)
        end
        feed = feeds.map {|f| f.entries.first(25)}.flatten.uniq {|x| x[:title]}.sort {|x,y| y[:pubDate] <=> x[:pubDate]}.first(25)
      else
        if source.name == 'No Recipes'
          feed = (SimpleRSS.parse HTTParty.get(source.feed_url, :headers=>{'User-agent'=>'ermacaz'}) rescue nil)
        else
          feed = (SimpleRSS.parse URI.open(source.feed_url, 'User-Agent'=>'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/94.0.4606.61 Safari/537.36') rescue nil)
        end
      end
     
      if feed.nil?
        feed = (SimpleRSS.parse HTTParty.get(source.feed_url, :headers=>{'User-agent'=>'ermacaz'}) rescue nil)
      end
      next if feed.nil?
      entry_set = {:source_name=>source.name, :source_url=>source.url, :stories=>[]}
      feed.entries.first(25).each do |entry|
        story = {}
        if source.name == 'AZ Central'
          story['link'] = entry[:feedburner_origLink].encode('UTF-8', invalid: :replace, undef: :replace, replace: '?').html_safe.gsub('reddit.com','teddit.net')
        else
          story['link'] = entry[:link].encode('UTF-8', invalid: :replace, undef: :replace, replace: '?').html_safe.gsub('reddit.com','teddit.net')
        end
        link_hash = Digest::MD5.hexdigest story['link']
        if current_cached_stores.include?(link_hash)
          store = REDIS.hget("newsfeed_cached_stories", link_hash)
          story = JSON.parse(store)
          current_cached_stores = current_cached_stores - [link_hash]
        else
          entry.keys.each do |key|
            case key.to_s
            when 'title'
              story['title'] = CGI.unescapeHTML(entry[key].encode('UTF-8', invalid: :replace, undef: :replace, replace: '?').gsub('&quot;', '"')).html_safe
            when 'description', 'content'
              case source.name
              when 'Just One Cookbook'
                story['media_url'] = (Nokogiri.HTML(entry[key]).xpath('//img').first.attr('src').encode('UTF-8', invalid: :replace, undef: :replace, replace: '?').html_safe rescue nil)
                story['description'] =  CGI.unescapeHTML((Nokogiri.HTML(entry[key]).xpath("//p")[1].content.truncate(1000).encode('UTF-8', invalid: :replace, undef: :replace, replace: '?').html_safe rescue nil))
              when 'No Recipes'
                story['description'] =  CGI.unescapeHTML((Nokogiri.HTML(entry[key]).xpath("//p").first.content.truncate(1000).encode('UTF-8', invalid: :replace, undef: :replace, replace: '?').html_safe rescue nil))
              when 'Kotaku'
                story['description'] =  CGI.unescapeHTML((Nokogiri.HTML(entry[key]).xpath("//p").first.content.truncate(1000).encode('UTF-8', invalid: :replace, undef: :replace, replace: '?').html_safe rescue nil))
                story['media_url'] = (Nokogiri.HTML(CGI.unescapeHTML(entry[:description])).xpath('//img').attribute('src').to_s rescue nil)
              when 'AZ Central'
                story['description'] = CGI.unescapeHTML(entry[:description].truncate(1000).encode('UTF-8', invalid: :replace, undef: :replace, replace: '?').html_safe)
                story['media_url'] = entry[:content]
              when 'The Intercept', 'NPR', "Al Jazeera", "Smithsonian"
                story['description'] = CGI.unescapeHTML(entry[:description].truncate(1000).encode('UTF-8', invalid: :replace, undef: :replace, replace: '?').html_safe)
              when 'NHK'
                story['description'] = CGI.unescapeHTML(entry[:description].truncate(1000).gsub(' ', '  ').encode('UTF-8', invalid: :replace, undef: :replace, replace: '?').html_safe)
              else
                unless source.name.match?(/Google|Slashdot|Hacker/)
                  story['description'] = CGI.unescapeHTML(entry[key].truncate(1000).encode('UTF-8', invalid: :replace, undef: :replace, replace: '?').html_safe)
                end
                if source.name.match?(/Phoenix New Times/)
                  story['media_url'] = (Nokogiri.HTML(CGI.unescapeHTML(entry[:description])).xpath('//img').attribute('src').to_s rescue nil)
                elsif source.name.match?(/Verge/)
                  story['media_url'] = (Nokogiri.HTML(CGI.unescapeHTML(entry[:content])).xpath('//img').attribute('src').to_s rescue nil)
                elsif source.name.match?(/Ars Tech/)
                  story['media_url'] = (Nokogiri.HTML(CGI.unescapeHTML(entry[:content_encoded])).xpath('//img').attribute('src').to_s rescue nil)
                end
              end
            when 'media_content_url', 'media_thumbnail_url'
              story['media_url'] = entry[key].encode('UTF-8', invalid: :replace, undef: :replace, replace: '?').html_safe
            when 'content_encoded'
              story['media_url'] ||= Nokogiri.parse(entry[:content_encoded])&.xpath("//img")&.first&.attribute('src')&.to_s
            end
          end
          begin
            case source.name
            when 'AZ Central'
              article = Nokogiri.HTML(entry[:content_encoded])
            else
              article = Nokogiri.HTML(HTTParty.get(story['link'], :headers=>{'User-agent'=>'ermacaz'}).body)
            end
            parts = nil
            case source.name
            when 'Reddit'
              if article.css('#post').first.css('.image').first
                story['content'] = ("https://teddit.net" + Nokogiri.HTML(article.css('#post').first.css('.image').first.inner_html).xpath('//a').first.attribute('href').to_s rescue nil)
                story['media_url'] = story['content'] unless story['media_url']
              elsif article.css('#post').first.css('.video').first
                story['content'] = ("https://teddit.net" + Nokogiri.HTML(article.css('#post').first.css('.video').first.inner_html).xpath('//a').first.attribute('href').to_s rescue nil)
              elsif article.css('.usertext-body').first
                story['content'] = (article.css('.usertext-body').first.content.split("\n\n") rescue nil)
              end
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
              if article.xpath("//article").any?
                parts = (article.xpath("//article").first.xpath('//p').map(&:content) rescue article.xpath("//article").first.content.split("\n\n"))
              else
                parts = article.xpath('//p').map(&:content)
              end
            end
            if story['media_url'].blank?
              if source.name == 'Smithsonian'
                img_src = (article.xpath("//img")[1]&.attribute('src')&.to_s.split(")/")[1] rescue nil)
              elsif source.name == 'NHK'
                img_src = (source.url + '/news/html/' + article.xpath("//img")[2]&.attribute('src')&.to_s.gsub('../','') rescue nil)
                img_src = nil if img_src.match?(/noimg_default/)
              else
                img_src = article.xpath("//img")&.first&.attribute('src')&.to_s
              end
              if img_src&.match?(/^\//)
                img_src = source.url + img_src
              end
              story['media_url'] = img_src if img_src&.strip&.present?
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