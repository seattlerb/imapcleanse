$TESTING = false unless defined? $TESTING
require 'net/imap'
require 'yaml'
require 'imap_sasl_plain'
require 'optparse'
require 'enumerator'

##
# An IMAPClient used by IMAPFlag and IMAPCleanse.
#
# Probably not very reusable by you, but it has lots of example code.
#
# Reference:
#
#     email: http://www.ietf.org/rfc/rfc0822.txt
#      imap: http://www.ietf.org/rfc/rfc3501.txt

class IMAPClient

  ##
  # This is the version of IMAPClient you are using.

  VERSION = '1.3.0'

  ##
  # Handles processing of +args+.

  def self.process_args(args, extra_options = {})
    opts_file = File.expand_path '~/.imap_cleanse'
    options = {}

    if File.exist? opts_file then
      unless File.stat(opts_file).mode & 077 == 0 then
        $stderr.puts "WARNING! #{opts_file} is group/other readable or writable!"
        $stderr.puts "WARNING! I'm not doing a thing until you fix it!"
        exit 1
      end

      options.merge! YAML.load(File.read(opts_file))
    end

    options[:SSL]      ||= true
    options[:Username] ||= ENV['USER']
    options[:Root]     ||= 'mail'
    options[:Noop]     ||= false
    options[:Verbose]  ||= false

    extra_options.each do |k,(v,m)|
      options[k]       ||= v
    end

    opts = OptionParser.new do |opts|
      opts.banner = "Usage: #{File.basename $0} [options]"
      opts.separator ''
      opts.separator 'Options may also be set in the options file ~/.imap_cleanse.'
      opts.separator ''
      opts.separator 'Example ~/.imap_cleanse:'
      opts.separator "\tHost=mail.example.com"
      opts.separator "\tPassword=my password"

      opts.separator ''
      opts.separator 'Connection options:'

      opts.on("-H", "--host HOST",
              "IMAP server host",
              "Default: #{options[:Host].inspect}",
              "Options file name: Host") do |host|
        options[:Host] = host
      end

      opts.on("-P", "--port PORT",
              "IMAP server port",
              "Default: The correct port SSL/non-SSL mode",
              "Options file name: Port") do |port|
        options[:Port] = port
      end

      opts.on("-s", "--[no-]ssl",
              "Use SSL for IMAP connection",
              "Default: #{options[:SSL].inspect}",
              "Options file name: SSL") do |ssl|
        options[:SSL] = ssl
      end

      opts.separator ''
      opts.separator 'Login options:'

      opts.on("-u", "--username USERNAME",
              "IMAP username",
              "Default: #{options[:Username].inspect}",
              "Options file name: Username") do |username|
        options[:Username] = username
      end

      opts.on("-p", "--password PASSWORD",
              "IMAP password",
              "Default: Read from ~/.imap_cleanse",
              "Options file name: Password") do |password|
        options[:Password] = password
      end

      authenticators = Net::IMAP.send :class_variable_get, :@@authenticators
      auth_types = authenticators.keys.sort.join ', '
      opts.on("-a", "--auth AUTH",
              "IMAP authentication type override",
              "Authentication type will be auto-",
              "discovered",
              "Default: #{options[:Auth].inspect}",
              "Valid values: #{auth_types}",
              "Options file name: Auth") do |auth|
        options[:Auth] = auth
      end

      opts.separator ''
      opts.separator "#{self} options:"

      opts.on("-r", "--root ROOT",
              "Root of mailbox hierarchy",
              "Default: #{options[:Root].inspect}",
              "Options file name: Root") do |root|
        options[:Root] = root
      end

      opts.on("-b", "--boxes BOXES",
              "Comma-separated list of mailbox name",
              "prefixes to search",
              "Default: #{options[:Boxes].inspect}",
              "Options file name: Boxes") do |boxes|
        options[:Boxes] = boxes
      end

      yield opts, options if block_given?

      opts.on("-n", "--noop",
              "Perform no destructive operations",
              "Best used with the verbose option",
              "Default: #{options[:Noop].inspect}",
              "Options file name: Noop") do |noop|
        options[:Noop] = noop
      end

      opts.on("-v", "--[no-]verbose",
              "Be verbose",
              "Default: #{options[:Verbose].inspect}",
              "Options file name: Verbose") do |verbose|
        options[:Verbose] = verbose
      end

      opts.separator ''

      opts.on("-h", "--help",
              "You're looking at it") do
        $stderr.puts opts
        exit 1
      end

      opts.separator ''
    end

    opts.parse! args

    options[:Port] ||= options[:SSL] ? 993 : 143

    if options[:Host].nil? or
       options[:Password].nil? or
       extra_options.any? { |k,v| options[k].nil? } then
      $stderr.puts opts
      $stderr.puts
      $stderr.puts "Host name not set"     if options[:Host].nil?
      $stderr.puts "Password not set"      if options[:Password].nil?
      extra_options.each do |k,(v,msg)|
        $stderr.puts msg if options[k].nil?
      end
      exit 1
    end

    return options
  end

  ##
  # Sets up an IMAPClient options then runs.

  def self.run(args = ARGV)
    options = process_args args
    client = new options
    client.run
  rescue => e
    $stderr.puts "Failed to finish with exception: #{e.class}:#{e.message}"
    $stderr.puts "\t#{e.backtrace.join "\n\t"}"
    exit 1
  end

  ##
  # Creates a new IMAPClient from +options+.
  #
  # Options include:
  #   +:Verbose+:: Verbose flag
  #   +:Noop+:: Don't delete anything flag
  #   +:Root+:: IMAP root path
  #   +:Boxes+:: Comma-separated list of mailbox prefixes to search
  #   +:Host+:: IMAP server
  #   +:Port+:: IMAP server port
  #   +:SSL+:: SSL flag
  #   +:Username+:: IMAP username
  #   +:Password+:: IMAP password
  #   +:Auth+:: IMAP authentication type

  def initialize(options)
    @verbose = options[:Verbose]
    @noop    = options[:Noop]
    @root    = options[:Root]

    root = @root
    root += "/" unless root.empty?

    connect options[:Host], options[:Port], options[:SSL],
            options[:Username], options[:Password], options[:Auth]
  end

  ##
  # Selects messages from mailboxes then marking them with +flags+.  If a
  # block is given it is run after message marking.
  # 
  # Unless :Noop was set, then it just prints out what it would do.
  #
  # Automatically called by IMAPClient::run

  def run(message, flags)
    log message

    message_count = 0
    mailboxes = find_mailboxes

    mailboxes.each do |mailbox|
      @mailbox = mailbox
      @imap.select @mailbox
      log "Selected #{@mailbox}"

      messages = find_messages

      next if messages.empty?

      message_count += messages.length

      unless @noop then
        mark messages, flags
      else
        log "Noop - not marking"
      end

      yield messages if block_given?
    end

    log "Done. Found #{message_count} messages in #{mailboxes.length} mailboxes"
  end

  private unless $TESTING

  ##
  # Connects to IMAP server +host+ at +port+ using ssl if +ssl+ is true then
  # logs in as +username+ with +password+.  IMAPClient will really only work
  # with PLAIN auth on SSL sockets, sorry.

  def connect(host, port, ssl, username, password, auth = nil)
    @imap = Net::IMAP.new host, port, ssl
    log "Connected to #{host}:#{port}"

    if auth.nil? then
      auth_caps = @imap.capability.select { |c| c =~ /^AUTH/ }
      raise "Couldn't find a supported auth type" if auth_caps.empty?
      auth = auth_caps.first.sub(/AUTH=/, '')
    end

    auth = auth.upcase
    log "Trying #{auth} authentication"
    @imap.authenticate auth, username, password
    log "Logged in as #{username}"
  end

  ##
  # Finds mailboxes with messages that were selected by the :Boxes option.

  def find_mailboxes
    mailboxes = @imap.list(@root, "*")

    if mailboxes.nil? then
      log "Found no mailboxes under #{@root.inspect}, you may have an incorrect root"
      return []
    end

    mailboxes.reject! { |mailbox| mailbox.attr.include? :Noselect }
    mailboxes.map! { |mailbox| mailbox.name }

    @box_re = /^#{Regexp.escape @root}#{Regexp.union(*@boxes)}/

    mailboxes.reject! { |mailbox| mailbox !~ @box_re }
    mailboxes = mailboxes.sort_by { |m| m.downcase }
    log "Found #{mailboxes.length} mailboxes to search:"
    mailboxes.each { |mailbox| log "\t#{mailbox}" } if @verbose
    return mailboxes
  end

  ##
  # Logs +message+ to $stderr if :Verbose was selected.

  def log(message)
    return unless @verbose
    $stderr.puts "# #{message}"
  end

  ##
  # Searches for messages matching +query+ in the selected mailbox
  # (see Net::IMAP#select).  Logs 'Scanning for +message+' before searching.

  def search(query, message)
    log "  Scanning for #{message}"
    messages = @imap.search query
    log "    Found #{messages.length} messages"
    return messages
  end

  ##
  # Marks +messages+ in the currently selected mailbox with +flags+
  # (see Net::IMAP#store).

  def mark(messages, flags)
    messages.each_slice(500) do |chunk|
      @imap.store chunk, '+FLAGS.SILENT', flags
    end
    log "Marked messages with flags"
  end
end
