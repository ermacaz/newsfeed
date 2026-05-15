module Sources
  class JustOneCookbook < Base
    def use_inline_image_extraction?; true; end

    def img_src
      source_html = entry[:content].presence || entry[:description]
      Nokogiri.HTML(source_html).xpath('//img').first.attr('src').encode('UTF-8', invalid: :replace, undef: :replace, replace: '?').html_safe
    rescue
      default_img_src
    end

    def description
      # JOC's RSS description has two <p> blocks: [0] is the recipe blurb, [1] is the "READ: <title>" link.
      # Pick the first non-"READ:" paragraph.
      ps = (Nokogiri.HTML(entry[:description]).xpath("//p").map(&:content) rescue [])
      blurb = ps.find { |t| t.present? && !t.strip.start_with?('READ:') }
      return nil unless blurb
      CGI.unescapeHTML(blurb.truncate(1000).encode('UTF-8', invalid: :replace, undef: :replace, replace: '?')).html_safe
    end
  end
end
