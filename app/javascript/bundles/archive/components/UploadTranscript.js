import React from 'react';
import WrapperPageContainer from '../containers/WrapperPageContainer';
import AuthShowContainer from '../containers/AuthShowContainer';
import Form from '../containers/form/Form';
import ContributionFormContainer from '../containers/ContributionFormContainer';
import { t, fullname } from '../../../lib/utils';

export default class UploadTranscript extends React.Component {

    constructor(props) {
        super(props);
        this.state = {
            hideTapeAndArchiveInputs: false, 
            tapeDurationsSet: false
        };

        this.handleTapeAndArchiveIdFromFileChange = this.handleTapeAndArchiveIdFromFileChange.bind(this);
        this.showContribution = this.showContribution.bind(this);
        //this.handleFileChange = this.handleFileChange.bind(this);
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
        this.props.returnToForm('uploads');
    }

    content() {
        if (
            this.props.processing 
        ) {
            return (
                <div>
                    <p>
                        {t(this.props, 'edit.upload.processing', {archiveId: this.props.processing})}
                    </p>
                    <div 
                        className='return-to-upload'
                        onClick={() => this.returnToForm()}
                    >
                        {t(this.props, 'edit.upload.return')}
                    </div>
                </div>
            )
        } else {
            let _this = this;
            return (
                <div>
                    <p className='explanation'>
                        {t(this.props, `upload.explanation.transcript`)}
                    </p>
                    <Form 
                        scope='transcript'
                        onSubmit={this.props.submitData}
                        submitText='edit.upload_transcript.title'
                        values={{ }}
                        elements={[
                            { 
                                attribute: 'data',
                                elementType: 'input',
                                type: 'file',
                                validate: function(v){return v instanceof File},
                                //handlechangecallback: this.handleFileChange
                            },
                            {
                                elementType: 'select',
                                attribute: 'transcript_language_id',
                                label: t(this.props, 'activerecord.attributes.transcript.transcript_language_id'),
                                values: this.props.languages,
                                withEmpty: true,
                                validate: function(v){return v !== ''} 
                            },
                            { 
                                attribute: 'tape_durations',
                                validate: function(v){return v !== ''}, 
                                //handlechangecallback: this.handleTapeDurationsChange,
                            },
                            { 
                                attribute: 'time_shifts',
                            },
                            { 
                                attribute: 'tape_and_archive_id_from_file',
                                elementType: 'input',
                                type: 'checkbox',
                                handlechangecallback: this.handleTapeAndArchiveIdFromFileChange,
                                help: (
                                    <p>
                                        {t(this.props, 'edit.upload_transcript.tape_and_archive_id_from_file_explanation')}
                                    </p>
                                )
                            },
                            { 
                                attribute: 'archive_id',
                                hidden: this.state.hideTapeAndArchiveInputs,
                                //value: this.state.dummy,
                                //value: this.state.archiveId,
                                validate: function(v){return _this.state.hideTapeAndArchiveInputs || /^[A-z]{2,3}\d{3,4}$/.test(v)}
                            },
                            { 
                                attribute: 'tape_count',
                                hidden: this.state.hideTapeAndArchiveInputs,
                                //value: this.state.dummy,
                                //value: this.state.tapeCount,
                                //validate: function(v){return _this.state.tapeDurationsSet || _this.state.hideTapeAndArchiveInputs || /^\d{1}$/.test(v)}
                            },
                            { 
                                attribute: 'tape_number',
                                hidden: this.state.hideTapeAndArchiveInputs,
                                //value: this.state.dummy,
                                //value: this.state.tapeNumber,
                                //validate: function(v){return _this.state.tapeDurationsSet || _this.state.hideTapeAndArchiveInputs || /^\d{1}$/.test(v)}
                            },
                        ]}
                        subForm={ContributionFormContainer}
                        subFormProps={{withSpeakerDesignation: true}}
                        subFormScope='contribution'
                        subScopeRepresentation={this.showContribution}
                    />
                </div>
            )
        }
    }

    handleTapeAndArchiveIdFromFileChange(name, checked) {
        if (name === 'tape_and_archive_id_from_file') {
            // trigger the handleChange and with it the validate function of the inputs archiveId, tapeCount and tapeNumber
            // in other words: the errors on these inputs would prevent the form from being submitted
            // some new values together with the prop hidden will remove errors on these inputs
            //let dummy = checked ? (new Date) : '';
            this.setState({ 
                //archiveId: dummy,
                //tapeCount: dummy,
                //tapeNumber: dummy,
                hideTapeAndArchiveInputs: checked
            })
        }
    }

    handleTapeDurationsChange(name, value) {
        if (name === 'tape_durations') {
            this.setState({ 
                tapeDurationsSet: /\d+/.test(value)
            })
        }
    }

    //handleFileChange(name, file) {
        //if (name === 'data') {
            //let fileNameParts = file.name.replace(/\.[^/.]+$/, "").split('_')
            //this.setState({ 
                //archiveId: fileNameParts[0],
                //tapeCount: fileNameParts[1],
                //tapeNumber: fileNameParts[2],
            //})
        //}
    //}

    render() {
        let tabIndex = this.props.locales.length + 4;
        let _this = this;
        return (
            <WrapperPageContainer tabIndex={tabIndex}>
                <AuthShowContainer ifLoggedIn={true}>
                    {this.content()}
                </AuthShowContainer>
                <AuthShowContainer ifLoggedOut={true}>
                    {t(this.props, 'devise.failure.unauthenticated')}
                </AuthShowContainer>
            </WrapperPageContainer>
        );
    }
}
