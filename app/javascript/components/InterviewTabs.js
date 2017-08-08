import React from 'react';
import { Tab, Tabs, TabList, TabPanel } from 'react-tabs';

import TableOfContents from '../components/TableOfContents';
import Transcript from '../components/Transcript';
import SearchForm from '../components/SearchForm';
import Locations from '../components/Locations';

export default class InterviewTabs extends React.Component {
  
  constructor(props, context) {
    super(props, context);

    this.state = {
      tabIndex: 1
    }
  }

  render() {
    return (
      <Tabs 
        selectedTabClassName='active' 
        selectedTabPanelClassName='active' 
        selectedIndex={this.state.tabIndex} 
        onSelect={tabIndex => this.setState({ tabIndex })}
        >
        <div className='content-tabs'>
          <TabList>
            <Tab> Inhaltsverzeichnis</Tab>
            <Tab> Transkript</Tab>
            <Tab> Übersetzung</Tab>
            <Tab> Suche</Tab>
            <Tab> Karte</Tab>
          </TabList>
        </div>

        <div className='wrapper-content'>
          <TabPanel forceRender={true} className='column-content'>
            <TableOfContents
              interviewId={this.props.interview.id}
              lang={this.props.interview.lang}
              handleChapterChange={this.props.handleChapterChange}
            />
          </TabPanel>
          <TabPanel forceRender={true} className='column-content'>
            <Transcript
              time={this.props.transcriptTime}
              interviewId={this.props.interview.id}
              lang={this.props.interview.lang}
            />
          </TabPanel>
          <TabPanel forceRender={true} className='column-content'>
            <Transcript
              time={this.props.transcriptTime}
              interviewId={this.props.interview.id}
              lang='de'
            />
          </TabPanel>
          <TabPanel className='column-content'>
            <SearchForm interviewId={this.props.interview.id}/>
          </TabPanel>
          <TabPanel className='column-content'>
            <Locations position={[37.9838, 23.7275]} zoom={13} />
          </TabPanel>
        </div>
      </Tabs>
    );
  }
}
