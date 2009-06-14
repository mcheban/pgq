require 'active_record'
require 'active_record/migration'

class ActiveRecord::Base
  @@run_on_slave_db = false
  def self.run_on_slave_db
    @@run_on_slave_db
  end

  def self.run_on_slave_db=(value)
    @@run_on_slave_db = value
  end
end


class ActiveRecord::Migration
  class << self
    def with_database_of model
      @conn = model.connection
      raise "NULL connection!" if @conn.nil?

      returning yield do
        @conn = nil
      end
    end

    @skip_on_slave = false
    alias_method :source_migrate, :migrate
    def migrate(direction)
      if ActiveRecord::Base.run_on_slave_db
        ActiveRecord::Base.configurations[RAILS_ENV] = ActiveRecord::Base.configurations[RAILS_ENV + "_slave"]
      end
      source_migrate(direction) unless (ActiveRecord::Base.run_on_slave_db and @skip_on_slave)
    end

    def method_missing(method, *arguments, &block)
      arg_list = arguments.map(&:inspect) * ', '

      msg = "#{method}(#{arg_list})"
      msg += " db: #{@conn.current_database}" if @conn && @conn.respond_to?(:current_database)

      say_with_time msg do
        unless arguments.empty? || method == :execute
          arguments[0] = ActiveRecord::Migrator.proper_table_name(arguments.first)
        end
        (@conn || ActiveRecord::Base.connection).send(method, *arguments, &block)
      end
    end

    def self.name
      "WithDatabaseOf"
    end
  end
end

