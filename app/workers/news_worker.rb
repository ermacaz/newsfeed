class NewsWorker
  require 'simple-rss'
  require 'open-uri'
  require 'nokogiri'
  require 'cgi'

  NUM_STORIES = 25

  if Rails.env == 'production'
    ActiveStorage::Current.url_options = { protocol: 'https', host: 'newsfeed.ermacaz.com' }
  else
    ActiveStorage::Current.url_options = { protocol: 'http', host: 'localhost', port: '3000' }
  end

  ## TODO
  # cache images at thumb and modal size?
  # parse full pages with lazy load images with apparition?
  def scrape(sources = NewsSource.active, nocache = false)
    puts "Beginning run at #{Time.zone.now.in_time_zone('Arizona')}"
    threads = []
    sources = [sources] unless sources.respond_to?(:first)
    NewsSource.update_teddit_source
    sources.each(&:reload)
    sources.each do |source|
      thread = Thread.new do
        begin
          if Rails.env == 'production'
            ActiveStorage::Current.url_options = { protocol: 'https', host: 'newsfeedapi.ermacaz.com' }
          else
            ActiveStorage::Current.url_options = { protocol: 'http', host: 'localhost', port: '3001' }
          end
          puts source.name
          skip_scan = false
          # unless ((source.scan_interval.nil? || source.last_scanned_at.nil?) || (source.last_scanned_at + source.scan_interval.minutes < Time.zone.now))
          #   skip_scan = true
          # end
          next if skip_scan || source.feed.nil?

          handler_class = Sources::Base.for(source)
          # we reverse so older stories are cached first
          source.feed.entries.first(NUM_STORIES).reverse.each do |entry|
            cached_story_keys = source.get_cached_story_keys
            link = handler_class.article_link(entry, source)
            link_hash = Digest::MD5.hexdigest(link)
            story = {
              source: source.slug,
              pub_date: (entry[:pubDate]&.to_i || entry[:published]&.to_i || DateTime.now&.to_i),
              link: link,
            }

            if !nocache && cached_story_keys.include?(link_hash)
              story = source.get_cached_story(link_hash)
            else
              article = handler_class.article_doc(entry, source, link)
              handler = handler_class.new(entry, article, source)

              story[:title]       = handler.title
              story[:description] = handler.description

              content = handler.content_parts
              content = Sources::Base.clean_parts(content) unless handler_class.skip_default_content?
              has_content = content.is_a?(Array) ? content.any? : content.present?
              story[:content] = content if has_content

              img_src = handler.img_src
              thumb_override = handler.media_url_thumb

              if img_src.present? && img_src.strip.present?
                story_image = process_img(img_src, link_hash, source)
                if story_image
                  story[:media_url_thumb] = story_image.thumb_url
                  story[:media_url]       = story_image.story_image_url
                else
                  story[:media_url_thumb] = story[:media_url] = img_src
                end
              end

              # Reddit videos set media_url_thumb directly (preview frame, no img_src).
              story[:media_url_thumb] = thumb_override if thumb_override
            end

            story[:cache_time] = Time.now.to_i
            REDIS.hset(source.cache_key, link_hash => story.to_json)
            REDIS.sadd?("newsfeed_caches", source.cache_key)
          end
          source.update!(last_scanned_at: Time.zone.now)
          puts "#{source.name} complete"
        rescue Exception => e
          puts e
          puts e.backtrace.select { |a| a.match?(/newsfeed/i) }.inspect
        end
      end
      thread.report_on_exception = false
      threads << thread
    end
    threads.each(&:join)
    puts "after thread join"
    NewsSource.update_index_cache
    true
  end

  def process_img(img_src, link_hash, source)
    begin
      unless story_image = StoryImage.find_by_link_hash(link_hash)
        img = URI.open(img_src, 'User-Agent' => 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/94.0.4606.61 Safari/537.36')
        case img_src
        when /\.jpe?g/i
          filename = "#{link_hash}.jpg"
        when /\.png/
          filename = "#{link_hash}.png"
        when /\.gif/
          filename = "#{link_hash}.gif"
        else
          filename = "#{link_hash}.jpg"
        end
        story_image = StoryImage.create_and_upload!(io: img, filename: filename, link_hash: link_hash, record: source)
        story_image.create_image_variants
      end
      story_image
    rescue Exception => e
      Rails.logger.warn("unable to grab image at #{img_src}")
      Rails.logger.warn(e.message)
      Rails.logger.warn e.backtrace.select { |a| a.match?(/newsfeed/) }.inspect
      puts "unable to grab image at #{img_src}"
      puts e.message
      puts e.backtrace.select { |a| a.match?(/newsfeed/) }.inspect
    end
  end
end
