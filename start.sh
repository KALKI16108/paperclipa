#!/bin/sh
set -e

mkdir -p /paperclip/instances/default/logs
chown -R node:node /paperclip

gosu node node --import ./server/node_modules/tsx/dist/loader.mjs server/dist/index.js &
SERVER_PID=$!

until wget -qO /dev/null http://localhost:3100/api/health 2>/dev/null; do
  sleep 2
done

gosu node node --import ./server/node_modules/tsx/dist/loader.mjs -e "
import { bootstrapCeoInvite } from './cli/src/commands/auth-bootstrap-ceo.js';
bootstrapCeoInvite({ expiresHours: 72 }).catch(e => console.error('Bootstrap error:', e.message));
" 2>&1 || echo "Bootstrap script skipped"

wait $SERVER_PID
