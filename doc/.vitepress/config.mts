import { defineConfig } from 'vitepress'
import fs from 'fs'
import path from 'path'

const pubspecPath = path.resolve(__dirname, '../../pubspec.yaml')
const pubspecContent = fs.readFileSync(pubspecPath, 'utf-8')
const versionMatch = pubspecContent.match(/version:\s+(\d+\.\d+\.\d+)/)
const bavardVersion = versionMatch ? versionMatch[1] : '0.0.0'
const currentYear = new Date().getFullYear()

// https://vitepress.dev/reference/site-config
export default defineConfig({
  title: "Bavard",
  description: "An Eloquent-inspired ORM for Dart/Flutter. Simplify interactions with SQLite, PostgreSQL, PowerSync, or any SQL-compatible database. Keep your code clean and readable.",
  lang: 'en-US',
  base: '/bavard/',
  cleanUrls: true,
  lastUpdated: true,
  
  vite: {
    define: {
      '__BAVARD_VERSION__': JSON.stringify(bavardVersion)
    }
  },

  head: [
    ['meta', { name: 'theme-color', content: '#6366f1' }],
  ],

  themeConfig: {
    // https://vitepress.dev/reference/default-theme-config
    logo: { text: '💬 Bavard' }, // Text logo until an image is provided

    nav: [
      { text: 'Home', link: '/' },
      { text: 'Guide', link: '/guide/' },
      { text: 'API', link: '/api/' },
      { text: 'Pub.dev', link: 'https://pub.dev/packages/bavard' }
    ],

    search: {
      provider: 'local'
    },

    editLink: {
      pattern: 'https://github.com/ILDaviz/bavard/edit/main/docs/:path',
      text: 'Edit this page on GitHub'
    },

    footer: {
      message: 'Released under the MIT License. Crafted with ❤️ for the Dart ecosystem.',
      copyright: `Copyright © 2025-${currentYear} David Galet and Bavard Contributors`
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
        collapsed: false,
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
          { text: 'Database Adapter', link: '/reference/adapters' },
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
