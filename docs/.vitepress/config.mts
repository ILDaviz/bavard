import { defineConfig } from 'vitepress'

// https://vitepress.dev/reference/site-config
export default defineConfig({
  title: "Bavard",
  description: "A reactive, Eloquent-inspired ORM for Dart & Flutter",
  lang: 'en-US',
  base: '/bavard/',
  cleanUrls: true,
  lastUpdated: true,

  head: [
    ['meta', { name: 'theme-color', content: '#6366f1' }],
  ],

  themeConfig: {
    // https://vitepress.dev/reference/default-theme-config
    logo: { text: '💬 Bavard' }, // Text logo until an image is provided

    nav: [
      { text: 'Home', link: '/' },
      { text: 'Guide', link: '/guide/' },
      { text: 'API', link: '/api/' }
    ],

    search: {
      provider: 'local'
    },

    editLink: {
      pattern: 'https://github.com/ILDaviz/bavard/edit/main/docs/:path',
      text: 'Edit this page on GitHub'
    },

    footer: {
      message: 'Released under the MIT License.',
      copyright: 'Copyright © 2025 Bavard Contributors'
    },

    sidebar: [
      {
        text: 'Getting Started',
        collapsed: false,
        items: [
          { text: 'Introduction', link: '/guide/' },
          { text: 'Installation', link: '/guide/installation' },
          { text: 'Initial Setup', link: '/guide/setup' },
          { text: 'Conventions', link: '/guide/conventions' },
          { text: 'Creating Models', link: '/guide/models' },
        ]
      },
      {
        text: 'Core Concepts',
        collapsed: false,
        items: [
          { text: 'CRUD Operations', link: '/core/crud' },
          { text: 'Query Builder', link: '/core/query-builder' },
          { text: 'Advanced Queries', link: '/core/query-builder-advanced' },
          { text: 'Schema Columns', link: '/core/schema-columns' },
        ]
      },
      {
        text: 'Relationships',
        collapsed: true,
        items: [
          { text: 'Overview', link: '/relationships/' },
          { text: 'HasManyThrough', link: '/relationships/has-many-through' },
          { text: 'Polymorphic', link: '/relationships/polymorphic' },
          { text: 'Eager Loading', link: '/relationships/eager-loading' },
        ]
      },
      {
        text: 'Advanced Features',
        collapsed: true,
        items: [
          { text: 'Type Casting', link: '/advanced/type-casting' },
          { text: 'Mixins Overview', link: '/advanced/mixins' },
          { text: 'Timestamps', link: '/advanced/timestamps' },
          { text: 'Soft Deletes', link: '/advanced/soft-deletes' },
          { text: 'UUIDs', link: '/advanced/uuids' },
          { text: 'Global Scopes', link: '/advanced/global-scopes' },
          { text: 'Mass Assignment', link: '/advanced/mass-assignment' },
          { text: 'Lifecycle Hooks', link: '/advanced/lifecycle-hooks' },
          { text: 'Transactions', link: '/advanced/transactions' },
        ]
      },
      {
        text: 'Tooling & Testing',
        collapsed: true,
        items: [
          { text: 'Code Generation', link: '/tooling/code-generation' },
          { text: 'Testing', link: '/tooling/testing' },
          { text: 'Debugging', link: '/tooling/debugging' },
        ]
      },
      {
        text: 'Reference',
        collapsed: true,
        items: [
          { text: 'Exceptions', link: '/reference/exceptions' },
          { text: 'Database Adapter', link: '/reference/database-adapter' },
          { text: 'Best Practices', link: '/reference/best-practices' },
          { text: 'API Index', link: '/api/' },
        ]
      }
    ],

    socialLinks: [
      { icon: 'github', link: 'https://github.com/ILDaviz/bavard' }
    ]
  }
})
