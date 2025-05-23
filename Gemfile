source 'https://rubygems.org'

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?("/")
  "https://github.com/#{repo_name}.git"
end

ruby '3.2.2'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~> 6.0'
# Use PostgreSQL 'pg' gem as the database for Active Record
gem 'pg'
# Use Microsfot SQL Server as the database for Active Record
gem 'tiny_tds'
gem 'activerecord-sqlserver-adapter'

# Use Puma as the app server
gem 'puma', '~> 3.7'
# Use SCSS for stylesheets
gem 'sass-rails', '~> 5.0'
# Use Uglifier as compressor for JavaScript assets
gem 'uglifier', '>= 1.3.0'
# See https://github.com/rails/execjs#readme for more supported runtimes
# gem 'therubyracer', platforms: :ruby

# Use CoffeeScript for .coffee assets and views
gem 'coffee-rails', '~> 4.2'
# Turbolinks makes navigating your web application faster. Read more: https://github.com/turbolinks/turbolinks
gem 'turbolinks', '~> 5'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.5'
# Use Redis adapter to run Action Cable in production
# gem 'redis', '~> 3.0'
# Use ActiveModel has_secure_password
# gem 'bcrypt', '~> 3.1.7'

# Use Capistrano for deployment
# gem 'capistrano-rails', group: :development


gem 'american_date'
gem 'carrierwave', '>= 1.0.0.rc', '< 2.0'
gem 'daemons'
gem 'delayed_job_active_record', '4.1.4'
gem 'devise', '~> 4.7'
gem 'devise_ldap_authenticatable'
gem 'exception_notification'
gem 'ffi', '~> 1.13.1'
gem 'foundation-rails', '6.4.1.2'
gem 'google-cloud'
gem 'haml'
gem 'jquery-rails'
gem 'jquery-ui-rails'
gem 'paper_trail'
gem 'pundit'
gem 'record_tag_helper'
gem 'rest-client'
gem 'retries'
gem 'grpc'
gem 'rbtree', '0.4.6'
# gem 'webpacker'
# gem 'thin', '~> 1.6.4'
gem 'uuid'
gem 'whenever', :require => false
gem 'will_paginate'
gem 'will_paginate-foundation'
gem 'yajl-ruby', require: 'yajl'
gem 'google-api-client', require: 'google/apis/iamcredentials_v1'

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug', platform: :mri
end

group :development do
  # Access an IRB console on exception pages or by using <%= console %> anywhere in the code.
  gem 'web-console'
  gem 'listen', '~> 3.0.5'
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring'
  gem 'spring-watcher-listen', '~> 2.0.0'

  gem 'capistrano', '~> 3.16.0'
  gem 'capistrano-rails'
  gem 'capistrano-rvm'
  # gem 'mailcatcher' 'should not be included in gemfile'
  gem 'rb-readline'
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw, :jruby]

group :test do
  gem 'rspec'
  gem 'rspec-rails'
  gem 'capybara'
  gem 'database_cleaner'
  gem 'selenium-webdriver'
  gem 'factory_bot_rails'
  gem 'shoulda'
  gem 'webmock'
end
