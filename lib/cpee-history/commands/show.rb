history = ARGV[0]
file = ARGV[1]
commit = ARGV[2]

Dir.chdir(File.join(history))
puts `git show '#{commit}:#{file}'`
