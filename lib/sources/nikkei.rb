module Sources
  class Nikkei < Base
    def img_src
      src = article.css('.image-main')&.first&.attribute('src')&.to_s
      src.presence || default_img_src
    end
  end
end
