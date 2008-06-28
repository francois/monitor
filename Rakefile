task :rebase do
  sh "git checkout master"
  %w(app future db slave web).each do |role|
    sh "git checkout #{role}"
    sh "git rebase master"
  end
end
