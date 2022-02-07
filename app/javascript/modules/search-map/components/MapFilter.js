import { useEffect } from 'react';
import PropTypes from 'prop-types';
import classNames from 'classnames';

import { useI18n } from 'modules/i18n';
import { MARKER_COLOR_MULTIPLE_TYPES, useMapReferenceTypes } from 'modules/map';

import useMapFilter from '../map-filter/useMapFilter';
import { MAP_NUM_INITIALLY_SELECTED_TYPES } from '../constants';

export default function MapFilter({
    className,
    initializeMapFilter,
    toggleMapFilter,
}) {
    const { t } = useI18n();
    const { referenceTypes } = useMapReferenceTypes();
    const { locationTypes } = useMapFilter();

    useEffect(() => {
        if (referenceTypes) {
            const initialFilter = referenceTypes
                .map(type => type.id.toString())
                .slice(0, MAP_NUM_INITIALLY_SELECTED_TYPES);
            initializeMapFilter(initialFilter);
        }
    }, [JSON.stringify(referenceTypes)]);

    if (!locationTypes) {
        return null;
    }

    return (
        <div className={classNames('MapFilter', className)}>
            <form className="MapFilter-form">
                {
                    locationTypes.map(type => {
                        return (
                            <label
                                key={type.id}
                                className={classNames('MapFilter-label', { 'is-active': type.filterIsSet })}
                            >
                                <input
                                    className="MapFilter-checkbox"
                                    name={type.name}
                                    type="checkbox"
                                    checked={type.filterIsSet}
                                    onChange={() => toggleMapFilter(type.id.toString())}
                                />
                                {`${type.name} `}
                                <svg
                                    className="MapFilter-icon"
                                    viewBox="0 0 100 100"
                                    xmlns="http://www.w3.org/2000/svg"
                                >
                                    <circle
                                        cx="50"
                                        cy="50"
                                        r="40"
                                        stroke="none"
                                        fill={type.color}
                                    />
                                </svg>
                                {` (${type.locationCount})`}
                            </label>
                        );
                    })
                }
            </form>
            {locationTypes.length > 2 && (
                <div>
                    <p>
                        {t('modules.search_map.multiple_types')}
                        {' '}
                        <svg
                            className="MapFilter-icon"
                            viewBox="0 0 100 100"
                            xmlns="http://www.w3.org/2000/svg"
                        >
                            <circle cx="50" cy="50" r="40" stroke="none" fill={MARKER_COLOR_MULTIPLE_TYPES} />
                        </svg>
                    </p>
                </div>
            )}
        </div>
    );
}

MapFilter.propTypes = {
    className: PropTypes.string,
    initializeMapFilter: PropTypes.func.isRequired,
    toggleMapFilter: PropTypes.func.isRequired,
};
