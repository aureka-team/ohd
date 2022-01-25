import PropTypes from 'prop-types';
import classNames from 'classnames';
import { Listbox, ListboxOption } from '@reach/listbox';
import '@reach/listbox/styles.css';
import { useSelector } from 'react-redux';

import { getMapSections } from 'modules/data';
import { useI18n } from 'modules/i18n';

export default function MapSectionsSelect({
    className,
    section,
    onChange,
}) {
    const mapSections = useSelector(getMapSections);
    const { t, locale } = useI18n();

    if (mapSections.length < 2) {
        return null;
    }

    return (
        <div className={classNames('u-flex', className)}>
            <span id="map_section" className="u-mr-small">
                {t('modules.search_map.map_section')}
            </span>
            <Listbox
                aria-labelledby="map_section"
                value={section}
                onChange={onChange}
            >
                {
                    mapSections.map(section => (
                        <ListboxOption
                            key={section.name}
                            value={section.name}
                        >
                            {section.label[locale]}
                        </ListboxOption>
                    ))
                }
            </Listbox>
        </div>
    );
}

MapSectionsSelect.propTypes = {
    className: PropTypes.string,
    section: PropTypes.string.isRequired,
    onChange: PropTypes.func.isRequired,
};
