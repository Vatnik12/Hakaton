FROM nginx:1.27-alpine
COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY index.html /usr/share/nginx/html/index.html
COPY style.css /usr/share/nginx/html/style.css
COPY gnezdo-ui.css /usr/share/nginx/html/gnezdo-ui.css
COPY app.js /usr/share/nginx/html/app.js
COPY gnezdo-ui.js /usr/share/nginx/html/gnezdo-ui.js
COPY api-client.js /usr/share/nginx/html/api-client.js
COPY assets /usr/share/nginx/html/assets
EXPOSE 80
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 CMD wget -qO- http://127.0.0.1/ >/dev/null || exit 1
CMD ["nginx","-g","daemon off;"]