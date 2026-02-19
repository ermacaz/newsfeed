import React from 'react';
import Col from 'react-bootstrap/Col'
import NewsStory from './NewsStory'
import ShowHideSwitch from "./ShowHideSwitch";
import Stack from "react-bootstrap/Stack";

interface Story {
  title: string;
  link: string;
  source: string;
  media_url?: string;
  media_url_thumb?: string;
  content?: string | string[];
  description?: string;
}

interface Source {
  source_name: string;
  source_url: string;
  stories: Story[];
}

interface NewsSourceProps {
  source: Source;
  setShowStoryDialog: (story: Story | null) => void;
}

function NewsSource({source, setShowStoryDialog}: NewsSourceProps): React.ReactElement {
  const [hideExtraLinks, setHideExtraLinks] = React.useState(1);

  const handleClick = (e: React.MouseEvent) => {
    const win=window.open(source.source_url, '_blank');
    win?.focus();
  }

  const showExtra = () => {
    setHideExtraLinks(0)
  }

  const hideExtra = () => {
    setHideExtraLinks(1)
  }

  const newsStories = (stories: Story[]) => {
    return stories.map(function(story, index) {
      return (
        <NewsStory key={index} story={story} setShowStoryDialog={setShowStoryDialog}/>
      )
    })
  }

  let stories = [...source.stories];
  if (hideExtraLinks !== 0) {
    stories = stories.slice(0,9)
  }
  return (
    <Col md={4}>
      <h3 style={{marginTop: '1em'}}><span className={'newsSourceTitle'} onClick={handleClick} >{source.source_name}</span></h3>
      <Stack gap={1}>
        {newsStories(stories)}
        <div>{<ShowHideSwitch showExtra={showExtra} hideExtra={hideExtra} sourceName={source.source_name}/>}</div>
      </Stack>
    </Col>
  )

}

export default NewsSource;
