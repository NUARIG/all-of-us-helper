#!/usr/bin/env bash
cd /var/www/apps/all-of-us-helper/current
/usr/local/rvm/bin/rvm-shell -c 'RAILS_ENV=production /var/www/apps/all-of-us-helper/current/bin/delayed_job --pid-dir=/var/www/apps/all-of-us-helper/shared/pids/ stop'