import React from 'react';
import Form from '../containers/form/Form';
import ContributionFormContainer from '../containers/ContributionFormContainer';
import { t, fullname } from '../../../lib/utils';

export default class InterviewForm extends React.Component {

    constructor(props) {
        super(props);
        this.showContribution = this.showContribution.bind(this);
        this.onSubmit = this.onSubmit.bind(this);
    }

    showContribution(value) {
        return (
            <span>
                <span>{fullname(this.props, this.props.people[parseInt(value.person_id)]) + ', '}</span>
                <span>{t(this.props, `contributions.${value.contribution_type}`) + ', '}</span>
            </span>
        )
    }

    onSubmit(params, locale){
        this.props.submitData(params, locale);
        if (typeof this.props.onSubmitCallback === "function") {this.props.onSubmitCallback()}
    }

    render() {
        let elements = [
            {
                elementType: 'select',
                attribute: 'collection_id',
                values: this.props.collections,
                value: this.props.interview && this.props.interview.collection_id,
                withEmpty: true,
                validate: function(v){return v !== ''},
                individualErrorMsg: 'empty'
            },
            { 
                attribute: 'archive_id',
                value: this.props.interview && this.props.interview.archive_id,
                validate: function(v){return /^[A-z]{2,3}\d{3,4}$/.test(v)}
            },
            {
                elementType: 'select',
                attribute: 'language_id',
                values: this.props.languages,
                value: this.props.interview && this.props.interview.language_id,
                withEmpty: true,
                validate: function(v){return v !== ''} 
            },
            { 
                attribute: 'interview_date',
                value: this.props.interview && this.props.interview.interview_date,
                elementType: 'input',
            },
            { 
                attribute: 'observations',
                value: this.props.interview && this.props.interview.observations && this.props.interview.observations[this.props.locale],
                elementType: 'textarea',
            },
            { 
                attribute: 'video',
                value: this.props.interview && this.props.interview.video,
                elementType: 'input',
                type: 'checkbox'
            },
            { 
                attribute: 'translated',
                value: this.props.interview && this.props.interview.translated,
                elementType: 'input',
                type: 'checkbox'
            },
            {
                elementType: 'select',
                attribute: 'workflow_state',
                values: this.props.interview && Object.values(this.props.interview.transitions_to),
                optionsScope: 'workflow_states',
                withEmpty: true,
            },
        ]

        let props = {
            scope: 'interview',
            values: {id: this.props.interview && this.props.interview.archive_id},
            onSubmit: this.onSubmit,
            submitText: this.props.submitText,
            elements: elements
        }

        if (this.props.withContributions) {
            props['subForm'] = ContributionFormContainer;
            props['subFormProps'] = {};
            props['subFormScope'] = 'contribution';
            props['subScopeRepresentation'] = this.showContribution;
        }

        return React.createElement(Form, props)
    }
}
