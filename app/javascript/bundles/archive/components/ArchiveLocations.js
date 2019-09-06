import React from 'react';
import PropTypes from 'prop-types';
import { t } from '../../../lib/utils';
import {Navigation} from 'react-router-dom'
import LocationsContainer from '../containers/LocationsContainer'

export default class ArchiveLocations extends React.Component {

    static contextTypes = {
        router: PropTypes.object
    }

    locationsLoaded() {
        return !this.props.isArchiveSearching && this.props.foundInterviews.length > 0;
    }

    handleClick(segmentId, archiveId) {
        this.props.searchInInterview(`/${props.projectId}/${props.locale}/searches/interview`, {fulltext: this.props.fulltext, id: archiveId});
        this.context.router.history.push(`/${this.props.locale}/interviews/${archiveId}`);
    }

    // locations() {
    //     let locations = [];
    //     for (let i = 0; i < this.props.foundInterviews.length; i++) {
    //         if (this.props.foundInterviews[i].interviewees.length) {
    //             // let loc = this.props.allPlacesOfBirth
    //             let loc = this.props.foundInterviews[i].interviewees[0].place_of_birth;
    //             if (loc) {
    //                 loc['names'] = this.props.foundInterviews[i].interviewees[0].names;
    //                 loc['archive_id'] = this.props.foundInterviews[i].archive_id;
    //                 locations = locations.concat(loc);
    //             }
    //         }
    //     }
    //     return locations;
    // }

    birthLocation(ref) {
        if (ref.name[this.props.locale]) {
            return (
                <div>
                    {`${t(this.props, 'birth_location')}: ${ref.name[this.props.locale]}`}
                </div>
            )
        }
    }

    popupContent(ref) {
        return (
            <div>
                <h3 className='active_map_popup_text'>
                    {`${ref.names[this.props.locale].firstname} ${ref.names[this.props.locale].lastname}`}
                </h3>
                {this.birthLocation(ref)}
            </div>
        )
    }

    render() {
        return (
            <LocationsContainer
                // data={this.locations()}
                loaded={this.locationsLoaded()}
                handleClick={this.handleClick.bind(this)}
                popupContent={this.popupContent.bind(this)}
            />
        );
    }

}
