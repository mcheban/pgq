class PgqTest < PgqConsumer
  QUEUE_NAME = 'test_queue'
  TYPE = 'test'

  def initialize(queue, logger = Rails.logger)
    @logger = logger
    super(QUEUE_NAME, CacheUpdater::PGQ_CONSUMER)
  end

  def perform_event event
    if event.type == TYPE
      event.data.each do |id|
				puts id * id
      end
    else
      event_failed event.id, "Unknown event type '#{event.type}'"
    end
  end

end
