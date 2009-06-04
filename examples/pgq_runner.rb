class PgqRunner
  
  attr_reader :logger
  attr_reader :queues
  
  SLEEP_TIME = 0.5
  
  CACHE_QUEUES = {
    PgqTest::QUEUE_NAME => PgqTest
  }

  PGQ_CONSUMER = "pgq_runner"
  
  def initialize(hint)
    @logger = hint[:logger] || Rails.logger 
    @consumers = []
    if hint[:queues].nil? || hint[:queues].empty?
      raise "Queue not selected"
    end
    hint[:queues].each do |queue|
      if CACHE_QUEUES.include?(queue)
        klass = CACHE_QUEUES[queue]
        @consumers << klass.new(queue, @logger)
      else
        raise "Unknown queue: #{hint[:queue]}"
      end
    end

    @watch_file = hint[:watch_file]
  end
  
  def run
    logger.info "Start running process"
    loop do
      all_queues_is_empty = true
      @consumers.each do |consumer|
        queue_status = consumer.perform_batch @watch_file
        all_queues_is_empty = false if queue_status
        if File.exists?(@watch_file)
          logger.info "Found file #{@watch_file}, now exiting"
          File.unlink(@watch_file)
          exit 0
        end
      end
      if all_queues_is_empty
        sleep SLEEP_TIME
      end
    end
  end
  
end
