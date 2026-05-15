module Sources
  # Handles both the Japanese-language site ('朝日新聞') and the English variant ('Asahi').
  # The Japanese site is image-heavy so it gets inline image extraction; the English
  # variant uses the default <article>//p extraction.
  class Asahi < Base
    def img_src
      src = article.css('figure img')&.first&.attribute('srcset')&.to_s&.gsub(/^\/\//, '')
      src = "https://" + src if src&.match?(/^www/)
      src.presence || default_img_src
    end

    def use_inline_image_extraction?
      source.name == '朝日新聞'
    end
  end
end
