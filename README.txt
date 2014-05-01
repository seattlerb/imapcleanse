= IMAPCleanse

= END OF LIFE

This project is EOL'd and has been superseded by imap_processor.

Rubyforge Project:

http://rubyforge.org/projects/seattlerb/

Documentation:

http://seattlerb.rubyforge.org/IMAPCleanse/

== About

IMAPCleanse removes old, read, unflagged messages from my IMAP mailboxes.

IMAPFlag flags messages I find interesting so I don\'t have to!

Both these tools can do this for you, too!

== Why?

I'm lazy.  I don't delete read messages from my mailboxes because I like to
have context when reading threads.  Since I'm lazy my more-trafficed mailboxes
can end up with tens of thousands of read messages.  Deleting this many
messages with Mail.app is time consuming and boring.

So I wrote imap_cleanse  to clean out my old mailboxes for me.  If I want to
keep a message around for forever I'll just flag it and imap_cleanse won't
touch it.

imap_cleanse eventually became known as Part One of my Plan for Total Email
Domination.

Next up I decided to automatically flag messages that were interesting.  (Part
Two of my Plan for Total Email Domination.)  I defined interesting as messages
I responded to, messages I wrote (naturally!) and messages in response to
messages I wrote.

Part Three of my Plan for Total Email Domination is awaiting more flagged
messages.

== Installing IMAPCleanse

Just install the gem:

  $ sudo gem install IMAPCleanse

== Using imap_cleanse

In short:

  imap_cleanse -H mail.example.com -p mypassword -b Lists/FreeBSD/current,Lists/Ruby -a 30

The help for imap_cleanse should be sufficiently verbose, but here's a couple of
tips:

=== --noop and --verbose

The --noop flag tells imap_cleanse not to delete anything.  When combined with
the --verbose flag you can see how many messages imap_cleanse would have deleted
from which mailboxes.

  $ ruby -Ilib bin/imap_cleanse -nv
  # Connected to mail.example.com:993
  # Logged in as drbrain
  # Cleansing read, unflagged messages older than 26-Feb-2006 17:04 PST
  # Found 23 mailboxes to cleanse:
  #       mail/Lists/FreeBSD/current
  [...]
  #       mail/Lists/Ruby/ZineBoard
  # Selected mail/Lists/FreeBSD/current
  # Scanning for messages
  # Found 0 messages
  [...]
  # Selected mail/Lists/Ruby/ZineBoard
  # Scanning for messages
  # Found 0 messages
  # Done. Found 0 messages in 23 mailboxes

(Since I just ran imap_cleanse it didn't have anything to do.)

=== ~/.imap_cleanse

The ~/.imap_cleanse file can hold your password and other options so you don't
have to type them in on the command line every time.  The format is simple,
just the option name followed by '=' followed by the argument.  (Check -v for
option names.)

No whitespace is stripped from options, so be sure to do that yourself.  Mine
looks something like this:

  Host=mail.example.com
  SSL=true
  Username=drbrain
  Boxes=Lists/FreeBSD/current,Lists/FreeBSD/performance,Lists/FreeBSD/Soekris,Lists/FreeBSD/stable,Lists/Ruby
  Age=30
  Password=my password
  Email=drbrain@segment7.net

== Using imap_flag

In short:

  imap_flag -H mail.example.com -p mypassword -b Lists/FreeBSD/current,Lists/Ruby -e drbrain@segment7.net

The help for imap_flag should be sufficiently verbose and the tips are the same
as those for imap_cleanse.  (imap_flag even reads ~/.imap_cleanse, so you can
shove that extra Email option right in there!)

== Bugs

Yeah, there probably is one, or maybe even three.  Report them here:

http://rubyforge.org/tracker/?group_id=1513

