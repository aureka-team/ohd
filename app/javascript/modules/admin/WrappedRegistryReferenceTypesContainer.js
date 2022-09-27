import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';

import { getLocale, getProjectId, getTranslations, getEditView } from 'modules/archive';
import { setQueryParams, getRegistryReferenceTypesQuery } from 'modules/search';
import { fetchData, deleteData, submitData, getCurrentProject, getProjectLocales, getProjects,
    getCurrentAccount, getRegistryReferenceTypesForCurrentProject,
    getRegistryReferenceTypesStatus } from 'modules/data';
import WrappedDataList from './WrappedDataList';

const mapStateToProps = (state) => {
    let project = getCurrentProject(state);
    return {
        locale: getLocale(state),
        locales: getProjectLocales(state),
        projectId: getProjectId(state),
        projects: getProjects(state),
        translations: getTranslations(state),
        account: getCurrentAccount(state),
        editView: getEditView(state),
        data: getRegistryReferenceTypesForCurrentProject(state),
        dataStatus: getRegistryReferenceTypesStatus(state),
        resultPagesCount: getRegistryReferenceTypesStatus(state).resultPagesCount,
        query: getRegistryReferenceTypesQuery(state),
        outerScope: 'project',
        outerScopeId: project.id,
        scope: 'registry_reference_type',
        sortAttribute: 'name',
        sortAttributeTranslated: true,
        baseTabIndex: 4 + project.has_map,
        detailsAttributes: ['name'],
        initialFormValues: {project_id: project.id},
        formElements: [
            {
                elementType: 'registryEntrySelect',
                attribute: 'registry_entry_id',
                goDeeper: true,
                help: 'help_texts.registry_reference_types.registry_entry_id',
                validate: function(v){return /^\d+$/.test(parseInt(v) && parseInt(v) !== parseInt(project?.root_registry_entry_id))},
            },
            {
                attribute: 'use_in_transcript',
                elementType: 'input',
                type: 'checkbox',
            },
            {
                attribute: 'name',
                multiLocale: true,
            },
        ],
        joinedData: { },
    }
}

const mapDispatchToProps = dispatch => bindActionCreators({
    fetchData,
    deleteData,
    submitData,
    setQueryParams,
}, dispatch);

export default connect(mapStateToProps, mapDispatchToProps)(WrappedDataList);
