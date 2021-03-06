require 'helper'

class TestMessages < Test::Unit::TestCase

  context "parsing an order message" do
    setup do
      @str = "O|1|8780||^^^ATA|R|||||||||||||||||||B0135"
      @message = LIS::Message::Base.from_string(@str)
    end

    should "have correct type" do
      assert_equal LIS::Message::Order, @message.class
      assert_equal "O", @message.type_id
    end

    should "have correct speciment id" do
      assert_equal "8780", @message.specimen_id
    end

    should "return message itself on #to_message" do
      assert_equal @str, @message.to_message
    end
  end

  context "parsing a comment message" do
    setup do
      @str = "C|1|BAD_QC|"
      @message = LIS::Message::Base.from_string(@str)
    end

    should "create a comment message" do
      assert_equal LIS::Message::Comment, @message.class
    end
  end

  context "parsing a result message" do
    setup do
      @str = "R|1|^^^TSH|0.902|mIU/L|0.400\\0.004^4.00\\75.0|N|N|R|||20100115105636|20100115120641|B0135"
      @message = LIS::Message::Base.from_string(@str)
    end

    should "have correct type" do
      assert_equal LIS::Message::Result, @message.class
      assert_equal "R", @message.type_id
    end

    should "have correct timestamp" do
      assert_equal "2010-01-15T10:56:36+00:00", @message.test_started_at.to_s
    end

    should "have correct test id" do
      assert_equal "TSH", @message.universal_test_id
    end

    should "have correct value" do
      assert_equal "0.902", @message.result_value
    end

    should "have currect value and unit" do
      assert_equal "mIU/L", @message.unit
    end

    should "return message itself on #to_message" do
      assert_equal @str, @message.to_message
    end

    should "parse empty result messages without error" do
      @message = LIS::Message::Base.from_string("R|1|^^^||||||X|||||LIAISON")
      assert_equal LIS::Message::Result, @message.class
    end
  end

end
