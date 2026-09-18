history = ARGV[0]
file = ARGV[1]

Dir.chdir(File.join(history))
puts `git log '#{file}'`
