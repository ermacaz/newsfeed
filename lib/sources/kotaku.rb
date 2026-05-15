module Sources
  class Kotaku < Base
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
      Nokogiri.HTML(CGI.unescapeHTML(entry[:description])).xpath('//img').attribute('src').to_s
    rescue
      default_img_src
    end
  end
end
