module Sources
  # NHK EasyNews skips the article fetch entirely and only customizes the title
  # (strips the "[MM/DD/YYYY]" date prefix).
  class NhkEasyNews < Base
    def self.article_doc(_entry, _source, _link); nil; end
    def self.skip_default_description?; true; end

    def title
      super.to_s.gsub(/^\[\d\d\/\d\d\/\d\d\d\d\]/, '').strip
    end
  end
end
