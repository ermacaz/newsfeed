module Sources
  # AZ Central is unusual: the article HTML comes from the RSS entry's content_encoded
  # rather than an HTTP fetch, and the link uses entry[:feedburner_origLink].
  class AzCentral < Base
    def self.article_link(entry, _source)
      entry[:feedburner_origLink].encode('UTF-8', invalid: :replace, undef: :replace, replace: '?').html_safe
    end

    def self.article_doc(entry, _source, _link)
      Nokogiri.HTML(entry[:content_encoded])
    end
  end
end
