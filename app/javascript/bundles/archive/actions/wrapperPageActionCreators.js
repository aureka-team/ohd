/* eslint-disable import/prefer-default-export */
import Loader from '../../../lib/loader'

import {
    RECEIVE_STATIC_CONTENT,
    REQUEST_STATIC_CONTENT,
    HOME_CONTENT_URL
} from '../constants/archiveConstants';

const requestStaticContent = () => ({
    type: REQUEST_STATIC_CONTENT
});


function receiveStaticContent(json){
    return {
        type: RECEIVE_STATIC_CONTENT,
        externalLinks: json.external_links,
        homeContent: json.home_content,
        translations: json.translations,
        countryKeys: json.country_keys,
        collections: json.collections,
        contributionTypes: json.contribution_types,
        rootRegistryEntry: json.root_registry_entry,
        registryEntrySearchFacets: json.registry_entry_search_facets,
        personPropertiesRegistryReferenceType: json.metadata_fields_registry_reference_type,
        languages: json.languages,
        uploadTypes: json.upload_types,
        locales: json.locales,
        viewModes: json.view_modes,
        viewMode: json.view_mode,
        listColumns: json.list_columns,
        detailViewFields: json.detail_view_fields,
        project: json.project,
        projectDoi: json.project_doi,
        hiddenRegistryEntryIds: json.hidden_registry_entry_ids,
        projectName: json.project_name,
        projectDomain: json.project_domain,
        archiveDomain: json.archive_domain,
        mediaStreams: json.media_streams,
        fullnameOnLandingPage:json.fullname_on_landing_page,
        receivedAt: Date.now()
    }
}

export function fetchStaticContent(archiveId) {
    return dispatch => {
        dispatch(requestStaticContent())
        Loader.getJson(`${HOME_CONTENT_URL}`, null, dispatch, receiveStaticContent);
    }
}


