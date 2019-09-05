import { connect } from 'react-redux';
import Carousel from '../components/Carousel';
import { getInterview } from '../../../lib/utils';
import { openArchivePopup, closeArchivePopup } from '../actions/archivePopupActionCreators';
import { deleteData } from '../actions/dataActionCreators';
import { getCookie } from '../../../lib/utils';

const mapStateToProps = (state) => {
    return {
        locale: state.archive.locale,
        archiveId: state.archive.archiveId,
        editView: getCookie('editView'),
        translations: state.archive.translations,
        account: state.data.accounts.current,
        interview: getInterview(state),
        project: project && project.identifier,
    }
}

const mapDispatchToProps = (dispatch) => ({
    deleteData: (dataType, id, nestedDataType, nestedId) => dispatch(deleteData(dataType, id, nestedDataType, nestedId)),
    openArchivePopup: (params) => dispatch(openArchivePopup(params)),
    closeArchivePopup: () => dispatch(closeArchivePopup())
})

export default connect(mapStateToProps, mapDispatchToProps)(Carousel);

