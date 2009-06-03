class PgqEvent
  attr_accessor :id, :type, :data, :extra1, :extra2, :extra3, :extra4
  
  def initialize pgq_tuple = nil, use_yaml = true
    if pgq_tuple.is_a? Hash
      @id = pgq_tuple['ev_id']
      @type = pgq_tuple['ev_type']
      if use_yaml
        @data = YAML.load pgq_tuple['ev_data']
        @extra1 = YAML.load pgq_tuple['extra1'] if pgq_tuple['extra1']
        @extra2 = YAML.load pgq_tuple['extra2'] if pgq_tuple['extra2']
        @extra3 = YAML.load pgq_tuple['extra3'] if pgq_tuple['extra3']
        @extra4 = YAML.load pgq_tuple['extra4'] if pgq_tuple['extra4']
      else
        @data = pgq_tuple['ev_data']
        @extra1 = pgq_tuple['extra1']
        @extra2 = pgq_tuple['extra2']
        @extra3 = pgq_tuple['extra3']
        @extra4 = pgq_tuple['extra4']
      end
    end
  end
end
