module Sources
  class PhoenixNewTimes < Base
    def img_src
      Nokogiri.HTML(CGI.unescapeHTML(entry[:description])).xpath('//img').attribute('src').to_s
    rescue
      default_img_src
    end

    def content_parts
      content_node = article.css('.article-content').first
      return nil unless content_node
      inline_items = []
      content_node.children.each do |child|
        case child.name
        when 'p'
          text = child.content.strip
          inline_items << text if text.present?
        when 'figure'
          src = child.css('img').first&.attribute('src')&.to_s
          inline_items << "IMAGE:#{src}" if src.present?
        end
      end
      self.class.clean_parts(inline_items)
    end
  end
end
