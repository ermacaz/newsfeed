module Sources
  # Google News links point at a redirect page whose first <a href> is the real
  # article URL. article_doc follows that redirect before parsing.
  class GoogleNews < Base
    def self.skip_default_description?; true; end

    def self.article_doc(_entry, _source, link)
      first_doc = Nokogiri.HTML(HTTParty.get(link, headers: { 'User-agent' => 'ermacaz' }).body)
      real_link = first_doc.css('a').first.attribute('href').value
      Nokogiri.HTML(HTTParty.get(real_link, headers: { 'User-agent' => 'ermacaz' }).body)
    rescue
      first_doc
    end

    def img_src
      src = article.xpath("//img")&.first&.attribute('src')&.to_s
      src = nil if src&.match?(/^\//)
      self.class.img_src_filter(src) || default_img_src
    end
  end
end
