module Sources
  class HackerNews < Base
    def self.skip_default_description?; true; end
    def self.skip_default_img?; true; end

    def img_src
      src = article.xpath("//img")&.first&.attribute('src')&.to_s
      src = nil if src&.match?(/^\//)
      self.class.img_src_filter(src)
    end
  end
end
