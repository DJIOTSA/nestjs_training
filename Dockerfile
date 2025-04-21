# ---- Base Stage ----
# Use a specific Node version (Choose one that includes corepack, e.g., 18+)
FROM node:18-alpine AS base
WORKDIR /usr/src/app

# Enable corepack to manage PNPM
RUN corepack enable
# Optionally, specify a pnpm version (if needed, otherwise uses version from package.json)
# RUN corepack prepare pnpm@latest --activate

# Copy package files and lockfile
COPY package.json pnpm-lock.yaml* ./
# Omit pnpm-lock.yaml if you want it generated based on package.json during build
# (Less reproducible, similar to npm install vs npm ci)

# Install ONLY production dependencies using pnpm
# --frozen-lockfile ensures we use exactly the versions from the lockfile
RUN pnpm install --prod --frozen-lockfile

# ---- Dependencies Stage ----
# Use base stage with prod deps already installed
FROM base AS dependencies
WORKDIR /usr/src/app
# Copy package files again (needed for pnpm install to detect dev deps)
COPY package.json pnpm-lock.yaml* ./
# Install ALL dependencies (including dev) needed for building
RUN pnpm install --frozen-lockfile

# ---- Build Stage ----
FROM dependencies AS build
WORKDIR /usr/src/app
# Copy all source code
COPY . .
# Build the NestJS application using pnpm run script
RUN pnpm run build

# ---- Production Stage ----
# Start fresh from the base stage (which only has production dependencies)
FROM base AS production
WORKDIR /usr/src/app
# Copy built application from the build stage
COPY --from=build /usr/src/app/dist ./dist
# Production node_modules are already present from the 'base' stage

# Expose the port the app runs on
EXPOSE 3000

# Set NODE_ENV to production by default for this image
ENV NODE_ENV=production

# Command to run the application
# Use pnpm directly if you have specific start scripts or dependencies managed by pnpm run
# CMD ["pnpm", "start:prod"]
# Or stick with node if start:prod just runs node dist/main
CMD ["node", "dist/main"]