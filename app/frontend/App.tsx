import React from "react";
import Container from 'react-bootstrap/Container';
import 'bootstrap/dist/css/bootstrap.css';
import NewsSourcesSet from "./components/NewsSourcesSet";
import './App.css';

const paddedStyle: React.CSSProperties = {
  paddingTop: '1em',
  backgroundColor: '#282a36'
};

function App(): React.ReactElement {
  return (
    <div className="App">
      <header className="App-header">
       <Container fluid style={paddedStyle}>
       <NewsSourcesSet/>
       </Container>
      </header>
    </div>
  );
}

export default App;
