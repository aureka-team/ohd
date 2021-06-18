import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';

import { closeArchivePopup } from 'modules/ui';
import { getCurrentProject, fetchData, deleteData, submitData, getProjects,
    getCurrentAccount, getMediaStreamsForCurrentProject } from 'modules/data';
import { getLocale, getLocales, getProjectId, getTranslations } from 'modules/archive';
import DataList from './DataList';

const mapStateToProps = state => {
    let project = getCurrentProject(state);
    return {
        locale: getLocale(state),
        projectId: getProjectId(state),
        projects: getProjects(state),
        translations: getTranslations(state),
        account: getCurrentAccount(state),
        editView: true,
        //
        data: getMediaStreamsForCurrentProject(state),
        scope: 'media_stream',
        detailsAttributes: ['path', 'media_type'],
        initialFormValues: {project_id: project.id},
        formElements: [
            {
                attribute: 'media_type',
                elementType: 'select',
                values: ['still', 'video', 'audio'],
                withEmpty: true,
            },
            {
                attribute: 'path',
                elementType: 'input',
                help: 'help_texts.media_streams.path'
            },
            {
                attribute: 'resolution',
                elementType: 'input',
            },
        ],
    }
}

const mapDispatchToProps = dispatch => bindActionCreators({
    fetchData,
    deleteData,
    submitData,
    closeArchivePopup,
}, dispatch);

export default connect(mapStateToProps, mapDispatchToProps)(DataList);
