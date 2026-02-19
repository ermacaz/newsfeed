import React, { useEffect } from "react";

import Container from 'react-bootstrap/Container';
import Col from "react-bootstrap/Col";
import Row from 'react-bootstrap/Row';
import EditOrderArea from "./EditOrderArea";

import NewsSource from './NewsSource';
import EmbeddedStoryDialog from "./EmbeddedStoryDialog";

interface Story {
  title: string;
  link: string;
  source: string;
  media_url?: string;
  media_url_thumb?: string;
  content?: string | string[];
  description?: string;
}

interface NewsSourceData {
  source_name: string;
  source_url: string;
  stories: Story[];
  source_id: number;
  enabled: boolean;
  list_order: number;
}

function NewsSourcesSet(): React.ReactElement {
  const [newsSources, setNewsSources] = React.useState<NewsSourceData[]>([]);
  const [showStoryDialog, setShowStoryDialog] = React.useState<Story | null>(null);
  const [showConnectionError, setShowConnectionError] = React.useState<number>(0);
  const [editOrderScreen, setEditOrderScreen] = React.useState(false);


  useEffect(() => {
    let ogTags = [];
    if (showStoryDialog !== null) {
      ogTags = [
        { property: 'og:title', content: showStoryDialog.title },
        { property: 'og:description', content: showStoryDialog.description || '' },
        { property: 'og:image', content: showStoryDialog.media_url || '' },
        { property: 'og:url', content: `https://newsfeed.ermacaz.com/#/${showStoryDialog.source}/${showStoryDialog.link}` },
      ];
    } else {
      ogTags = [
        { property: 'og:title', content: 'NewsFeed' },
        { property: 'og:description', content: '' },
        { property: 'og:image', content: '' },
        { property: 'og:url', content: 'https://newsfeed.ermacaz.com' },
      ];
    }

    ogTags.forEach(tag => {
      const existingTag = document.querySelector(`meta[property="${tag.property}"]`);
      if (existingTag) {
        existingTag.setAttribute('content', tag.content);
      } else {
        const newTag = document.createElement('meta');
        newTag.setAttribute('property', tag.property);
        newTag.setAttribute('content', tag.content);
        document.head.appendChild(newTag);
      }
    });
  }, [showStoryDialog]);


  const toggleOrderScreen = () => {
    setEditOrderScreen(!editOrderScreen)
  };

  const newsSourceElements = (newsSourceTrio: NewsSourceData[]) => {
    return newsSourceTrio.map(function(source) {
      return <NewsSource key={source.source_name} source={source} setShowStoryDialog={setShowStoryDialog}/>
    })
  }

  const showSources = (newsSources: NewsSourceData[][]) => {
    return newsSources.map(function (newsSourceTrio, index) {
      return (
        <Row key={index} >
          {newsSourceElements(newsSourceTrio)}
        </Row>
      )
    })
  }

  const getNewsSourceData = () => {
    fetch(`/news_sources`)
      .then(res => res.json())
      .then((newsSources: NewsSourceData[]) => setNewsSources(newsSources))
      .catch((error) => {
        setShowConnectionError(1);
      })
      .finally(() => {
        parseUrlForStory()
      })
  }

  const parseUrlForStory = () => {
    if (window.location.hash && window.location.hash.match(/#\//)) {
      const parts = window.location.hash.split("/")
      fetch(`/news_sources/${parts[1]}/story/${parts[2]}`)
        .then(res => res.json())
        .then((story: Story) => {
          setShowStoryDialog(story)
        })
    }
  }

  const renderOrderLink = () => {
    if (editOrderScreen) {
      return (
        <Row>
          <Col md={{span: 1, offset: 11}}>
            <span className="change_order_link" onClick={toggleOrderScreen}>
              Return
            </span>
          </Col>
        </Row>
      )
    } else {
      return (
        <Row>
          <Col md={{span: 1, offset: 11}}>
            <span className="change_order_link" onClick={toggleOrderScreen}>
              Change Order
            </span>
          </Col>
        </Row>
      )
    }
  }

  useEffect(() => {
    getNewsSourceData()
  }, [])

  if (editOrderScreen) {
    return (
      <>
        {renderOrderLink()}
        <EditOrderArea toggleOrderScreen={toggleOrderScreen} newsSources={newsSources}/>
      </>
    )
  }

  if (showConnectionError !== 0) {
    return(
      <div className={'connection-error'}>Unable to connect to story service</div>
    )
  }
  const chunk_size = 3;
  const localSourceSet = [...newsSources];
  if (localSourceSet.length > 0) {
    const newsSourcesSet = localSourceSet.map(function(e,i) {
      return i%chunk_size===0 ? localSourceSet.slice(i,i+chunk_size) : null;
    }).filter(x=>!!x);
    if (newsSourcesSet.length > 0) {
      return (
        <div>
          {showSources(newsSourcesSet)}
          {showStoryDialog !== null &&
            <EmbeddedStoryDialog story={showStoryDialog} setShowStoryDialog={setShowStoryDialog}/>
          }
          {renderOrderLink()}
        </div>
      )
    } else {
      return (
        <Container fluid>
          <p>Loading</p>
        </Container>
      )
    }
  } else {
    return (
      <Container fluid>
        <p>Loading</p>
      </Container>
    )
  }
}

export default NewsSourcesSet;
