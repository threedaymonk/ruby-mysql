require "rubygems"
require "rake/gempackagetask"
require "rake/rdoctask"
require "lib/mysql/version"

task :default => :package do
  puts "Don't forget to write some tests!"
end

spec = Gem::Specification.new do |s|

  s.name              = "ruby-mysql"
  s.version           = Mysql::Version::STRING
  s.summary           = "Pure Ruby MySQL"
  s.author            = "TOMITA Masahiro"

  s.has_rdoc          = false

  # Add any extra files to include in the gem (like your README)
  s.files             = %w() + Dir.glob("{lib}/**/*")

  s.require_paths     = ["lib"]
end

Rake::GemPackageTask.new(spec) do |pkg|
  pkg.gem_spec = spec

  # Generate the gemspec file for github.
  file = File.dirname(__FILE__) + "/#{spec.name}.gemspec"
  File.open(file, "w") {|f| f << spec.to_ruby }
end

# Generate documentation
Rake::RDocTask.new do |rd|

  rd.rdoc_files.include("lib/**/*.rb")
  rd.rdoc_dir = "rdoc"
end

desc 'Clear out RDoc and generated packages'
task :clean => [:clobber_rdoc, :clobber_package] do
  rm "#{spec.name}.gemspec"
end
