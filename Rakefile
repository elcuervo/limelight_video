require 'rake/testtask'

namespace :test do
  Rake::TestTask.new :unit do |t|
    t.pattern = "test/unit/**/*_test.rb"
    t.libs = ["lib", "test"]
  end

  Rake::TestTask.new :integration do |t|
    t.pattern = "test/integration/**/*_test.rb"
    t.libs = ["lib", "test"]
  end
end

task :test => ["test:unit", "test:integration"]
task default: :test
