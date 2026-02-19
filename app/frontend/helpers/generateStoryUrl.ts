import md5 from "md5";

interface Story {
  source: string;
  link: string;
}

const generateStoryUrl = (story: Story): string => {
  return "#/" + story.source + '/' + md5(story.link)
}

export default generateStoryUrl;
