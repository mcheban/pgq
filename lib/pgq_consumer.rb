class PgqConsumer
  
  attr_accessor :queue, :consumer_id, :logger
  
  def initialize(queue, consumer_id)
    self.queue = queue
    self.consumer_id = consumer_id
  end

  def self.quote(text)
    ActiveRecord::Base.connection.quote(text)
  end

  def self.get_consumer_info
     @get_consumer_info||=ActiveRecord::Base.connection.select_all("select * from pgq.get_consumer_info()")
  end


  def self.failed_event_retry(queue_name, consumer,event_id)
     ActiveRecord::Base.connection.select_value(
             "select * from pgq.failed_event_retry(#{self.quote(queue_name)}, #{self.quote(consumer)},#{event_id.to_i})")
  end
    def self.failed_event_delete(queue_name, consumer,event_id)
     ActiveRecord::Base.connection.select_value(
             "select * from pgq.failed_event_delete(#{self.quote(queue_name)}, #{self.quote(consumer)},#{event_id.to_i})")
  end

  def self.failed_event_count(queue_name, consumer)
     ActiveRecord::Base.connection.select_value("select * from pgq.failed_event_count(#{self.quote(queue_name)}, #{self.quote(consumer)})")
  end

  def self.failed_event_list(queue_name, consumer, cnt=nil, offset=nil)
     offset_str = cnt ? ",#{cnt.to_i},#{offset.to_i}" : ''
     ActiveRecord::Base.connection.select_all("select * from pgq.failed_event_list(#{self.quote(queue_name)}, #{self.quote(consumer)} #{offset_str}) order by ev_id desc")
  end

  def get_batch_events
    @batch_id = get_next_batch
    return unless @batch_id
    ActiveRecord::Base.pgq_get_batch_events(@batch_id)
  end
    
  def get_next_batch
    ActiveRecord::Base.pgq_next_batch(queue, consumer_id)
  end
  
  def finish_batch(count = nil)
    ActiveRecord::Base.pgq_finish_batch(@batch_id)
  end

  def event_failed(event_id, reason)
    ActiveRecord::Base.pgq_event_failed(@batch_id, event_id, reason)
  end

  def event_retry(event_id, retry_seconds)
    ActiveRecord::Base.pgq_event_retry(@batch_id, event_id, retry_seconds)
  end

  def perform_batch(watch_file = nil)
    events = get_batch_events
    logger.debug "batch(#{queue}): #{@batch_id} events: #{events.length}" if logger.present? && events.present?

    return if !events

    events.each do |event|
      if watch_file and File.exists?(watch_file)
        event_retry(event['ev_id'], 0)
      else
        if Rails.env.development? || Rails.env.test?
          perform_event(prepare_event(event))
        else
          begin
            perform_event(prepare_event(event))
          rescue StandardError => ex
            event_failed event['ev_id'], ex
          end
        end
      end
    end

    finish_batch(events.length)
    true
  end

  def prepare_event(event)
    PgqEvent.new(event)
  end

  def add_event(data)
    self.class.add_event(data)
  end

  def self.add_event(data)
    ActiveRecord::Base.pgq_insert_event(self.const_get('QUEUE_NAME'), self.const_get('TYPE'), data.to_yaml)
  end
  
end
