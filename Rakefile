require 'rubygems'
require 'rake'

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), *%w[lib]))


task :default => [:compile]

desc "Compiles the file"
task :compile do
  sh "ruby stuff.rb > hello.s"
  sh "gcc -o hello hello.s"
end
