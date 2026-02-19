import React from 'react';

interface ShowMoreLinkProps {
  handler: (e: React.MouseEvent) => void;
}

class ShowMoreLink extends React.Component<ShowMoreLinkProps> {
  render(): React.ReactElement {
    return (
      <a className="hover-info showMoreLess" onClick={ e=> this.props.handler(e)} href="#" rel="noreferrer">↓ Show More</a>
    )
  }
}

export default ShowMoreLink
