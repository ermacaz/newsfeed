module Sources
  class TheVerge < Base
    def self.skip_default_description?; true; end

    def img_src
      Nokogiri.HTML(CGI.unescapeHTML(entry[:content])).xpath('//img').attribute('src').to_s
    rescue
      default_img_src
    end

    def description
      Nokogiri.HTML(CGI.unescapeHTML(entry[:content])).to_s.gsub(/(<([^>]+)>)/i, '').gsub(/\s/, ' ').strip
    rescue
      nil
    end
  end
end
