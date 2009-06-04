namespace :pgq do
  def pgq
    "pgqadm.py #{pgq_config}"
  end

	def pgq_config
		"#{RAILS_ROOT + "/config/pgq/#{RAILS_ENV}.ini"}"
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
		"#{RAILS_ROOT + "/config/pgq/londiste_#{RAILS_ENV}.ini"}"
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
