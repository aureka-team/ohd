import PropTypes from 'prop-types';
import classNames from 'classnames';
import { FaPlus, FaMinus } from 'react-icons/fa';

export default function HeaderExpander({
    table,
}) {
    return (
        <button
            type="button"
            className={classNames('Button', 'Button--transparent',
                'Button--icon', 'Button--withoutPadding',
                'Button--primaryAction')}
            onClick={table.getToggleAllRowsExpandedHandler()}
        >
            {table.getIsAllRowsExpanded() ?
                <FaMinus className="Icon" /> :
                <FaPlus className="Icon" />
            }
        </button>
    );
}

HeaderExpander.propTypes = {
    table: PropTypes.object.isRequired,
};
