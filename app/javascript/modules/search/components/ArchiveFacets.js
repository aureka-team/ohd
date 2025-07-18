import classNames from 'classnames';

import { useAuthorization } from 'modules/auth';
import { useI18n } from 'modules/i18n';
import { Spinner, SearchSpinnerOverlay } from 'modules/spinners';
import { useEventTypes } from 'modules/event-types';
import FacetDropdown from './FacetDropdown';
import Facet from './Facet';
import BirthYearFacet from './BirthYearFacet';
import RangeFacet from './RangeFacet';
import useFacets from '../useFacets';

export default function ArchiveFacets() {
    const { locale } = useI18n();
    const { isAuthorized } = useAuthorization();
    const { facets, isLoading } = useFacets();
    const { isLoading: eventTypesAreLoading, data: eventTypes } = useEventTypes();

    if (!facets || eventTypesAreLoading) {
        return <Spinner withPadding />;
    }

    const adminFacets = [
        'tasks_user_ids',
        'tasks_supervisor_ids',
    ];

    return (
        <SearchSpinnerOverlay loading={isLoading}>
            {Object.keys(facets).map(facetName => {
                const facetData = facets[facetName];

                if (facetName === 'year_of_birth') {
                    const years = Object.keys(facetData.subfacets)
                        .map(year => Number.parseInt(year));

                    return (
                        <FacetDropdown
                            key={facetName}
                            facet={facetName}
                            label={facetData.name[locale]}
                        >
                            <BirthYearFacet
                                sliderMin={Math.min(...years)}
                                sliderMax={Math.max(...years)}
                            />
                        </FacetDropdown>
                    );
                } else if (facetData.type === 'EventType') {
                    const eventType = eventTypes.find(et =>
                        et.code === facetData.name)

                    const values = Object.keys(facetData.subfacets);
                    if (!Array.isArray(values) || values.length === 0) {
                        return null;
                    }

                    // Facet values are formatted like:
                    // 1955.0..1960.0
                    // ^       ^
                    // |       |
                    // 0       8
                    const min = Number(values.at(0).slice(0, 4));
                    const max = Number(values.at(-1).slice(8, 12));

                    return (
                        <FacetDropdown
                            key={facetName}
                            facet={facetName}
                            label={eventType.name}
                        >
                            <RangeFacet
                                name={facetName}
                                sliderMin={min}
                                sliderMax={max}
                            />
                        </FacetDropdown>
                    );
                } else {
                    const isAdminFacet = adminFacets.includes(facetName);
                    const isVisible = !isAdminFacet || isAuthorized({ type: 'General' }, 'edit');

                    if (!isVisible) {
                        return null;
                    }

                    return (
                        <FacetDropdown
                            key={facetName}
                            facet={facetName}
                            label={facetData.name[locale]}
                            admin={isAdminFacet}
                        >
                            <Facet
                                facet={facetName}
                                data={facetData}
                            />
                        </FacetDropdown>
                    );
                }
            })}
        </SearchSpinnerOverlay>
    );
}
