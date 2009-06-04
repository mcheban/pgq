require 'rubygems'

spec = Gem::Specification.new do |s|
  s.name = 'pgq'
  s.version = '0.0.1'
  s.authors = ['Andrey Stikheev', 'Ivan Evtukhovich']
  s.email = 'evtuhovich@gmail.com'
  s.platform = Gem::Platform::RUBY
  s.summary = 'Useful tools for working with PgQ and Londiste'
  s.description = 'This gem contains rake tasks, ActiveRecord extensions
  useful for work with PgQ and Londiste Skytools'
  candidates = Dir.glob("{bin,tasks,docs,lib,tests,examples}/**/*")
  s.files = candidates.delete_if do |item|
    item.include?("CVS") || item.include?(".svn") || item.include?("rdoc") || item.include?("-pre20")
  end
  s.require_path = "lib"
  s.has_rdoc = false
  s.extra_rdoc_files = ["README"]
end

if $0 == __FILE__
  Gem::manage_gems
  Gem::Builder.new(spec).build
end
