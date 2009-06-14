# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{pgq}
  s.version = "0.1.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Ivan Evtukhovich", "Andrey Stikheev"]
  s.date = %q{2009-06-12}
  s.email = ['evtuhovich@gmail.com', 'andrey.stikheev@gmail.com']
  s.extra_rdoc_files = [
    "README"
  ]
  s.files = [
    ".gitignore",
     "MIT-LICENSE",
     "README",
     "Rakefile",
     "VERSION",
     "examples/pgq_runner.rb",
     "examples/pgq_test.rb",
     "init.rb",
     "lib/migration.rb",
     "lib/pgq.rb",
     "lib/pgq_consumer.rb",
     "lib/pgq_event.rb",
     "pgq.gemspec",
     "tasks/pgq.rake"
  ]
  s.homepage = %q{http://github.com/evtuhovich/pgq}
  s.rdoc_options = ["--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.3}
  s.platform = Gem::Platform::RUBY
  s.summary = %q{Useful tools for working with PgQ and Londiste}
  s.description = %q{This gem contains rake tasks, ActiveRecord extensions useful for work with PgQ and Londiste Skytools}
  s.test_files = [
    "test/test_helper.rb",
     "test/pgq_test.rb",
     "examples/pgq_runner.rb",
     "examples/pgq_test.rb"
  ]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
    else
    end
  else
  end
end
