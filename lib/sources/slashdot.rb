module Sources
  class Slashdot < Base
    def self.skip_default_description?; true; end

    def content_parts
      parts = article.css('.body').first.content.strip.split("\n\n")
      self.class.clean_parts(parts)
    rescue
      nil
    end

    def img_src
      src = article.xpath("//img")&.first&.attribute('src')&.to_s&.gsub(/^\/\//, 'https://')
      self.class.img_src_filter(src) || default_img_src
    end
  end
end
