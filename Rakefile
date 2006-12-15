require 'rubygems'
require 'rake'
require 'rake/testtask'
require 'rake/rdoctask'
require 'rake/gempackagetask'
require 'rake/contrib/sshpublisher'

$VERBOSE = nil

spec = Gem::Specification.new do |s|
  s.name = 'IMAPCleanse'
  s.version = '1.2.0'
  s.summary = 'Removes mailbox oldness, finds mailbox interestingness!'
  s.description = 'IMAPCleanse removes old, read, unflagged messages from your IMAP mailboxes so you don\'t have to!
  
IMAPFlag flags messages I find interesting so I don\'t have to!'
  s.author = 'Eric Hodel'
  s.email = 'drbrain@segment7.net'

  s.has_rdoc = true
  s.files = File.read('Manifest.txt').split($/)
  s.require_path = 'lib'
  s.executables = %w[imap_cleanse imap_flag]
end

desc 'Run tests'
task :default => [ :test ]

Rake::TestTask.new('test') do |t|
  t.libs << 'test'
  t.pattern = 'test/test_*.rb'
  t.verbose = true
end

desc 'Update Manifest.txt'
task :update_manifest do
  sh "find . -type f | sed -e 's%./%%' | egrep -v 'svn|swp|~' | egrep -v '^(doc|pkg)/' | sort > Manifest.txt"
end

desc 'Generate RDoc'
Rake::RDocTask.new :rdoc do |rd|
  rd.rdoc_dir = 'doc'
  rd.rdoc_files.add 'lib', 'README', 'LICENSE'
  rd.main = 'README'
  rd.options << '-d' if `which dot` =~ /\/dot/
  rd.options << '-t IMAPCleanse'
end

desc 'Upload RDoc to RubyForge'
task :upload => :rdoc do
  user = "#{ENV['USER']}@rubyforge.org"
  project = '/var/www/gforge-projects/seattlerb/IMAPCleanse'
  local_dir = 'doc'
  pub = Rake::SshDirPublisher.new user, project, local_dir
  pub.upload
end

desc 'Build Gem'
Rake::GemPackageTask.new spec do |pkg|
  pkg.need_tar = true
end

desc 'Clean up'
task :clean => [ :clobber_rdoc, :clobber_package ]

desc 'Clean up'
task :clobber => [ :clean ]

# vim: syntax=Ruby

