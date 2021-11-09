ARG NODE_VERSION=14.18.1
FROM node:${NODE_VERSION} as node

FROM registry.gitlab.com/islandoftex/images/texlive:TL2020-2020-05-17-04-19-src

# Install node and npm
COPY --from=node /usr/local/bin/node /usr/local/bin/
COPY --from=node /usr/local/lib/node_modules/ /usr/local/lib/node_modules/

RUN ln -s /usr/local/bin/node /usr/local/bin/nodejs \
  && ln -s /usr/local/lib/node_modules/npm/bin/npm-cli.js /usr/local/bin/npm

ENV PATH $PATH:/usr/local/bin/node

# Install dependencies
RUN apt-get clean \
  && apt-get update \
  && apt-get install -y \ 
    bc \
    curl \
    memcached \
    coreutils \
  && rm -rf /var/lib/apt/lists/*

ARG WORKDIR=/var/www
WORKDIR ${WORKDIR}

# Cleanup working directory
RUN rm -rf ./*

# Install node packages
COPY package.json ${WORKDIR}/
RUN npm install \ 
  && npm install -g forever

# Build
COPY . ${WORKDIR}/

# Set environment variables
# To set the commit SHA, use `--build-arg VERSION=$(git rev-parse HEAD)` Docker command line argument
ARG VERSION
ARG ALLOWED_ORIGINS="*"
ENV NODE_ENV=production \
  VERSION=${VERSION} \
  ALLOWED_ORIGINS=${ALLOWED_ORIGINS}

# Expose ports
ARG EXPOSED_PORT=2700
EXPOSE ${EXPOSED_PORT}

# Use forever to manage service
CMD ["forever", "--killTree", "app.js"]