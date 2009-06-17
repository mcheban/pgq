require 'rake'

namespace :pgq do
  def pgq
    "pgqadm.py #{pgq_config}"
  end

	def pgq_config
		"#{RAILS_ROOT + "/config/pgq/#{RAILS_ENV}.ini"}"
	end

	def generate_connectin_string db
		conn_str = "dbname=#{db['database']}"
		conn_str += " user=#{db['username']}" if db['username']
		conn_str += " host=#{db['host']}" if db['host']
		conn_str += " port=#{db['port']}" if db['port']
		conn_str += " pass=#{db['pass']}" if db['pass']
		conn_str
	end

	desc "Generate PgQ and Londiste config from database.yml"
	task :gen_config do
		unless File.exists? File.join(RAILS_ROOT, 'config', 'pgq')
			puts "ERROR: directory config/pgq do not exists"
			exit
		end
		unless File.exists? File.join(RAILS_ROOT, 'config', 'database.yml')
			puts "ERROR: file config/database.yml do not exists"
			exit
		end

		if File.exists? pgq_config
			puts "ERROR: file #{pgq_config} already exists"
			exit
		end

		config = YAML.load File.read(File.join(RAILS_ROOT, 'config', 'database.yml'))

		if config[RAILS_ENV].nil? or config[RAILS_ENV].empty?
			puts "ERROR: there no '#{RAILS_ENV}' section in database.yml"
			exit
		end

		unless config[RAILS_ENV]['adapter'] == 'postgresql'
			puts "ERROR: only postgresql adapter support PgQ"
			exit
		end

		file = <<END
[pgqadm]
job_name = pgq_job
db = #{generate_connectin_string config[RAILS_ENV]}
# how often to run maintenance [seconds]
maint_delay = 600
# how often to check for activity [seconds]
loop_delay = 0.1
logfile = ./log/%(job_name)s.log
pidfile = ./tmp/%(job_name)s.pid
END

		f = File.new pgq_config, 'w'
		f.write file

		slave = config["#{RAILS_ENV}_slave"]
		if slave.nil? or slave.empty? or slave['adapter'] != 'postgresql'
			puts "WARNING: '#{RAILS_ENV}_slave' section not found or incorrect in database.yml"
		else
			file = <<END
[londiste]

# should be unique
job_name = master_to_slave

# source queue location
provider_db = #{generate_connectin_string config[RAILS_ENV]}

# target database - it's preferable to run "londiste replay"
# on same machine and use unix-socket or localhost to connect
subscriber_db = #{generate_connectin_string config["#{RAILS_ENV}_slave"]}

# source queue name
pgq_queue_name = londiste.replika

logfile = ./log/%(job_name)s.log
pidfile = ./tmp/pids/%(job_name)s.pid

# how often to poll event from provider
#loop_delay = 1

# max locking time on provider (in seconds, float)
#lock_timeout = 10.0
END
			f.write file
		end

		f.close
	end

  desc "Install PgQ"
  task :install do
    puts "installing pgq, running: #{pgq} install"
     
    output = `#{pgq} install 2>&1`
    puts output
    if output =~ /pgq is installed/ || output =~ /Reading from.*?pgq.sql$/
      puts "PgQ installed successfully"
    else
      raise "Something went wrong(see above)... Check that you install skytools package and create #{pgq_config}"
    end
  end
  desc "Start PgQ ticker daemon"
  task :start do
    output = `#{pgq} -d ticker 2>&1`
    if output.empty?
      puts "ticker daemon started"
    else
      puts output
    end
  end
  desc "Stop PgQ ticker daemon"
  task :stop do
    output = `#{pgq} -s 2>&1`
    if output.empty?
      puts "ticker daemon stoped"
    else
      puts output
    end
  end
end

