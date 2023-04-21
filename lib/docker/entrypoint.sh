#!/bin/bash

set -e

if [ -f /usr/src/app/tmp/pids/server.pid ]; then
  rm /usr/src/app/tmp/pids/server.pid
fi

bin/rails log:clear
bundle exec rake db:drop
bundle exec rake db:setup

bundle exec rake db:migrate 
exec bundle exec "$@"
