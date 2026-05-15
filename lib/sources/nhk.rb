module Sources
  class Nhk < Base
    def use_inline_image_extraction?; true; end

    def description
      return nil if entry[:description].blank?
      CGI.unescapeHTML(entry[:description].truncate(1000).gsub(' ', '  ').encode('UTF-8', invalid: :replace, undef: :replace, replace: '?').html_safe)
    end

    def img_src
      src = (source.url + article.xpath("//img").first.attribute('data-src').to_s rescue nil)
      return nil if src&.match?(/noimg_default/)
      src = source.url + src if src&.match?(/^\//)
      self.class.img_src_filter(src) || default_img_src
    end
  end
end
