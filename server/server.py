#!/usr/bin/env python3
"""Minimal local static server for nvim-presenter.

Serves index.html (and its assets) from a fixed static directory, and
outline.json from a separate, writable data directory that Neovim
rewrites on save. No dependencies beyond the standard library.

Usage: server.py <port> <static_dir> <data_dir>
"""
import os
import sys
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

CONTENT_TYPES = {
    '.html': 'text/html; charset=utf-8',
    '.json': 'application/json',
}


def make_handler(static_dir, data_dir):
    class Handler(BaseHTTPRequestHandler):
        def log_message(self, *args):
            pass  # keep stdout/stderr quiet; this runs as a background job

        def do_GET(self):
            if self.path == '/' or self.path == '/index.html':
                self._serve(os.path.join(static_dir, 'index.html'), '.html')
            elif self.path == '/outline.json':
                self._serve(os.path.join(data_dir, 'outline.json'), '.json')
            else:
                self.send_error(404)

        def _serve(self, path, ext):
            try:
                with open(path, 'rb') as f:
                    body = f.read()
            except OSError:
                if ext == '.json':
                    body = b'[]'
                else:
                    self.send_error(404)
                    return

            self.send_response(200)
            self.send_header('Content-Type', CONTENT_TYPES[ext])
            self.send_header('Cache-Control', 'no-store')
            self.send_header('Content-Length', str(len(body)))
            self.end_headers()
            self.wfile.write(body)

    return Handler


def main():
    port = int(sys.argv[1])
    static_dir = sys.argv[2]
    data_dir = sys.argv[3]

    handler = make_handler(static_dir, data_dir)
    httpd = ThreadingHTTPServer(('127.0.0.1', port), handler)
    httpd.serve_forever()


if __name__ == '__main__':
    main()
