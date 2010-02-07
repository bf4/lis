
module LIS::Transfer

  # splits a stream into immulite packets and only lets packets through
  # that are inside a session delimited by ENQ .. EOT
  #
  # check the checksum and do acknowledgement of messages
  #
  # forwards the following events:
  #
  # - :message, String :: when a message is received
  # - :idle            :: when a transmission is finished (after EOT is received)
  #
  class PacketizedProtocol < Base
    ACK = "\006"
    NAK = "\025"
    ENQ = "\005"
    EOT = "\004"

    RX = /(?:
          \005 | # ENQ - start a transaction
          \004 | # EOT - ends a transaction
          (?:\002 (.*?) \015 \003 (.+?) \015 \012)) # a message with a checksum
        /xm

    def initialize(*args)
      super(*args)
      @memo = ""
      @inside_transmission = false
    end

    def receive(data)
      scanner = StringScanner.new(@memo + data)
      while match = scanner.scan(RX)
        case match
          when ENQ then transmission_start
          when EOT then transmission_end
        else
          received_message(match)
          write ACK
        end
      end
      @memo = scanner.rest
      nil
    end


    private

    def self.message_from_string(string)
      match = string.match(RX)
      data = match[1]
      checksum = match[2]

      expected_checksum = data.to_enum(:each_byte).inject(16) { |a,b| (a+b) % 0x100 }
      actual_checksum   = checksum.to_i(16)

      raise "checksum mismatch" unless expected_checksum == actual_checksum
      return data
    end

    def received_message(message)
      return false unless @inside_transmission
      forward(:message, self.class.message_from_string(message))
    end

    def transmission_start
      return false if @inside_transmission
      write ACK
      forward :begin
      @inside_transmission = true
      true
    end

    def transmission_end
      return false unless @inside_transmission
      forward :idle
      @inside_transmission = false
      true
    end
  end

end