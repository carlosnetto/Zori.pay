#!/usr/bin/env python3
"""
Dev proxy for Flutter + API server.

Two modes:
  1) STATIC mode (default):  serves build/web + proxies /v1/* to API
     python3 dev_server.py

  2) LIVE mode (hot reload):  proxies everything to Flutter dev server,
     except /v1/* which goes to API
     python3 dev_server.py --live 8081

     Then in another terminal:
       flutter run -d chrome --web-port=8081 --web-hostname=localhost

Open http://localhost:8080 in both modes.
"""

import http.server
import os
import urllib.request
import urllib.error
import sys

API_TARGET = "http://localhost:3001"
WEB_DIR = "build/web"
PORT = 8080
FLUTTER_TARGET = None  # set in live mode


def parse_args():
    global PORT, FLUTTER_TARGET
    args = sys.argv[1:]
    if "--live" in args:
        idx = args.index("--live")
        flutter_port = int(args[idx + 1]) if idx + 1 < len(args) else 8081
        FLUTTER_TARGET = f"http://localhost:{flutter_port}"
        args = args[:idx] + args[idx + 2:]
    if args:
        PORT = int(args[0])


class ProxyHandler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        if FLUTTER_TARGET is None:
            super().__init__(*args, directory=WEB_DIR, **kwargs)
        else:
            super().__init__(*args, **kwargs)

    def do_GET(self):
        if self.path.startswith("/v1/"):
            self._proxy_to(API_TARGET)
        elif FLUTTER_TARGET:
            self._proxy_to(FLUTTER_TARGET)
        else:
            # Static mode: SPA fallback for client-side routes
            url_path = self.path.split("?")[0]
            file_path = os.path.join(WEB_DIR, url_path.lstrip("/"))
            if not os.path.isfile(file_path) and not url_path.endswith("/"):
                self.path = "/index.html"
            super().do_GET()

    def do_POST(self):
        if self.path.startswith("/v1/"):
            self._proxy_to(API_TARGET)
        elif FLUTTER_TARGET:
            self._proxy_to(FLUTTER_TARGET)
        else:
            self.send_error(405)

    def _proxy_to(self, target):
        url = f"{target}{self.path}"
        content_length = int(self.headers.get("Content-Length", 0))
        body = self.rfile.read(content_length) if content_length else None

        # Forward all headers except hop-by-hop
        skip = {"host", "connection", "keep-alive", "transfer-encoding"}
        headers = {}
        for key, val in self.headers.items():
            if key.lower() not in skip:
                headers[key] = val

        try:
            req = urllib.request.Request(url, data=body, headers=headers, method=self.command)
            with urllib.request.urlopen(req) as resp:
                self.send_response(resp.status)
                for key, val in resp.getheaders():
                    if key.lower() not in ("transfer-encoding", "connection"):
                        self.send_header(key, val)
                self.end_headers()
                self.wfile.write(resp.read())
        except urllib.error.HTTPError as e:
            self.send_response(e.code)
            for key, val in e.headers.items():
                if key.lower() not in ("transfer-encoding", "connection"):
                    self.send_header(key, val)
            self.end_headers()
            self.wfile.write(e.read())
        except urllib.error.URLError as e:
            self.send_error(502, f"Upstream unreachable ({target}): {e.reason}")

    def log_message(self, format, *args):
        # Color API calls differently
        msg = format % args
        if "/v1/" in msg:
            print(f"  \033[36m[API]\033[0m {msg}")
        elif FLUTTER_TARGET and "/v1/" not in msg:
            print(f"  \033[33m[FLT]\033[0m {msg}")
        else:
            print(f"  {msg}")


if __name__ == "__main__":
    parse_args()
    server = http.server.HTTPServer(("0.0.0.0", PORT), ProxyHandler)
    print(f"\n  Proxy listening on http://localhost:{PORT}")
    print(f"  /v1/*  ->  {API_TARGET}")
    if FLUTTER_TARGET:
        print(f"  /*     ->  {FLUTTER_TARGET}  (live mode)")
        print(f"\n  Run in another terminal:")
        print(f"    flutter run -d chrome --web-port={FLUTTER_TARGET.split(':')[-1]} --web-hostname=localhost\n")
    else:
        print(f"  /*     ->  {WEB_DIR}/  (static mode)\n")
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\nStopped.")
