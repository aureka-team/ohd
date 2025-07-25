/* global railsMode */

/**
 * Put global constants here.
 */

export const ONE_REM = 16;
export const CSS_BASE_UNIT = 24;

export const SITE_HEADER_HEIGHT_MOBILE = 5 * ONE_REM;
export const SITE_HEADER_HEIGHT_DESKTOP = 6.25 * ONE_REM;
export const CONTENT_TABS_HEIGHT = 3 * ONE_REM;

export const PROJECT_CDOH = 'cdoh';
export const PROJECT_DG = 'dg';
export const PROJECT_MOG = 'mog';
export const PROJECT_ZWAR = 'zwar';
export const PROJECT_CAMPSCAPES = 'campscapes';

export const DEFAULT_LOCALES = ['de', 'en'];
export const SYSTEM_LOCALES = ['de', 'en', 'el', 'es', 'ru', 'uk', 'ar'];

export const VIEWMODE_GRID = 'grid';
export const VIEWMODE_LIST = 'list';
export const VIEWMODE_WORKFLOW = 'workflow';

export const METADATA_SOURCE_INTERVIEW = 'Interview';
export const METADATA_SOURCE_PERSON = 'Person';
export const METADATA_SOURCE_REGISTRY_REFERENCE_TYPE = 'RegistryReferenceType';
export const METADATA_SOURCE_EVENT_TYPE = 'EventType';

export const OHD_LOCATION = 'https://portal.oral-history.digital';
export const OHD_DOMAINS = {
    development: 'http://portal.oral-history.localhost:3000',
    staging: 'https://staging.oral-history.digital',
    production: 'https://portal.oral-history.digital',
    test: 'http://test.portal.oral-history.localhost:47001',
};

export const ALPHA2_TO_ALPHA3 = {
    de: 'ger',
    en: 'eng',
    el: 'gre',
    es: 'spa',
    ru: 'rus',
    uk: 'ukr',
    ar: 'ara',
};

export const ALPHA3_TO_ALPHA2 = {
    ger: 'de',
    ita: 'it',
    eng: 'en',
    dut: 'nl',
    fre: 'fr',
    ara: 'ar',
    rus: 'ru',
    gre: 'el',
    bel: 'be',
    bos: 'bs',
    bul: 'bg',
    cze: 'cs',
    heb: 'he',
    hrv: 'hr',
    hun: 'hu',
    lav: 'lv',
    lit: 'lt',
    mac: 'mk',
    nor: 'no',
    per: 'fa',
    pol: 'pl',
    rum: 'ro',
    slo: 'sk',
    slv: 'sl',
    spa: 'es',
    srp: 'sr',
    tam: 'ta',
    tir: 'ti',
    tur: 'tr',
    ukr: 'uk',
    // using alpha-3 for languages without alpha-2
    rom: 'rom',
    cat: 'ca',
    'ukr-rus': 'uk',
    zza: 'zz',
};

const ANALYTICS_URLS = {
    development: '//localhost:8080/',
    staging: '//metrics.oral-history.digital/',
    production: '//metrics.oral-history.digital/',
};
export const ANALYTICS_URL_BASE = ANALYTICS_URLS[railsMode];

export const SHOW_SYSTEM_WARNING = false;
