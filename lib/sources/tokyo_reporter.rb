module Sources
  class TokyoReporter < Base
    def img_src
      src = article.css('.post-content figure img')&.first&.attribute('src')&.to_s
      src.presence || default_img_src
    end
  end
end
