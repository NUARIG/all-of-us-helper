namespace :maintenance do
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