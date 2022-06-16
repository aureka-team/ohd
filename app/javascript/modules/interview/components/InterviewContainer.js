import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';

import { getIsLoggedIn } from 'modules/account';
import { setArchiveId, getInterviewEditView, getProjectId, getLocale } from 'modules/archive';
import { getCurrentInterview, getCurrentInterviewFetched, getIsCatalog, getProjects,
    fetchData, getCurrentProject, getContributorsFetched } from 'modules/data';
import Interview from './Interview';

const mapStateToProps = state => ({
    interview: getCurrentInterview(state),
    interviewIsFetched: getCurrentInterviewFetched(state),
    contributorsAreFetched: getContributorsFetched(state),
    isCatalog: getIsCatalog(state),
    interviewEditView: getInterviewEditView(state),
    projectId: getProjectId(state),
    locale: getLocale(state),
    projects: getProjects(state),
    project: getCurrentProject(state),
    isLoggedIn: getIsLoggedIn(state),
});

const mapDispatchToProps = dispatch => bindActionCreators({
    fetchData,
    setArchiveId,
}, dispatch);

export default connect(mapStateToProps, mapDispatchToProps)(Interview);
