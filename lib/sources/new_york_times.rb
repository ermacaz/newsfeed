module Sources
  class NewYorkTimes < Base
    def img_src
      entry[:media_content_url] || default_img_src
    end
  end
end
