require 'hoe'

Hoe.add_include_dirs("../../minitest/dev/lib")

$: << './lib'
require 'imap_client'

Hoe.new 'IMAPCleanse', IMAPClient::VERSION do |s|
  s.summary = 'Removes mailbox oldness, finds mailbox interestingness'
  s.description = 'IMAPCleanse removes old, read, unflagged messages from your IMAP mailboxes so you don\'t have to!
  
IMAPFlag flags messages I find interesting so I don\'t have to!'
  s.author = 'Eric Hodel'
  s.email = 'drbrain@segment7.net'
  s.url = 'http://seattlerb.rubyforge.org/IMAPCleanse'

  s.testlib = :minitest

  s.extra_deps << 'rbayes'
end

