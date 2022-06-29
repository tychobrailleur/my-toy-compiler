require 'rake'

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), *%w[lib]))

task :default => [:compile]

desc "Compiles the file"
task :compile do
  sh "ruby -I. parser.rb > parser.s"
  sh "gcc -no-pie -o parser parser.s runtime.c"
end

task :parser do
  sh "ruby -I. parser.rb > parser.s"
  sh "gcc -no-pie -o parser parser.s runtime.c"
end
