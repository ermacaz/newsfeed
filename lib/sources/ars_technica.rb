module Sources
  class ArsTechnica < Base
    def img_src
      Nokogiri.HTML(CGI.unescapeHTML(entry[:content_encoded])).xpath('//img').attribute('src').to_s
    rescue
      default_img_src
    end

    def content_parts
      # `xpath("//p")` is absolute and pulls every <p> on the page; preserved as-is to keep
      # parity with the original behavior. Drops the first 4 boilerplate paragraphs and
      # truncates at the "You must login or create an account to comment" marker.
      parts = (article.css('.article-content').first.xpath("//p").map(&:content).drop(4) rescue [])
      comment_part = parts.select { |a| a.match?(/^You must login or create an account to comment/) }.first
      if comment_part
        index = parts.index(comment_part)
        parts = parts.reverse.drop(parts.length - index).reverse
      end
      self.class.clean_parts(parts)
    end
  end
end
