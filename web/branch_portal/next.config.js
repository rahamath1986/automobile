/** @type {import('next').NextConfig} */
const nextConfig = {
  reactStrictMode: true,
  output: 'export',
  basePath: '/automobile/branch',
  trailingSlash: true,
  images: {
    unoptimized: true,
  },
};

module.exports = nextConfig;

