import React from 'react';
import Row from 'react-bootstrap/Row';
import Col from 'react-bootstrap/Col'
import OverlayTrigger from "react-bootstrap/OverlayTrigger";
import Tooltip from "react-bootstrap/Tooltip";
import { LazyLoadImage } from "react-lazy-load-image-component";
import sanitizeString from "../helpers/sanitizeString";
import generateStoryUrl from "../helpers/generateStoryUrl";
import md5 from "md5";

interface Story {
  title: string;
  link: string;
  source: string;
  media_url?: string;
  media_url_thumb?: string;
  content?: string | string[];
  description?: string;
}

interface NewsStoryProps {
  story: Story;
  setShowStoryDialog: (story: Story | null) => void;
}

function NewsStory({story, setShowStoryDialog}: NewsStoryProps): React.ReactElement {


  const renderTooltip = () => (
    <Tooltip id="button-tooltip" >
      <span className={'tooltipText'}>{sanitizeString(story.description || '')}</span>
    </Tooltip>
  );

  const handleShowStory = (story: Story) => {
    const linkHash = md5(story.link)
    window.history.replaceState(null, linkHash, generateStoryUrl(story));
    fetch(`/news_sources/${story.source}/story/${linkHash}`)
      .then(res => res.json())
      .then((story: Story) => {
        setShowStoryDialog(story)
      })
  }

  const storyLink = () => {
    let title = story.title
    if (story.content) {
      return (
        <a className="hover-info newsStoryHeadline embedStoryLink" onClick={(e) => { e.preventDefault(); handleShowStory(story);}} href={generateStoryUrl(story)}>{sanitizeString(title)}</a>
      )
    } else {
      return (
        <a className="hover-info newsStoryHeadline" href={story.link} target="_blank" rel="noreferrer">{sanitizeString(title)}</a>
      )
    }
  }

  const storyLinkWithOverlay = () => {
    if (story.description && sanitizeString(story.description)?.length && sanitizeString(story.description)!.length > 0) {
      return(
        <OverlayTrigger
          placement="top"
          delay={{show: 50, hide: 300}}
          overlay={renderTooltip()}
        >
          {storyLink()}
        </OverlayTrigger>
      )
    } else {
      return storyLink()
    }
  }

  if (story.media_url_thumb && story.media_url_thumb.length > 0) {
    return (
      <div className={"overflow-hidden"} style={flexContainerStyle}>
        <div style={textColStyle}>
          {storyLinkWithOverlay()}
        </div>
        <div style={imgColStyle}>
          <LazyLoadImage src={story.media_url_thumb || ''}
                         style={imageStyle}
                         alt="story"
          />
        </div>
      </div>
    )
  } else {
      return (
        <Row className={'overflow-hidden'} style={rowStyle}>
          <Col md={12}>
            {storyLink()}
          </Col>
        </Row>
      )
  }
}


export default NewsStory


const imgColStyle: React.CSSProperties = {
  verticalAlign: 'center'
}

const imageStyle: React.CSSProperties = {
  maxHeight: '4em',
  verticalAlign: 'center'
}

const textColStyle: React.CSSProperties = {
  height: '100%',
  width: '75%',
  marginRight: '1em',
  overflow: 'hidden',
  marginTop: '1em',
  marginBottom: '1em',
  display: 'flex'
}

const flexContainerStyle: React.CSSProperties = {
  display: 'flex',
  width: '100%',
  height: '5.7em',
  lineHeight: '1.6em',
  color: 'white',
  paddingBottom: '0.5em',
  paddingTop: '0.5em',
  borderBottom: "1px solid #6272a4",
  alignItems: 'center'
}

const rowStyle: React.CSSProperties = {
  paddingBottom: '0.5em',
  paddingTop: '0.5em',
  borderBottom: "1px solid #6272a4",
  display: 'flex',
  width: '100%',
  alignItems: 'center',
  height: '5.7em',
  lineHeight: '1.6em',
  color: 'white'
}
