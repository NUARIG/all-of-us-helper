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
    # every 5.minutes do # 1.minute 1.day 1.week 1.month 1.year is also supported
    #   rake "redcap:assign_invitation_codes"
    # end
    #
    every 3.minutes do # 1.minute 1.day 1.week 1.month 1.year is also supported
      rake "redcap:synch_patients"
    end

    every 10.minutes do # 1.minute 1.day 1.week 1.month 1.year is also supported
      rake "redcap:synch_deleted_patients"
    end

    every 6.hours do # 1.minute 1.day 1.week 1.month 1.year is also supported
      rake "redcap:synch_patients_to_redcap"
    end
  when 'staging'
    # every 5.minutes do # 1.minute 1.day 1.week 1.month 1.year is also supported
    #   rake "redcap:assign_invitation_codes"
    # end
    every 5.minutes do # 1.minute 1.day 1.week 1.month 1.year is also supported
      rake "redcap:synch_patients"
    end

    every 10.minutes do # 1.minute 1.day 1.week 1.month 1.year is also supported
      rake "redcap:synch_deleted_patients"
    end

    every 6.hours do # 1.minute 1.day 1.week 1.month 1.year is also supported
      rake "redcap:synch_patients_to_redcap"
    end
end