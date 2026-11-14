/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    "./src/pages/**/*.{js,ts,jsx,tsx,mdx}",
    "./src/components/**/*.{js,ts,jsx,tsx,mdx}",
    "./src/app/**/*.{js,ts,jsx,tsx,mdx}",
  ],
  theme: {
    extend: {
      colors: {
        brand: {
          50: '#F0F6FF',
          100: '#E0EDFE',
          500: '#1B5AE0',
          600: '#1446B8',
          700: '#0F348F',
          900: '#0A2540',
        },
        slate: {
          850: '#151E2E',
        }
      },
    },
  },
  plugins: [],
};

