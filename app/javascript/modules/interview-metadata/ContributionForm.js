import { Link } from 'react-router-dom';
import PropTypes from 'prop-types';

import { Form } from 'modules/forms';
import { usePathBase } from 'modules/routes';
import { useI18n } from 'modules/i18n';
import { usePeople } from 'modules/person';
import { Spinner } from 'modules/spinners';

export default function ContributionForm({
    withSpeakerDesignation,
    projects,
    projectId,
    locale,
    data,
    nested,
    contributionTypes,
    interview,
    formClasses,
    onSubmit,
    onSubmitCallback,
    index,
    onCancel,
    submitData,
}) {
    const { t } = useI18n();
    const pathBase = usePathBase();
    const { data: peopleData, isLoading } = usePeople();

    if (isLoading) {
        return <Spinner />;
    }

    const formElements = [
        {
            elementType: 'select',
            attribute: 'person_id',
            values: peopleData,
            value: data?.person_id,
            withEmpty: true,
            validate: v => v !== '',
            individualErrorMsg: 'empty',
        },
        {
            elementType: 'select',
            attribute: 'contribution_type_id',
            values: contributionTypes && Object.values(contributionTypes),
            value: data?.contribution_type_id,
            optionsScope: 'contributions',
            keepOrder: true,
            withEmpty: true,
            validate: v => v !== '',
        },
        {
            elementType: 'select',
            attribute: 'workflow_state',
            values: ["unshared", "public"],
            value: data ? data.workflow_state : 'public',
            optionsScope: 'workflow_states',
        }
    ]
    if (withSpeakerDesignation) {
        formElements.push({
            attribute: 'speaker_designation',
            value: data?.speaker_designation,
        });
    }

    return (
        <>
            <Form
                scope='contribution'
                data={data}
                nested={nested}
                values={{
                    interview_id: interview?.id,
                    workflow_state: data ? data.workflow_state : 'public'
                }}
                onSubmit={(params) => {
                    if (typeof submitData === 'function') {
                        submitData({ locale, projectId, projects }, params, index);
                    }
                    if (typeof onSubmit === 'function') {
                        onSubmit();
                    }
                }}
                onSubmitCallback={onSubmitCallback}
                onCancel={onCancel}
                formClasses={formClasses}
                elements={formElements}
            />
            <p />
            <Link
                to={`${pathBase}/people`}
                className='Link admin'
                onClick={() => {
                    if (typeof onSubmit === 'function') {
                        onSubmit();
                    }
                }}
            >
                {t("edit.person.admin")}
            </Link>
        </>
    );
}

ContributionForm.propTypes = {
    interview: PropTypes.object.isRequired,
    withSpeakerDesignation: PropTypes.bool,
    data: PropTypes.object,
    contributionTypes: PropTypes.object.isRequired,
    formClasses: PropTypes.string,
    locale: PropTypes.string.isRequired,
    project: PropTypes.object.isRequired,
    projectId: PropTypes.string.isRequired,
    projects: PropTypes.object.isRequired,
    translations: PropTypes.object.isRequired,
    submitData: PropTypes.func.isRequired,
    onSubmit: PropTypes.func,
    onCancel: PropTypes.func,
};
