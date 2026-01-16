/** @type {import('tailwindcss').Config} */
module.exports = {
  darkMode: 'class',
  content: [
    "./.vitepress/**/*.{js,ts,vue}",
    "./**/*.md",
  ],
  theme: {
    extend: {
      colors: {
        brand: {
          light: '#818cf8', // Indigo 400
          DEFAULT: '#6366f1', // Indigo 500
          dark: '#4f46e5', // Indigo 600
        }
      }
    },
  },
  plugins: [],
}
