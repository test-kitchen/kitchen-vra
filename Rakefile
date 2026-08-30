require "bundler/gem_tasks"
require "rspec/core/rake_task"

desc "Run the unit tests"
RSpec::Core::RakeTask.new(:unit) do |task|
  task.pattern = "spec/*_spec.rb"
end

desc "Drive the driver through Test Kitchen against a stubbed vRA"
RSpec::Core::RakeTask.new(:integration) do |task|
  task.pattern = "spec/integration/**/*_spec.rb"
end

desc "Run all the tests"
task test: %i{unit integration}

begin
  require "cookstyle/chefstyle"
  require "rubocop/rake_task"
  RuboCop::RakeTask.new(:style) do |task|
    task.options += ["--display-cop-names", "--no-color"]
  end
rescue LoadError
  puts "cookstyle/chefstyle is not available. (sudo) gem install cookstyle to do style checking."
end

task default: %i{test style}

begin
  require "yard"

  # Options and the file list live in .yardopts so that a bare `yard` from the
  # command line produces exactly what `rake doc` does.
  YARD::Rake::YardocTask.new(:doc)

  desc "List anything in lib/ that is still undocumented"
  task :doc_coverage do
    sh "yard stats --list-undoc"
  end
rescue LoadError
  desc "Generate YARD documentation (not installed)"
  task :doc do
    abort "YARD is not installed. Run: bundle install"
  end
end
