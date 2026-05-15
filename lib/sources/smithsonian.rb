module Sources
  class Smithsonian < Base
    def img_src
      src = article.xpath("//img").compact.select { |a| a.attribute('src')&.to_s&.match?(/jpe?g$/) }.first.attribute('src')
      unless src
        src = (article.xpath("//img").compact[2]&.attribute('src')&.to_s.split(")/")[1] rescue nil)
      end
      src = source.url + src if src&.to_s&.match?(/^\//)
      self.class.img_src_filter(src) || default_img_src
    rescue
      default_img_src
    end
  end
end
