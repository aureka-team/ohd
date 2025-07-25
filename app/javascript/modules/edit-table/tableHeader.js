export default function tableHeader({
    interview: interview,
    column: column,
    t: t,
}) {
    const translationParams = {
        original_locale: interview.alpha3,
        translation_locale: interview.translation_alpha3,
    };

    const header = /heading|translation|annotation/.test(column) ?
        (t(`edit_column_header.${column.split('_')[0]}`) + ` (${column.split('_')[1]})`) :
        t(`edit_column_header.${column}`, translationParams).join('');
    return header;
}
