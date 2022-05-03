import searchOptionsFromMetadataFields from './searchOptionsFromMetadataFields';

test('returns search options based on metadata settings', () => {
    const metadataFields = [
        {
            'id': 15,
            'name': 'typology',
            'facet_order': 3,
            'use_in_results_table': true,
            'use_in_results_list': true,
        },
        {
            'id': 45,
            'name': 'duration',
            'facet_order': 1,
            'use_in_results_table': true,
            'use_in_results_list': null,
        },
        {
            'id': 17,
            'name': 'archive_id',
            'facet_order': 1,
            'use_in_results_table': null,
            'use_in_results_list': null,
        },
    ];

    const actual = searchOptionsFromMetadataFields(metadataFields);
    const expected = [
        'typology',
        'duration',
    ];
    expect(actual).toEqual(expected);
});
