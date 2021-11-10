import PropTypes from 'prop-types';
import { Link } from 'react-router-dom';

import { useI18n } from 'modules/i18n';
import { usePathBase } from 'modules/routes';

export default function ProjectLogo({
    logos,
    defaultLocale,
}) {
    const { t, locale } = useI18n();
    const pathBase = usePathBase();

    let src = null;
    if (logos) {
        const logoArray = Object.values(logos);

        const logoForLocale = logoArray.find(logo => logo.locale === locale);
        const logoForDefaultLocale = logoArray.find(logo => logo.locale === defaultLocale);

        src = logoForLocale?.src || logoForDefaultLocale?.src || null;
    }

    return (
        <Link
            to={pathBase}
            className="logo-link"
            title={t('home')}
        >
            <img
                className="logo-img"
                src={src}
                alt="Collection logo"
            />
        </Link>
    );
}

ProjectLogo.propTypes = {
    logos: PropTypes.object.isRequired,
    defaultLocale: PropTypes.string.isRequired,
};
