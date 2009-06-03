module Pgq
  
  #-- Function: pgq.create_queue(1)
  #
  #      Creates new queue with given name.
  #
  # Returns:
  #      0 - queue already exists
  #      1 - queue created
  def pgq_create_queue(queue_name)
    connection.select_value("SELECT pgq.create_queue(#{connection.quote queue_name})").to_i
  end
  
  def pgq_drop_queue(queue_name)
    connection.select_value("SELECT pgq.drop_queue(#{connection.quote queue_name})").to_i
  end
  
  def pgq_insert_event(queue_name, ev_type, ev_data, extra1 = nil, extra2 = nil, extra3 = nil, extra4 = nil)
    result = connection.select_value("SELECT pgq.insert_event(#{connection.quote queue_name}, #{connection.quote ev_type}, #{connection.quote ev_data}, #{connection.quote extra1}, #{connection.quote extra2}, #{connection.quote extra3}, #{connection.quote extra4})")
    result ? result.to_i : nil
  end
  
  def pgq_register_consumer(queue_name, consumer_id)
    connection.select_value("SELECT pgq.register_consumer(#{connection.quote queue_name}, #{connection.quote consumer_id})").to_i
  end
  
  def pgq_unregister_consumer(queue_name, consumer_id)
    connection.select_value("SELECT pgq.unregister_consumer(#{connection.quote queue_name}, #{connection.quote consumer_id})").to_i
  end
  
  def pgq_next_batch(queue_name, consumer_id)
    result = connection.select_value("SELECT pgq.next_batch(#{connection.quote queue_name}, #{connection.quote consumer_id})")
    result ? result.to_i : nil
  end
  
  def pgq_get_batch_events(batch_id)
    connection.select_all("SELECT * FROM pgq.get_batch_events(#{batch_id})")
  end
  
  def pgq_event_failed(batch_id, event_id, reason)
    connection.select_value(sanitize_sql(["SELECT pgq.event_failed(?, ?, ?)", batch_id, event_id, reason])).to_i
  end
  
  def pgq_event_retry(batch_id, event_id, retry_seconds)
    connection.select_value(sanitize_sql(["SELECT pgq.event_retry(?, ?, ?)", batch_id, event_id, retry_seconds])).to_i
  end
  
  def pgq_finish_batch(batch_id)
    connection.select_value("SELECT pgq.finish_batch(#{batch_id})")
  end

  # Возвращает
  # select queue_name, queue_ntables, queue_cur_table,
  #           queue_rotation_period, queue_switch_time,
  #           queue_external_ticker,
  #           queue_ticker_max_count, queue_ticker_max_lag,
  #           queue_ticker_idle_period,
  #           (select current_timestamp - tick_time
  #              from pgq.tick where tick_queue = queue_id
  #             order by tick_queue desc, tick_id desc limit 1
  #            ) as ticker_lag
  def pgq_get_queue_info(queue_name)
    connection.select_value(sanitize_sql ["SELECT pgq.get_queue_info(:queue_name)", {:queue_name => queue_name}])
  end

  #-- Function: pgq.force_tick(2)
  #--
  #--      Simulate lots of events happening to force ticker to tick.
  #--
  #--      Should be called in loop, with some delay until last tick
  #--      changes or too much time is passed.
  #--
  #--      Such function is needed because paraller calls of pgq.ticker() are
  #--      dangerous, and cannot be protected with locks as snapshot
  #--      is taken before locking.
  #--
  #-- Parameters:
  #--      i_queue_name     - Name of the queue
  #--
  #-- Returns:
  #--      Currently last tick id.
  def pgq_force_tick(queue_name)
    last_tick = connection.select_value(sanitize_sql ["SELECT pgq.force_tick(:queue_name)", {:queue_name => queue_name}])
    current_tick = connection.select_value(sanitize_sql ["SELECT pgq.force_tick(:queue_name)", {:queue_name => queue_name}])
    cnt=0
    while last_tick!=current_tick and cnt<100
      current_tick = connection.select_value(sanitize_sql ["SELECT pgq.force_tick(:queue_name)", {:queue_name => queue_name}])
      sleep 0.01
      cnt+=1
    end
    current_tick
  end
      
end
