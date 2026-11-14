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
          50: '#F5F8FF',
          100: '#E6EFFF',
          500: '#002C6C',
          600: '#002254',
          700: '#00183D',
          900: '#000F26',
        },
        slate: {
          850: '#151E2E',
        }
      },
    },
  },
  plugins: [],
};

