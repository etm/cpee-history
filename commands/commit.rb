history = ARGV[0]
new = ARGV[1]
author = ARGV[2]

Dir.chdir(File.join(history))
`git -c user.name='#{author}' -c user.email=dev@null.com -c push.default=simple add "#{new}" 2> /dev/null`
`git -c user.name='#{author}' -c user.email=dev@null.com -c push.default=simple commit -m "#{author.gsub(/"/,"'")} modified #{new}"`
#`GIT_TERMINAL_PROMPT=0 git push` rescue nil

