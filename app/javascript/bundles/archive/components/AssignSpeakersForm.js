import React from 'react';
import Form from '../containers/form/Form';
import ContributionFormContainer from '../containers/ContributionFormContainer';
import { t, fullname } from '../../../lib/utils';
import spinnerSrc from '../../../images/large_spinner.gif'

export default class AssignSpeakersForm extends React.Component {

    constructor(props) {
        super(props);
        this.showContribution = this.showContribution.bind(this);
    }

    showContribution(value) {
        return (
            <span>
                <span>{fullname(this.props, this.props.people[parseInt(value.person_id)]) + ', '}</span>
                <span>{t(this.props, `contributions.${value.contribution_type}`) + ', '}</span>
                <span>{value.speaker_designation}</span>
            </span>
        )
    }

    returnToForm() {
        this.props.returnToForm('interviews');
    }

    msg() {
        let msg;
        if (this.props.initialsStatus.processing_speaker_update === this.props.interview.archive_id) {
            msg = 'edit.update_speaker.processing';
        } 
        return msg;
    }

    render() {
        if (this.msg()) {
            return (
                <div>
                    <p>
                        {t(this.props, msg)}
                    </p>
                </div>
            )
        } else {
            let _this = this;
            return (
                <Form 
                    scope='update_speaker'
                    onSubmit={this.props.submitData}
                    values={{
                        id: this.props.interview.archive_id
                    }}
                    elements={[]}
                    subForm={ContributionFormContainer}
                    subFormProps={{withSpeakerDesignation: true}}
                    subFormScope='contribution'
                    subScopeRepresentation={this.showContribution}
                />
            )
        }
    }
}
