
rule '.rb' => ['.rex'] do |task|
  sh "bin/rex #{task.source} -o #{task.name}"
end

task :test => ['OptionSpecsLexer.rb'] do |task|
  sh "bin/rspec *_spec.rb"
end
