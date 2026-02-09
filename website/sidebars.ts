import type {SidebarsConfig} from '@docusaurus/plugin-content-docs';

const sidebars: SidebarsConfig = {
  docsSidebar: [
    'intro',
    {
      type: 'category',
      label: 'Architecture',
      items: [
        'architecture',
        'security',
      ],
    },
    {
      type: 'category',
      label: 'Setup',
      items: [
        'getting-started',
        'headscale-setup',
        'ollama-setup',
        'container-setup',
      ],
    },
    {
      type: 'category',
      label: 'Components',
      items: [
        'model-router',
        'mobile-support',
        'offline-mode',
      ],
    },
    {
      type: 'category',
      label: 'Operations',
      items: [
        'update-policy',
        'troubleshooting',
      ],
    },
  ],
};

export default sidebars;
