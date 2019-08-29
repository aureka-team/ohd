import React from 'react';

import RegistryReferenceFormContainer from '../containers/RegistryReferenceFormContainer';
import RegistryReferenceContainer from '../containers/RegistryReferenceContainer';
import { t, admin } from '../../../lib/utils';

export default class RegistryEntrySearchFacets extends React.Component {

    constructor(props, context) {
        super(props, context);
    }

    componentDidMount() {
        this.loadRegistryEntries();
    }

    componentDidUpdate() {
        this.loadRegistryEntries();
    }

    loadRegistryEntries() {
        if (
            !this.props.registryEntriesStatus[this.props.parentEntryId]
        ) {
            this.props.fetchData('registry_entries', this.props.parentEntryId);
        }

        if (
            !this.props.registryEntriesStatus[`children_for_entry_${this.props.parentEntryId}`] 
        ) {
            this.props.fetchData('registry_entries', null, null, this.props.locale, `children_for_entry=${this.props.parentEntryId}`);
        } 
    }

    registryEntries() {
        let registryEntries = [];
        if (
            this.props.interview && 
            this.props.registryEntriesStatus[`children_for_entry_${this.props.parentEntryId}`] &&
            this.props.registryEntriesStatus[`children_for_entry_${this.props.parentEntryId}`].split('-')[0] === 'fetched'
        ) {
            for (var c in this.props.interview.registry_references) {
                let registryReference = this.props.interview.registry_references[c];
                let registryEntry = this.props.registryEntries[registryReference.registry_entry_id];
                if (registryEntry && registryEntry.parent_ids[this.props.locale].indexOf(this.props.parentEntryId) > -1 && registryReference !== 'fetched') {
                    registryEntries.push(
                        <RegistryReferenceContainer 
                            registryEntry={registryEntry} 
                            registryReference={registryReference} 
                            refObjectType='interview'
                            locale={this.props.locale}
                            key={`registry_reference-${registryReference.id}`} 
                        />
                    );
                }
            }
            if (registryEntries.length > 1) registryEntries.unshift(
                <br key={this.props.parentEntryId}/>
            )
        } 
        if (registryEntries.length > 0) {
            return registryEntries;
        } else if (!admin(this.props, {type: 'RegistryEntry', action: 'create'})){
            return (
                null
            )
        }
    }

    addRegistryReference() {
        if (admin(this.props, {type: 'RegistryEntry', action: 'create'})) {
            return (
                <div
                    className='flyout-sub-tabs-content-ico-link'
                    title={`${this.props.registryEntries[this.props.parentEntryId].name[this.props.locale]} - ${t(this.props, 'edit.registry_reference.new')}`}
                    onClick={() => this.props.openArchivePopup({
                        title: `${this.props.registryEntries[this.props.parentEntryId].name[this.props.locale]} - ${t(this.props, 'edit.registry_reference.new')}`,
                        content: <RegistryReferenceFormContainer 
                                    refObject={this.props.interview} 
                                    refObjectType='Interview' 
                                    interview={this.props.interview} 
                                    parentEntryId={this.props.parentEntryId}
                                    locale={this.props.locale}
                                    goDeeper={true}
                                    //  allowed values: true, false, 'hidden'
                                    selectRegistryReferenceType={false}
                                />
                    })}
                >
                    <i className="fa fa-plus"></i>
                </div>
            )
        } else {
            return null;
        }
    }

    render() {
        if (this.props.registryEntries && this.props.registryEntries[this.props.parentEntryId] && this.registryEntries.length !== 0) {
            return (
                <p>
                    <span className={'flyout-content-label'}>{(this.props.label && this.props.label[this.props.locale]) || this.props.registryEntries[this.props.parentEntryId].name[this.props.locale]}:</span>
                    {this.registryEntries()}
                    {this.addRegistryReference()}
                </p>
            )
        } else {
            return null;
        }
    }
}

