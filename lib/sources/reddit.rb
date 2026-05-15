module Sources
  # Reddit (via teddit) — content can be an image URL, a stored video, or text.
  # The post type is detected from the article DOM. For video posts we download and
  # store the file via StoryVideo. The worker uses #img_src for the image case and
  # #media_url_thumb for the video case; #content_parts returns the URL or paragraph array.
  class Reddit < Base
    def self.skip_default_description?; true; end
    def self.skip_default_img?; true; end
    def self.skip_default_content?; true; end

    def content_parts
      processed[:content]
    end

    def img_src
      processed[:img_src]
    end

    def media_url_thumb
      processed[:media_url_thumb]
    end

    private

    def processed
      @processed ||= compute_processed
    end

    def compute_processed
      if article.css('#post')&.first&.css('.image')&.first
        url = ("https://#{NewsSource::TEDDIT_URL}" + Nokogiri.HTML(article.css('#post').first.css('.image').first.inner_html).xpath('//a').first.attribute('href').to_s rescue nil)
        { content: url, img_src: url }
      elsif article.css('#post')&.first&.css('.video')&.first
        filepath = (Nokogiri.HTML(article.css('#post').first.css('.video').first.inner_html).xpath('//a').first.attribute('href').to_s rescue nil)
        if filepath
          link_hash = Digest::MD5.hexdigest(self.class.article_link(entry, source))
          filename = "#{link_hash}.#{filepath.match(/\.(.*)$/)[1]}"
          story_video = StoryVideo.where(link_hash: link_hash, filename: filename).first
          unless story_video
            io = URI.open("https://#{NewsSource::TEDDIT_URL}" + filepath, 'User-Agent' => 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/94.0.4606.61 Safari/537.36')
            story_video = StoryVideo.create_and_upload!(io: io, filename: filename, link_hash: link_hash, record: source)
          end
          { content: story_video.url, media_url_thumb: story_video.preview(resize_to_limit: [StoryImage::THUMB_WIDTH, nil]).processed.url }
        else
          fallback = ("https://#{NewsSource::TEDDIT_URL}" + Nokogiri.HTML(article.css('#post').first.css('.video').first.inner_html).xpath('//a').first.attribute('href').to_s rescue nil)
          { content: fallback }
        end
      elsif article.css('.usertext-body').first
        { content: (article.css('.usertext-body').first.content.split("\n\n") rescue nil) }
      else
        {}
      end
    end
  end
end
