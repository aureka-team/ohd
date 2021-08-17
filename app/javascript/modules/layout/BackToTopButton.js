import { memo } from 'react';
import PropTypes from 'prop-types';
import classNames from 'classnames';
import { FaArrowUp } from 'react-icons/fa';

import { scrollSmoothlyTo } from 'modules/user-agent';
import { useI18n } from 'modules/i18n';

function BackToTopButton({
    visible = false,
    fullscreen = false,
}) {
    const { t } = useI18n();

    const handleClick = () => {
        if (visible) {
            scrollSmoothlyTo(0, 0);
        }
    };

    return (
        <button
            type="button"
            className={classNames('BackToTop', {
                'is-visible': visible,
                'is-fullscreen': fullscreen,
            })}
            aria-label={t('modules.layout.back_to_top.label')}
            title={t('modules.layout.back_to_top.label')}
            onClick={handleClick}
        >
            <FaArrowUp className="BackToTop-icon" />
        </button>
    );
}

BackToTopButton.propTypes = {
    visible: PropTypes.bool,
    fullscreen: PropTypes.bool,
};

const memoizedBackToTopButton = memo(BackToTopButton);

export default memoizedBackToTopButton;
