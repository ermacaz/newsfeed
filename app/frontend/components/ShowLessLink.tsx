import React from 'react';

interface ShowLessLinkProps {
  handler: (e: React.MouseEvent) => void;
}

class ShowLessLink extends React.Component<ShowLessLinkProps> {
  render(): React.ReactElement {
    return (
      <a className="hover-info show_less_link showMoreLess" onClick={ e=> this.props.handler(e)} href="#" rel="noreferrer">↑ Show Less</a>
    )
  }
}

export default ShowLessLink
