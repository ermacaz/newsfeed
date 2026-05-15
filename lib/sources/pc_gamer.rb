module Sources
  class PcGamer < Base
    def content_parts
      # `.//p` (relative descendant) keeps the selection scoped to #article-body —
      # an absolute `//p` would pull every <p> on the page including newsletter signup.
      parts = article.css('#article-body').first&.xpath(".//p")&.map(&:content)&.map { |a| a.gsub('(opens in new tab)', '') } || []
      self.class.clean_parts(parts)
    end
  end
end
