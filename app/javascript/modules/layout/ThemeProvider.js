import { useSelector } from 'react-redux';
import { Helmet } from 'react-helmet';

import { getCurrentProject } from 'modules/data';

const DEFAULT_PRIMARY_COLOR =   '#e01217';
const DEFAULT_SECONDARY_COLOR = '#808080';
const DEFAULT_EDITORIAL_COLOR = '#262626';
const DEFAULT_ASPECT_X = 4;
const DEFAULT_ASPECT_Y = 3;

export default function ThemeProvider() {
    const project = useSelector(getCurrentProject);

    const primaryColor = project?.primary_color || DEFAULT_PRIMARY_COLOR;
    const secondaryColor = project?.secondary_color || DEFAULT_SECONDARY_COLOR;
    const editorialColor = project?.editorial_color || DEFAULT_EDITORIAL_COLOR;
    const aspectX = project?.aspect_x || DEFAULT_ASPECT_X;
    const aspectY = project?.aspect_y || DEFAULT_ASPECT_Y;

    return (
        <Helmet>
            <style>{`
                :root {
                    --primary-color: ${primaryColor};
                    --secondary-color: ${secondaryColor};
                    --editorial-color: ${editorialColor};
                    --aspect-x: ${aspectX};
                    --aspect-y: ${aspectY};
                `}
            </style>
        </Helmet>
    );
}
