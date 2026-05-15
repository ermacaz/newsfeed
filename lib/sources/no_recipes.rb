module Sources
  class NoRecipes < Base
    def use_inline_image_extraction?; true; end

    def description
      Nokogiri.HTML(entry[:description]).xpath("//p").first.content
        .truncate(1000)
        .encode('UTF-8', invalid: :replace, undef: :replace, replace: '?')
        .html_safe
        .then { |s| CGI.unescapeHTML(s) }
    rescue
      nil
    end

    def img_src
      src = article.xpath("//img")[5]&.attribute('src')&.to_s
      src = source.url + src if src&.match?(/^\//)
      self.class.img_src_filter(src) || default_img_src
    end
  end
end
