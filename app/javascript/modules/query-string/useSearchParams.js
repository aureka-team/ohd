import { useMemo } from 'react';
import { useLocation, useNavigate } from 'react-router-dom';
import queryString from 'query-string';

const qsOptions = {
    arrayFormat: 'bracket',
};

export default function useSearchParams() {
    const { search } = useLocation();
    const navigate = useNavigate();

    const params = useMemo(
        () => queryString.parse(search, qsOptions), [search]
    );

    const sortBy = params.sort;
    const sortOrder = params.order;
    const fulltext = params.fulltext;
    const fulltextIsSet = fulltext?.length > 0;
    const yearOfBirthMin = Number.parseInt(params.year_of_birth_min);
    const yearOfBirthMax = Number.parseInt(params.year_of_birth_max);

    const facets = {
        ...params,
    };
    delete facets.sort;
    delete facets.order;
    delete facets.fulltext;
    delete facets.year_of_birth_min;
    delete facets.year_of_birth_max;


    function setSortBy(value) {
        setParam('sort', value);
    }

    function setSortOrder(value) {
        setParam('order', value);
    }

    function setSort(sort, order) {
        const newParams = {
            ...params,
           sort,
           order,
        };
        pushToHistory(newParams);
    }

    function setDefaultSortOptions(sort, order) {
        const newParams = {
            ...params,
           sort,
           order,
        };
        pushToHistory(newParams, true);
    }

    function setFulltext(value) {
        setParam('fulltext', value);
    }

    function setFulltextAndSort(fulltext, sort, order) {
        const newParams = {
            ...params,
           fulltext,
           sort,
           order,
        };
        pushToHistory(newParams);
    }

    function setYearOfBirthRange(min, max) {
        setParams({
            year_of_birth_min: min,
            year_of_birth_max: max,
        });
    }

    function setParam(name, value) {
        const newParams = {
            ...params,
           [name]: value,
        };
        pushToHistory(newParams);
    }

    function setParams(object) {
        const newParams = {
            ...params,
            ...object,
        };
        pushToHistory(newParams);
    }

    function deleteParam(name) {
        const newParams = {
            ...params,
        };
        delete newParams[name];

        pushToHistory(newParams);
    }

    function addFacetParam(name, value) {
        const newParams = {
            ...params,
        };

        const previousValues = newParams[name];

        if (!previousValues) {
            newParams[name] = [value];
        } else {
            if (previousValues.includes(value)) {
                return;
            } else {
                newParams[name] = newParams[name].concat(value);
            }
        }

        pushToHistory(newParams);
    }

    function deleteFacetParam(name, value) {
        const newParams = {
            ...params,
        };

        const previousValues = newParams[name];
        if (!previousValues) {
            // No need to delete.
            return;
        }

        if (!previousValues.includes(value)) {
            // No need to delete.
            return;
        }

        const valueIndex = previousValues.indexOf(value);
        const firstPart = previousValues.slice(0, valueIndex);
        const lastPart = previousValues.slice(valueIndex + 1);
        const newValues = firstPart.concat(lastPart);

        newParams[name] = newValues;

        pushToHistory(newParams);
    }

    function getFacetParam(name) {
        return params[name] || [];
    }

    function resetSearchParams() {
        const newParams = {};
        pushToHistory(newParams);
    }

    function pushToHistory(newParams, replace = false) {
        const options = {
            search: queryString.stringify(newParams, qsOptions),
        };

        navigate(options, { replace });
    }

    const memoizedValue = useMemo(() => {
        return {
            allParams: params,
            sortBy,
            sortOrder,
            yearOfBirthMin,
            yearOfBirthMax,
            fulltext,
            fulltextIsSet,
            facets,
            setSortBy,
            setSortOrder,
            setSort,
            setDefaultSortOptions,
            setFulltext,
            setFulltextAndSort,
            setYearOfBirthRange,
            setParam,
            addFacetParam,
            deleteFacetParam,
            getFacetParam,
            resetSearchParams,
        };
    }, [search]);

    return memoizedValue;
}
