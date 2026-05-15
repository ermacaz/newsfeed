module Sources
  class Mainichi < Base
    def img_src
      src = article.css('picture img')&.first&.attribute('src')&.to_s
      src.presence || default_img_src
    end
  end
end
