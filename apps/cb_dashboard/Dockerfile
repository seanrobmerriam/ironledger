FROM golang:1.25.7-bookworm AS builder

WORKDIR /src/apps/cb_dashboard

COPY apps/cb_dashboard/ ./

RUN mkdir -p dist \
    && GOOS=js GOARCH=wasm go build -o dist/ironledger.wasm . \
    && if [ -f "$(go env GOROOT)/misc/wasm/wasm_exec.js" ]; then \
         cp "$(go env GOROOT)/misc/wasm/wasm_exec.js" dist/wasm_exec.js; \
       else \
         cp "$(go env GOROOT)/lib/wasm/wasm_exec.js" dist/wasm_exec.js; \
       fi

FROM nginx:1.27-alpine

COPY --from=builder /src/apps/cb_dashboard/dist /usr/share/nginx/html

EXPOSE 80
