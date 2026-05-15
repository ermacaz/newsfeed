require 'cgi'
require 'nokogiri'

module Sources
  # Base class for per-source parsers. Each source overrides what it needs;
  # the worker calls #title / #description / #img_src / #content_parts and
  # falls back to the entry/article defaults when those return nil.
  #
  # Dispatch happens via Base.for(news_source) — keyed on NewsSource#name
  # via the HANDLERS map. Adding a new source = adding one file under
  # app/sources/ and one entry in HANDLERS.
  class Base
    HANDLERS = {
      '朝日新聞'            => 'Asahi',
      'Asahi'              => 'Asahi',
      '毎日新聞'            => 'Mainichi',
      'Ars Technica'       => 'ArsTechnica',
      'AZ Central'         => 'AzCentral',
      'Google News'        => 'GoogleNews',
      'Hacker News'        => 'HackerNews',
      'Just One Cookbook'  => 'JustOneCookbook',
      'Kotaku'             => 'Kotaku',
      'New York Times'     => 'NewYorkTimes',
      'NHK'                => 'Nhk',
      'NHK EasyNews'       => 'NhkEasyNews',
      'Nikkei'             => 'Nikkei',
      'No Recipes'         => 'NoRecipes',
      'PC GAMER'           => 'PcGamer',
      'Phoenix New Times'  => 'PhoenixNewTimes',
      'Reddit'             => 'Reddit',
      'Slashdot'           => 'Slashdot',
      'Smithsonian'        => 'Smithsonian',
      'The Verge'          => 'TheVerge',
      'Tokyo Reporter'     => 'TokyoReporter',
      'Washington Post'    => 'WashingtonPost',
    }.freeze

    def self.for(source)
      name = HANDLERS[source.name]
      name ? Sources.const_get(name) : Sources::Default
    end

    # --- Class-level config (override per source) ---

    # Some sources need a tweaked article URL (AZ Central uses feedburner_origLink).
    def self.article_link(entry, _source)
      entry[:link]&.encode('UTF-8', invalid: :replace, undef: :replace, replace: '?')&.html_safe&.gsub('reddit.com', NewsSource::TEDDIT_URL)
    end

    # Build the article DOM. Default: HTTP-fetch the link and parse with Nokogiri.
    # AZ Central builds it from the RSS entry's content_encoded; NHK EasyNews returns nil;
    # Google News follows the link's first <a href> redirect to get the real article.
    def self.article_doc(_entry, _source, link)
      Nokogiri.HTML(HTTParty.get(link, headers: { 'User-agent' => 'ermacaz' }).body)
    end

    # Suppression flags. Used by the worker to skip the default
    # description/img/content fallback for sources that explicitly want nothing.
    def self.skip_default_description?; false; end
    def self.skip_default_img?;         false; end
    def self.skip_default_content?;     false; end

    # When the default content extraction runs (article//p), use
    # extract_content_with_images instead so figures get preserved inline.
    # Instance-level so a single class can vary by source.name (e.g. Asahi
    # has Japanese & English variants with different requirements).
    def use_inline_image_extraction?; false; end

    # --- Instance contract (override per source) ---

    attr_reader :entry, :article, :source

    def initialize(entry, article, source)
      @entry = entry
      @article = article
      @source = source
    end

    def title
      raw = entry[:title].force_encoding('utf-8').encode('UTF-8', invalid: :replace, undef: :replace, replace: '?').gsub('&quot;', '"')
      CGI.unescapeHTML(raw).html_safe
    end

    def description
      return nil if self.class.skip_default_description?
      default_description
    end

    def img_src
      return nil if self.class.skip_default_img?
      default_img_src
    end

    def content_parts
      return nil if self.class.skip_default_content?
      default_content_parts
    end

    # Optional override for Reddit videos — preview thumb URL set alongside content.
    def media_url_thumb; nil; end

    # --- Default extraction (used by Base#description/img_src/content_parts
    # and by subclasses that want to compose on top of the default) ---

    def default_description
      return nil if entry[:description].blank?
      CGI.unescapeHTML(entry[:description].truncate(1000).encode('UTF-8', invalid: :replace, undef: :replace, replace: '?').html_safe)
    end

    def default_img_src
      src = if entry[:media_content_url].present?
              entry[:media_content_url]
            elsif entry[:media_thumbnail_url].present?
              entry[:media_thumbnail_url]
            elsif entry[:content_encoded].present?
              (Nokogiri.parse(entry[:content_encoded])&.xpath("//img")&.first&.attribute('src')&.to_s rescue nil)
            end
      if src.blank? && article
        src = article.css('figure img')&.first&.attribute('src')&.to_s
        src = source.url + src if src&.match?(/^\//)
        src = self.class.img_src_filter(src)
      end
      src
    end

    def default_content_parts
      return nil if article.nil?
      parts = if article.xpath("//article").any?
                if use_inline_image_extraction?
                  (self.class.extract_content_with_images(article.xpath("//article").first) rescue article.xpath("//article").first.content.split("\n\n"))
                else
                  (article.xpath("//article").first.xpath('//p').map(&:content) rescue article.xpath("//article").first.content.split("\n\n"))
                end
              else
                self.class.extract_content_with_images(article)
              end
      first_img_idx = parts.index { |p| p.is_a?(String) && p.start_with?("IMAGE:") }
      parts.delete_at(first_img_idx) if first_img_idx
      parts
    end

    # --- Shared helpers (class methods so subclasses can call without an instance) ---

    AD_REGEX = /^PC Gamer is part of Future US Inc|^PC Gamer is supported by its audience|Future US, Inc. Full 7th Floor|^Advertisement$|^Supported by$|^Send any friend a story$|^Follow Al Jazeera|^Sponsor Message|^Sign in|First Look Institute|^Credit\.\.\.$|^Photographs by|10 gift articles to give each month/.freeze

    # Filter out short snippets and boilerplate from a parts array.
    def self.clean_parts(parts)
      return parts unless parts.is_a?(Array)
      parts.map(&:strip).reject(&:blank?).reject { |a| a.length < 5 || a.match?(AD_REGEX) }
    end

    def self.img_src_filter(img_src)
      img_src = img_src&.to_s
      if img_src&.match?(/favicon/) || !img_src&.match?(/png|jpg|jpeg|gif|webp|webm/)
        img_src = nil
      end
      img_src
    end

    def self.extract_content_with_images(node)
      items = []
      node.search('p, figure').each do |el|
        case el.name
        when 'p'
          text = el.content.strip
          items << text if text.present?
        when 'figure'
          src = el.css('img').first&.attribute('src')&.to_s
          items << "IMAGE:#{src}" if src.present?
        end
      end
      items
    end

    # Same description-cleaning chain that most sources reach for.
    def self.clean_description(text, limit: 1000)
      return nil if text.blank?
      CGI.unescapeHTML(text.truncate(limit).encode('UTF-8', invalid: :replace, undef: :replace, replace: '?').html_safe)
    end
  end
end
