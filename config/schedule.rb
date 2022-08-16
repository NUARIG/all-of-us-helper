# Use this file to easily define all of your cron jobs.
#
# It's helpful, but not entirely necessary to understand cron before proceeding.
# http://en.wikipedia.org/wiki/Cron

# Example:
#
# set :output, "/path/to/my/cron_log.log"
#
# every 2.hours do
#   command "/usr/bin/some_great_command"
#   runner "MyModel.some_method"
#   rake "some:great:rake:task"
# end
#
# every 4.days do
#   runner "AnotherModel.prune_old_records"
# end

# Learn more: http://github.com/javan/whenever

set :environment, ENV['RAILS_ENV']
set :output, {:error => 'log/whenever_error.log', :standard => 'log/whenever.log'}

case environment
  when 'production'
    every :wednesday, at: '2:00pm' do # Use any day of the week or :weekend, :weekday
      rake "recruitment:load_export"
    end

    every 1.day, at: ['10:00 am', '4:00 pm'] do
      rake "recruitment:load_cohorts"
    end

    every :day, at: '12:00am' do # Use any day of the week or :weekend, :weekday
      rake "health_pro_api:rotate_service_account_key"
    end

    every :day, at: '12:15am' do # Use any day of the week or :weekend, :weekday
      rake "maintenance:expire_batch_health_pros"
    end

    every :day, at: '12:30am' do # Use any day of the week or :weekend, :weekday
      rake "health_pro_api:import_api"
    end

    every 1.day, at: ['9:00 am', '10:00 am', '11:00 am', '12:00 pm', '1:00 pm', '2:00 pm', '3:00 pm', '4:00 pm', '5:00 pm'] do
      rake "redcap:synch_patients"
    end

    every :day, at: '7:00 pm' do # Use any day of the week or :weekend, :weekday
      rake "redcap:synch_deleted_patients"
    end

    every 1.day, at: ['8:00 am', '2:00 pm'] do
      rake "redcap:synch_patients_to_redcap"
    end
  when 'staging'
end