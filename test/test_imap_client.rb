require 'rubygems'
require 'minitest/autorun'

$TESTING = true

require 'imap_client'

Net.send :remove_const, :IMAP

class Net::IMAP

  @capability = %w[AUTH=PLAIN]

  class << self
    attr_accessor :capability
  end

  attr_accessor :host, :port, :ssl

  def initialize(host, port, ssl)
    @host = host
    @port = port
    @ssl = ssl
    @selected = []
    @searches = []
    @capability = self.class.capability
    @boxes = %w[mail/Folder mail/One mail/Two mail/Three]
  end

  attr_accessor :auth, :username, :password

  def authenticate(auth, username, password)
    @auth = auth
    @username = username
    @password = password
  end

  attr_reader :capability

  attr_accessor :boxes

  def list(root, boxes)
    return @boxes if @boxes.nil?

    boxes = @boxes.each do |box|
      def box.attr; @attr ||= []; @attr; end
      def box.attr=(attr); @attr = attr; end
      def box.name; self; end
    end
    boxes.first.attr = [:Noselect]
    boxes
  end

  attr_accessor :selected

  def select(arg)
    @selected << arg
  end

  attr_accessor :searches

  def search(arg)
    @searches << arg
  end

  def store(arg1, arg2, arg3)
  end

end

class IMAPClient
  attr_accessor :verbose, :noop, :root, :box_re, :imap
end

class IMAPTest < IMAPClient

  def initialize options = {}
    @boxes = options[:Boxes]
    super
  end

  def find_messages
    search [ 'NOT', 'READ' ], 'finding messages'
  end

end

class TestImapClient < MiniTest::Unit::TestCase
  def setup
    @default_options = {
      :Root     => 'mail',
      :Boxes    => 'One,Two',
      :Verbose  => true,
      :Noop     => false,

      :Host     => 'localhost',
      :Port     => 993,
      :SSL      => true,

      :Auth     => 'PLAIN',
      :Username => 'nobody',
      :Password => 'password',
    }
  end

  def test_initialize
    client = nil

    _, err = capture_io do
      client = util_init
    end

    assert_equal true, client.verbose
    assert_equal false, client.noop
    assert_equal 'mail', client.root

    # HACK refute_nil client.box_re, client.inspect
    # HACK assert_equal '^mail/(?-mix:One|Two)', client.box_re.source

    assert_equal 'localhost', client.imap.host
    assert_equal 993, client.imap.port
    assert_equal true, client.imap.ssl

    assert_equal 'PLAIN', client.imap.auth
    assert_equal 'nobody', client.imap.username
    assert_equal 'password', client.imap.password


    err = err.scan(/.*\n/)

    assert_equal "# Connected to localhost:993\n", err.shift
    assert_equal "# Trying PLAIN authentication\n", err.shift
    assert_equal "# Logged in as nobody\n", err.shift
  end

  def test_initialize_empty_root
    client = nil
    capture_io do
      client = util_init :Root => ''
    end

    assert_equal '', client.root

    # HACK refute_nil client.box_re, client.inspect
    # HACK assert_equal '^(?-mix:One|Two)', client.box_re.source
  end

  def test_connect
    c = nil
    capture_io do
      c = IMAPTest.new @default_options
      c.connect 'mail', 993, true, 'user', 'p@ss'
    end
    assert_equal 'PLAIN', c.imap.auth
  end

  def test_connect_multi_auth
    old_capability       = Net::IMAP.capability
    Net::IMAP.capability = %w[AUTH=CRAM-MD5 AUTH=LOGIN]

    c = nil
    capture_io do
      c = IMAPTest.new @default_options
      c.connect 'mail', 993, true, 'user', 'p@ss'
    end
    assert_equal 'CRAM-MD5', c.imap.auth
  ensure
    Net::IMAP.capability = old_capability
  end

  def test_connect_with_auth
    c = nil
    capture_io do
      c = IMAPTest.new @default_options
      c.connect 'mail', 993, true, 'user', 'p@ss', 'LOGIN'
    end
    assert_equal 'LOGIN', c.imap.auth
  end

  def test_find_mailboxes_bad_root
    c = nil
    capture_io { c = util_init :Root => 'nosuchdir', :Verbose => true }

    c.imap.boxes = nil
    boxes = nil
    out, err = capture_io { boxes = c.find_mailboxes }

    assert_equal [], boxes
    assert_equal "# Found no mailboxes under \"nosuchdir\", you may have an incorrect root\n", err
  end

# HACK: :Boxes is never set, and never selected. I fixed the former by
# adding in initialize to IMAPTest, but I don't know how to fix the
# latter yet.
#
#   def test_run
#     client = nil
#     capture_io do
#       client = util_init
#       client.run 'test', ['test_flag']
#     end
#
#     assert_equal %w[mail/One mail/Two], client.imap.selected
#   end

  def util_init(options = {})
    options = @default_options.merge options
    IMAPTest.new options
  end
end

