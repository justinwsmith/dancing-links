require 'rubygems'
require 'rubygems/package_task'
require 'rake/testtask'
require 'rdoc/task'

task :default => [:test]

Rake::TestTask.new do |t|
  t.test_files = ['test/tc_dancing_links.rb']
  t.verbose = true
end

Rake::RDocTask.new do |rd|
  rd.main = "README.rdoc"
  rd.rdoc_files.include("README.rdoc", "lib/**/*.rb")
end


PKG_FILES = FileList['lib/**/*.rb','[A-Z]*']
TEST_FILES = FileList['test/**/*.rb']

gem_spec = Gem::Specification.new do |s|
  s.platform = Gem::Platform::RUBY
  s.summary = 'Implementation of the "Dancing Links" algorithm.'
  s.name = 'dancing-links'
  s.email = 'justin dot w dot smith at gmail dot com'
  s.authors = ['Justin W Smith']
  s.homepage = 'http://rubyforge.org/projects/sudoku-gtk/'
  s.version = '0.1.0.3'
  s.requirements << 'none'
  s.require_path = 'lib'
  s.files = PKG_FILES
  s.test_files = TEST_FILES
  s.has_rdoc = true
  s.description = <<EOF
  Dancing-links is an implementation of the "Dancing Links" algorthm to solve the
  "Exact Cover" problem.  Algorithm found by Donald Knuth.
EOF
  end

Gem::PackageTask.new(gem_spec) do |t|
  t.need_zip = true
  t.need_tar = true
end

