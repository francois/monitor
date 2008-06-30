require "rake/testtask"

task :rebase do
  sh "git checkout master"
  %w(app future db slave web).each do |role|
    sh "git checkout #{role}"
    sh "git rebase master"
  end
end

Rake::TestTask.new do |t|
  t.pattern = FileList["test/**/*_test.rb"]
  t.verbose = true
  t.warning = true
end

task :default => :test
