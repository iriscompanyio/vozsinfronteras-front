# development
FROM node:20-alpine3.18 AS development
RUN apk add --no-cache libc6-compat xdg-utils
WORKDIR /app
COPY package.json package-lock.json* ./
RUN npm install

FROM node:20-alpine3.18 AS builder
RUN apk add --no-cache libc6-compat xdg-utils cpulimit
WORKDIR /app
COPY . .
COPY --from=development /app/node_modules ./node_modules
# RUN cpulimit -l 100 -i -- npm run build
RUN npm run build

FROM nginx:1.23-alpine AS production
ENV NODE_ENV production
RUN echo "http://uk.alpinelinux.org/alpine/v3.8/main" > /etc/apk/repositories ; \
    echo "http://uk.alpinelinux.org/alpine/v3.8/community" >> /etc/apk/repositories ; \
    apk add --no-cache bash ; \
    echo "http://dl-cdn.alpinelinux.org/alpine/v3.8/main" > /etc/apk/repositories ; \
    echo "http://dl-cdn.alpinelinux.org/alpine/v3.8/community" >> /etc/apk/repositories
COPY    ./entrypoint.sh /entrypoint.sh
COPY --from=builder /app/build /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf
EXPOSE 80
RUN     chmod +x /entrypoint.sh
CMD     [ "/entrypoint.sh" ]
