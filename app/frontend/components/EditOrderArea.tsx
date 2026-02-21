//component EditOrderArea

import React, { useState, useEffect } from "react";
import GridLayout from "react-grid-layout";
import Button from "react-bootstrap/Button";

interface NewsSource {
  source_id: number;
  source_name: string;
  enabled: boolean;
  list_order: number;
}

interface EditOrderAreaProps {
  toggleOrderScreen: () => void;
  newsSources: NewsSource[];
}

function EditOrderArea({toggleOrderScreen, newsSources}: EditOrderAreaProps): React.ReactElement {
  // State to track enabled/disabled status
  const [sources, setSources] = useState(newsSources);

  // Sync state when newsSources prop updates (async fetch completes after mount)
  useEffect(() => {
    if (newsSources.length > 0) {
      setSources(newsSources);
    }
  }, [newsSources]);

  // Filter enabled and disabled sources
  const enabledSources = sources.filter(source => source.enabled !== false);
  const disabledSources = sources.filter(source => source.enabled === false);

  // Generate layout only for enabled sources
  let layout = enabledSources.sort((a, b) => a.list_order - b.list_order).map((newsSource, index) => {
    return {
      i: newsSource.source_id.toString(), // assuming id is unique
      x: index % 3, // will give values 0, 1, 2 for each row
      y: Math.floor(index / 3), // will increment after every 3 columns
      w: 1,
      h: 1
    };
  });

  // Function to toggle enable/disable status
  const toggleSourceStatus = (e: React.MouseEvent, sourceId: number) => {
    // Stop event propagation to prevent GridLayout from capturing it
    e.stopPropagation();
    e.preventDefault();
    e.nativeEvent.stopImmediatePropagation();

    setSources(prevSources =>
      prevSources.map(source =>
        source.source_id === sourceId
          ? { ...source, enabled: !source.enabled }
          : source
      )
    );
  };

  const renderSourceDivs = () => {
    return enabledSources.map((newsSource) => {
      return (
        <div key={newsSource.source_id.toString()} className="edit-order-entry">
          <div className="source-content">
            <span className="drag-handle">⠿</span>
            {newsSource.source_name}
          </div>
          <div className="button-container">
            <Button
              variant="outline-danger"
              size="sm"
              className="ms-2"
              onClick={(e) => toggleSourceStatus(e, newsSource.source_id)}
            >
              Disable
            </Button>
          </div>
        </div>
      )
    });
  };

  const updateLayout = (layout: any[]) => {
    console.log(layout);
    let orderedLayout = layout.sort((a, b) => {
      if (a.y === b.y) {
        return a.x - b.x;
      } else {
        return a.y - b.y;
      }
    });

    // Create layout parameters with enable status
    let layoutParam = sources.map(source => {
      // Find the position in the layout for enabled sources
      const layoutItem = orderedLayout.find(item => item.i === source.source_id.toString());
      const list_order = layoutItem ? orderedLayout.indexOf(layoutItem) : null;

      return {
        id: source.source_id.toString(),
        list_order: list_order !== null ? list_order : source.list_order,
        enabled: source.enabled !== false
      };
    });

    const csrfToken = document.querySelector('meta[name="csrf-token"]')?.getAttribute('content') || '';
    fetch('/news_sources/update_layout', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': csrfToken,
      },
      body: JSON.stringify({layout_order: layoutParam}),
    })
      .catch((error) => {
        console.error('Error:', error);
      });
  }

  // Render disabled sources
  const renderDisabledSources = () => {
    if (disabledSources.length === 0) {
      return <p>No disabled sources</p>;
    }

    return (
      <div className="disabled-sources-list">
        {disabledSources.map(source => (
          <div
            key={source.source_id.toString()}
            className="disabled-source-item"
          >
            {source.source_name}
            <Button
              variant="outline-success"
              size="sm"
              className="ms-2"
              onClick={(e) => toggleSourceStatus(e, source.source_id)}
            >
              Enable
            </Button>
          </div>
        ))}
      </div>
    );
  };

  return (
    <div>
      <div className="grid-container">
        <p className="grid-area-header">Active Sources</p>
        <GridLayout
          className="layout"
          layout={layout}
          cols={3}
          rowHeight={60}
          autoSize={true}
          width={1200}
          draggableHandle=".source-content"
          onLayoutChange={(layout) => {updateLayout(layout)}}
        >
          {renderSourceDivs()}
        </GridLayout>
      </div>

      <div className="disabled-sources-container">
        <h3>Disabled Sources</h3>
        {renderDisabledSources()}
      </div>
    </div>
  )
}

export default EditOrderArea;
