import React from 'react';
import { t, fullname, admin } from '../../../lib/utils';
import ContributionFormContainer from '../containers/ContributionFormContainer';
import PersonContainer from '../containers/PersonContainer';

export default class InterviewContributors extends React.Component {

    contributors() {
        let contributionTypes = {};
        if (
            this.props.interview &&
            this.props.peopleStatus[`contributors_for_interview_${this.props.interview.id}`] &&
            this.props.peopleStatus[`contributors_for_interview_${this.props.interview.id}`].split('-')[0] === 'fetched' && 
            this.props.contributionTypes
        ) {
            for (var c in this.props.interview.contributions) {
                let contribution = this.props.interview.contributions[c];
                if (contribution !== 'fetched' && contribution.contribution_type !== 'interviewee') {
                    if (!contributionTypes[contribution.contribution_type]) {
                        contributionTypes[contribution.contribution_type] = [<span key={`contribution-${contribution.id}`} className='flyout-content-label'>{t(this.props, `contributions.${contribution.contribution_type}`)}: </span>];
                    }
                    contributionTypes[contribution.contribution_type].push(<PersonContainer data={this.props.people[contribution.person_id]} contribution={true} key={`contribution-${contribution.id}`} />)
                }
            }
        } 
        return Object.keys(contributionTypes).map((key, index) => {
            return (
              <div>
                <p>{contributionTypes[key]}</p>
              </div>
            );
        })
    }

    addContribution() {
        if (admin(this.props, {type: 'Contribution', action: 'create'})) {
            return (
                <div
                    className='flyout-sub-tabs-content-ico-link'
                    title={t(this.props, 'edit.contribution.new')}
                    onClick={() => this.props.openArchivePopup({
                        title: t(this.props, 'edit.contribution.new'),
                        content: <ContributionFormContainer interview={this.props.interview} submitData={this.props.submitData} />
                    })}
                >
                    <i className="fa fa-plus"></i>
                </div>
            )
        }
    }

    contributions() {
        return (
            <div>
                {this.contributors()}
                {this.addContribution()}
            </div>
        );
    }

    render() {
        if (this.props.interview) {
            return (
                <div>
                    {this.contributions()}
                </div>
            );
        } else {
            return null;
        }
    }
}

