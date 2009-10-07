require 'imap_client'

##
# IMAPCleanse removes old messages from your IMAP mailboxes so you don't have
# to!
#
# aka part one of my Plan for Total Email Domination.
#
# IMAPClient doesn't remove messages you haven't read nor messages you've
# flagged.  See also IMAPFlag for automatic flagging goodness!

class IMAPCleanse < IMAPClient

  ##
  # Creates a new IMAPCleanse from +options+.
  #
  # Options include:
  #   +:Age+:: Delete messages older than this many days ago
  #
  # and all options from IMAPClient

  def initialize(options)
    @cleanse = options[:cleanse]
    @boxes = @cleanse.keys
    super
  end

  ##
  # Removes read, unflagged messages from all selected mailboxes...

  def run
    super "Cleansing read, unflagged old messages",
          [:Deleted] do
      @imap.expunge
      log "Expunged deleted messages"
    end
  end

  private

  ##
  # Searches for read, unflagged messages older than :Age in the currently
  # selected mailbox (see Net::IMAP#select).

  def find_messages
    mailbox = @boxes.find { |box| @mailbox =~ /#{box}/ } # TODO: needs more work
    raise unless mailbox
    age = @cleanse[mailbox]
    before_date = (Time.now - 86400 * age).imapdate

    search [
      'NOT', 'NEW',
      'NOT', 'FLAGGED',
      'BEFORE', before_date
    ], 'read, unflagged messages'
  end

end

