#!/bin/bash
# Start Cloudflare tunnel for Zori API
# Routes production frontend requests to local API server

cloudflared tunnel run zori-api