namespace :londiste do
  def londiste
    "londiste.py #{londiste_config}"
  end

	def londiste_config
		pgq_config
	end

  namespace :provider do
    desc "Install Londiste on provider"
    task :install do
      puts "installing londiste, running:  provider install"
       
      output = `#{londiste} provider install 2>&1`
      puts output
      if output =~ /londiste is installed/ || output =~ /Reading from.*?londiste.sql$/
        puts "Londiste installed successfully"
      else
        raise "Something went wrong(see above)... Check that you install skytools package and create #{londiste_config}"
      end
    end

    desc "Add all public tables and sequences to provider"
    task :add => :environment do
      tables = ActiveRecord::Base.connection.select_values "SELECT tablename FROM pg_catalog.pg_tables WHERE schemaname = 'public' AND NOT tablename = 'schema_migrations'"
      output = `#{londiste} provider add #{tables.join(' ')} 2>&1`
      puts output

      seqs = ActiveRecord::Base.connection.select_values("SELECT sequence_name FROM information_schema.sequences WHERE sequence_schema = 'public'").map { |e| "public.#{e}" }
      old_seqs = `#{londiste} provider seqs`
      old_seqs = old_seqs.split("\n")
      output = `#{londiste} provider add-seq #{(seqs - old_seqs).join(' ')} 2>&1`
      puts output
    end
  end

  namespace :subscriber do
    desc "Install Londiste on subscriber"
    task :install do
      puts "installing londiste, running: #{londiste} subscriber install"
       
      output = `#{londiste} subscriber install 2>&1`
      puts output
      if output =~ /londiste is installed/ || output =~ /Reading from.*?londiste.sql$/
        puts "Londiste installed successfully"
      else
        raise "Something went wrong(see above)... Check that you install skytools package and create #{londiste_config}"
      end
    end

    desc "Add all tables and sequences to subscriber (run only after londiste:provider:add)"
    task :add => 'environment' do
      tables = ActiveRecord::Base.connection.select_values "SELECT tablename FROM pg_catalog.pg_tables WHERE schemaname = 'public' AND NOT tablename = 'schema_migrations'"
      output = `#{londiste} subscriber add #{tables.join(' ')} 2>&1`
      puts output

      seqs = ActiveRecord::Base.connection.select_values("SELECT sequence_name FROM information_schema.sequences WHERE sequence_schema = 'public'").map { |e| "public.#{e}" }
      old_seqs = `#{londiste} subscriber seqs`
      old_seqs = old_seqs.split("\n")
      cmd = "#{londiste} subscriber add-seq #{(seqs - old_seqs).join(' ')} 2>&1"
      puts cmd
      output = `#{cmd}`
      puts output
    end

    desc "Show replication statistic"
    task :stat do
      puts `#{londiste} subscriber tables`
    end

  end

  desc "Start Londiste replay daemon"
  task :start do
    output = `#{londiste} -d replay 2>&1`
    if output.empty?
      puts "Londiste replay daemon started"
    else
      puts output
    end
  end

  desc "Stop Londiste replay daemon"
  task :stop do
    output = `#{londiste} -s 2>&1`
    if output.empty?
      puts "Londiste replay daemon stoped"
    else
      puts output
    end
  end

  desc "Update replication tables list"
  task :update do
    Rake::Task["londiste:provider:add"].invoke
    Rake::Task["londiste:subscriber:add"].invoke
  end
end


namespace :db do
  task :migrate => :environment do
    ActiveRecord::Migration.verbose = ENV["VERBOSE"] ? ENV["VERBOSE"] == "true" : true
    ActiveRecord::Migrator.migrate("db/migrate/", ENV["VERSION"] ? ENV["VERSION"].to_i : nil)

    #run migration on slave server if it defined
    unless ActiveRecord::Base.configurations[RAILS_ENV + "_slave"].blank?
      ActiveRecord::Base.establish_connection((RAILS_ENV + "_slave").to_sym)
      ActiveRecord::Base.run_on_slave_db = true
      ActiveRecord::Migrator.migrate("db/migrate/", ENV["VERSION"] ? ENV["VERSION"].to_i : nil)
    end
    
    Rake::Task["db:schema:dump"].invoke if ActiveRecord::Base.schema_format == :ruby
  end

  namespace :migrate do
    desc 'Runs the "up" for a given migration VERSION.'
    task :up => :environment do
      version = ENV["VERSION"] ? ENV["VERSION"].to_i : nil
      raise "VERSION is required" unless version
      ActiveRecord::Migrator.run(:up, "db/migrate/", version)
			#run migration up on slave server if it defined
			unless ActiveRecord::Base.configurations[RAILS_ENV + "_slave"].blank?
				ActiveRecord::Base.establish_connection((RAILS_ENV + "_slave").to_sym)
				ActiveRecord::Base.run_on_slave_db = true
				ActiveRecord::Migrator.run(:up, "db/migrate/", version)
			end
      Rake::Task["db:schema:dump"].invoke if ActiveRecord::Base.schema_format == :ruby
    end

    desc 'Runs the "down" for a given migration VERSION.'
    task :down => :environment do
      version = ENV["VERSION"] ? ENV["VERSION"].to_i : nil
      raise "VERSION is required" unless version
      ActiveRecord::Migrator.run(:down, "db/migrate/", version)
			unless ActiveRecord::Base.configurations[RAILS_ENV + "_slave"].blank?
				ActiveRecord::Base.establish_connection((RAILS_ENV + "_slave").to_sym)
				ActiveRecord::Base.run_on_slave_db = true
				ActiveRecord::Migrator.run(:down, "db/migrate/", version)
			end
      Rake::Task["db:schema:dump"].invoke if ActiveRecord::Base.schema_format == :ruby
    end
  end

  desc 'Rolls the schema back to the previous version. Specify the number of steps with STEP=n'
  task :rollback => :environment do
    step = ENV['STEP'] ? ENV['STEP'].to_i : 1
    ActiveRecord::Migrator.rollback('db/migrate/', step)
    Rake::Task["db:schema:dump"].invoke if ActiveRecord::Base.schema_format == :ruby
  end
end
