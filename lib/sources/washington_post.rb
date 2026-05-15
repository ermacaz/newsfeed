module Sources
  class WashingtonPost < Base
    def img_src
      img_elem = article.xpath("//img").reject { |v| v.attribute('src')&.value&.match(/authors/) }.first
      src = (img_elem&.attribute('src')&.to_s rescue nil)
      if src.blank? && (srcset = img_elem&.attribute('srcset'))
        src = srcset.to_s&.split(', ')&.last&.split(' ')&.first
      end
      src.presence || default_img_src
    end
  end
end
