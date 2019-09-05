import {connect} from 'react-redux';

import VideoPlayer from '../components/VideoPlayer';
import {handleVideoTimeChange, handleVideoEnded, setNextTape, setTapeAndTimeAndResolution} from '../actions/videoPlayerActionCreators';
import {handleTranscriptScroll} from '../actions/interviewActionCreators';
import {openArchivePopup} from '../actions/archivePopupActionCreators';

import { getInterview, getProject } from '../../../lib/utils';

const mapStateToProps = (state) => {
    let interview = getInterview(state);
    let project = getProject(state);
    return {
        project: project && project.identifier,
        archiveId: state.archive.archiveId,
        locale: state.archive.locale,
        locales: (project && project.locales) || state.archive.locales,
        translations: state.archive.translations,
        tape: state.interview.tape,
        videoTime: state.interview.videoTime,
        videoStatus: state.interview.videoStatus,
        currentSegment: state.interview.currentSegment,
        people: state.data.people,
        contributionTypes: state.archive.contributionTypes,
        mediaStreams: state.archive.mediaStreams,
        resolution: state.interview.resolution,
    }
}

const mapDispatchToProps = (dispatch) => ({
    handleVideoTimeChange: time => dispatch(handleVideoTimeChange(time)),
    handleVideoEnded: () => dispatch(handleVideoEnded()),
    setNextTape: () => dispatch(setNextTape()),
    setTapeAndTimeAndResolution: (tape, time, resolution) => dispatch(setTapeAndTimeAndResolution(tape, time, resolution)),
    handleTranscriptScroll: bool => dispatch(handleTranscriptScroll(bool)),
    openArchivePopup: (params) => dispatch(openArchivePopup(params))
})

export default connect(mapStateToProps, mapDispatchToProps)(VideoPlayer);
