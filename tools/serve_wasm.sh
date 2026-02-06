#!/bin/bash
# Serve Flutter WASM build with required COOP/COEP headers

PORT=${1:-8000}
# Assuming script is run from project root
TARGET_DIR="flutter_app/build/web"

if [ ! -d "$TARGET_DIR" ]; then
  echo "Error: $TARGET_DIR not found."
  echo "Make sure you ran: cd flutter_app && flutter build web --wasm"
  exit 1
fi

echo "Serving Zori.pay WASM on http://localhost:$PORT"
echo "Root directory: $TARGET_DIR"
echo "Press Ctrl+C to stop."

cd "$TARGET_DIR" || exit

python3 -c "
import http.server, socketserver

class WASMHandler(http.server.SimpleHTTPRequestHandler):
    def end_headers(self):
        self.send_header('Cross-Origin-Opener-Policy', 'same-origin')
        self.send_header('Cross-Origin-Embedder-Policy', 'require-corp')
        super().end_headers()

socketserver.TCPServer(('', $PORT), WASMHandler).serve_forever()
"
