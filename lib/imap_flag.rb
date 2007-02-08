require 'imap_client'

##
# Automatically flag your messages, yo!
#
# aka part two of my Plan for Total Email Domination.
#
# IMAPFlag flags messages you've responded to, messages you've written and
# messages in response to messages you've written.
#
# If you unflag a message IMAPFlag is smart and doesn't re-flag it.
#
# I chose these settings because I find these messages interesting but don't
# want to manually flag them.  Why should I do all the clicking when the
# computer can do it for me?

class IMAPFlag < IMAPClient

  ##
  # IMAP keyword for automatically flagged messages

  AUTO_FLAG_KEYWORD = 'IMAPFLAG_AUTO_FLAGGED'

  ##
  # Message-Id query

  MESSAGE_ID = 'HEADER.FIELDS (MESSAGE-ID)'

  ##
  # Handles processing of +args+.

  def self.process_args(args)
    extra_options = { }
    super args, extra_options
  end

  ##
  # Creates a new IMAPFlag from +options+.
  #
  # Options include:
  #   +:Email:: Email address used for sending email
  #
  # and all options from IMAPClient

  def initialize(options)
    @flag = options[:flag]
    @boxes = @flag.keys
    super
  end

  ##
  # Removes read, unflagged messages from all selected mailboxes...

  def run
    super "Flagging messages", [:Flagged, AUTO_FLAG_KEYWORD]
  end

  private

  ##
  # Searches for messages I answered and messages I wrote.

  def find_messages
    @box = @boxes.find { |box| @mailbox =~ /#{box}/ } # TODO: needs more work
    raise unless @box
    @email = @flag[@box]
    raise unless @email
    return [answered_in_curr, wrote_in_curr, responses_in_curr].flatten
  end

  ##
  # Answered messages in the selected mailbox.

  def answered_in_curr
    search [
      'ANSWERED',
      'NOT', 'FLAGGED',
      'NOT', 'KEYWORD', AUTO_FLAG_KEYWORD
    ], 'answered messages'
  end

  ##
  # Messages I wrote in the selected mailbox.

  def wrote_in_curr
    @email.map { |email|
      search [
              'FROM', email,
              'NOT', 'FLAGGED',
              'NOT', 'KEYWORD', AUTO_FLAG_KEYWORD
             ], "messages by #{email}"
    }
  end

  ##
  # Messages in response to messages I wrote in the selected mailbox.

  def responses_in_curr
    log "  Scanning for responses to messages I wrote"
    my_mail = @email.map { |email| @imap.search [ 'FROM', email ] }.flatten

    return [] if my_mail.empty?

    msg_ids = @imap.fetch my_mail, "BODY.PEEK[#{MESSAGE_ID}]"
    msg_ids.map! do |data|
      data.attr["BODY[#{MESSAGE_ID}]"].split(':', 2).last.strip
    end

    messages = msg_ids.map do |id|
      @imap.search([
        'HEADER', 'In-Reply-To', id,
        'NOT', 'FLAGGED',
        'NOT', 'KEYWORD', AUTO_FLAG_KEYWORD
      ])
    end

    messages.flatten!

    log "    Found #{messages.length} messages"

    return messages
  end

end

