namespace :maintenance do
  STOP_FILE = File.expand_path('../../../tmp/stop.txt', __FILE__)
  HTML_FILE = File.expand_path('../../../public/maintenance.html', __FILE__)

  desc 'Generates the maintenance warning page'
  task :html do |t|
    require 'haml'
    template = File.expand_path('../../../app/views/maintenance.html.haml', __FILE__)

    File.open(HTML_FILE, 'w:utf-8') do |f|
      f.write Haml::Engine.new(File.read template).render(Object.new)
    end
  end

  desc 'Set tmp/stop.txt to block access to the application'
  task block: :html do
    touch STOP_FILE
  end

  desc 'Restore access to the application'
  task unblock: :html do
    rm_f HTML_FILE
    rm_f STOP_FILE
  end

  desc 'Expire Batch Health Pros'
  task(expire_batch_health_pros: :environment) do  |t, args|
    begin
      BatchHealthPro.by_status(BatchHealthPro::STATUS_READY).each do |batch_healh_pro|
        batch_healh_pro.status = BatchHealthPro::STATUS_EXPIRED
        batch_healh_pro.save!
      end
    rescue => error
      handle_error(t, error)
    end
  end
end

def handle_error(t, error)
  puts error.class
  puts error.message
  puts error.backtrace.join("\n")

  Rails.logger.info(error.class)
  Rails.logger.info(error.message)
  Rails.logger.info(error.backtrace.join("\n"))
  ExceptionNotifier.notify_exception(error)
end