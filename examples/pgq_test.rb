class PgqTest < PgqConsumer
  QUEUE_NAME = 'test_queue'
  TYPE = 'test'

  def initialize(queue, logger = Rails.logger)
    @logger = logger
    super(QUEUE_NAME, PgqRunner::PGQ_CONSUMER)
  end

  def perform_event event
    if event.type == TYPE
				puts event.data * event.data
      end
    else
      event_failed event.id, "Unknown event type '#{event.type}'"
    end
  end

end
