require 'pgq_consumer'
class PgqCooperativeConsumer < PgqConsumer

  attr_accessor :subconsumer_id

  def initialize(queue, consumer_id, subconsumer_id, logger = nil)
    super(queue, consumer_id, logger)
    self.subconsumer_id = subconsumer_id
  end

  protected

  def get_next_batch
    ActiveRecord::Base.pgq_coop_next_batch(queue, consumer_id, subconsumer_id)
  end

  def finish_batch(count = nil)
    ActiveRecord::Base.pgq_coop_finish_batch(@batch_id)
  end

end
