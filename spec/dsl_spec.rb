require 'spec_helper'
require 'capybara/dsl'

class TestClass
  include Capybara::DSL
end

Capybara::SpecHelper.run_specs TestClass.new, "DSL", :skip => [
  :js,
  :screenshot,
  :frames,
  :windows,
  :server
]

describe Capybara::DSL do
  after do
    Capybara.session_name = nil
    Capybara.default_driver = nil
    Capybara.javascript_driver = nil
    Capybara.use_default_driver
    Capybara.app = TestApp
  end

  describe '#default_driver' do
    it "should default to rack_test" do
      Capybara.default_driver.should == :rack_test
    end

    it "should be changeable" do
      Capybara.default_driver = :culerity
      Capybara.default_driver.should == :culerity
    end
  end

  describe '#current_driver' do
    it "should default to the default driver" do
      Capybara.current_driver.should == :rack_test
      Capybara.default_driver = :culerity
      Capybara.current_driver.should == :culerity
    end

    it "should be changeable" do
      Capybara.current_driver = :culerity
      Capybara.current_driver.should == :culerity
    end
  end

  describe '#javascript_driver' do
    it "should default to selenium" do
      Capybara.javascript_driver.should == :selenium
    end

    it "should be changeable" do
      Capybara.javascript_driver = :culerity
      Capybara.javascript_driver.should == :culerity
    end
  end

  describe '#use_default_driver' do
    it "should restore the default driver" do
      Capybara.current_driver = :culerity
      Capybara.use_default_driver
      Capybara.current_driver.should == :rack_test
    end
  end

  describe '#using_driver' do
    before do
      Capybara.current_driver.should_not == :selenium
    end

    it 'should set the driver using Capybara.current_driver=' do
      driver = nil
      Capybara.using_driver(:selenium) { driver = Capybara.current_driver }
      driver.should == :selenium
    end

    it 'should return the driver to default if it has not been changed' do
      Capybara.using_driver(:selenium) do
        Capybara.current_driver.should == :selenium
      end
      Capybara.current_driver.should == Capybara.default_driver
    end

    it 'should reset the driver even if an exception occurs' do
      driver_before_block = Capybara.current_driver
      begin
        Capybara.using_driver(:selenium) { raise "ohnoes!" }
      rescue Exception
      end
      Capybara.current_driver.should == driver_before_block
    end

    it 'should return the driver to what it was previously' do
      Capybara.current_driver = :selenium
      Capybara.using_driver(:culerity) do
        Capybara.using_driver(:rack_test) do
          Capybara.current_driver.should == :rack_test
        end
        Capybara.current_driver.should == :culerity
      end
      Capybara.current_driver.should == :selenium
    end

    it 'should yield the passed block' do
      called = false
      Capybara.using_driver(:selenium) { called = true }
      called.should == true
    end
  end

  describe '#using_wait_time' do
    before do
      @previous_wait_time = Capybara.default_wait_time
    end

    after do
      Capybara.default_wait_time = @previous_wait_time
    end

    it "should switch the wait time and switch it back" do
      in_block = nil
      Capybara.using_wait_time 6 do
        in_block = Capybara.default_wait_time
      end
      in_block.should == 6
      Capybara.default_wait_time.should == @previous_wait_time
    end

    it "should ensure wait time is reset" do
      expect do
        Capybara.using_wait_time 6 do
          raise "hell"
        end
      end.to raise_error
      Capybara.default_wait_time.should == @previous_wait_time
    end
  end

  describe '#app' do
    it "should be changeable" do
      Capybara.app = "foobar"
      Capybara.app.should == 'foobar'
    end
  end

  describe '#current_session' do
    it "should choose a session object of the current driver type" do
      Capybara.current_session.should be_a(Capybara::Session)
    end

    it "should use #app as the application" do
      Capybara.app = proc {}
      Capybara.current_session.app.should == Capybara.app
    end

    it "should change with the current driver" do
      Capybara.current_session.mode.should == :rack_test
      Capybara.current_driver = :selenium
      Capybara.current_session.mode.should == :selenium
    end

    it "should be persistent even across driver changes" do
      object_id = Capybara.current_session.object_id
      Capybara.current_session.object_id.should == object_id
      Capybara.current_driver = :selenium
      Capybara.current_session.mode.should == :selenium
      Capybara.current_session.object_id.should_not == object_id

      Capybara.current_driver = :rack_test
      Capybara.current_session.object_id.should == object_id
    end

    it "should change when changing application" do
      object_id = Capybara.current_session.object_id
      Capybara.current_session.object_id.should == object_id
      Capybara.app = proc {}
      Capybara.current_session.object_id.should_not == object_id
      Capybara.current_session.app.should == Capybara.app
    end

    it "should change when the session name changes" do
      object_id = Capybara.current_session.object_id
      Capybara.session_name = :administrator
      Capybara.session_name.should == :administrator
      Capybara.current_session.object_id.should_not == object_id
      Capybara.session_name = :default
      Capybara.session_name.should == :default
      Capybara.current_session.object_id.should == object_id
    end
  end

  describe "#using_session" do
    it "should change the session name for the duration of the block" do
      Capybara.session_name.should == :default
      Capybara.using_session(:administrator) do
        Capybara.session_name.should == :administrator
      end
      Capybara.session_name.should == :default
    end

    it "should reset the session to the default, even if an exception occurs" do
      begin
        Capybara.using_session(:raise) do
          raise
        end
      rescue Exception
      end
      Capybara.session_name.should == :default
    end

    it "should yield the passed block" do
      called = false
      Capybara.using_session(:administrator) { called = true }
      called.should == true
    end
  end

  describe "#session_name" do
    it "should default to :default" do
      Capybara.session_name.should == :default
    end
  end

  describe 'the DSL' do
    before do
      @session = Class.new { include Capybara::DSL }.new
    end

    it "should be possible to include it in another class" do
      @session.visit('/with_html')
      @session.click_link('ullamco')
      @session.body.should include('Another World')
    end

    it "should provide a 'page' shortcut for more expressive tests" do
      @session.page.visit('/with_html')
      @session.page.click_link('ullamco')
      @session.page.body.should include('Another World')
    end

    it "should provide an 'using_session' shortcut" do
      Capybara.should_receive(:using_session).with(:name)
      @session.using_session(:name)
    end

    it "should provide a 'using_wait_time' shortcut" do
      Capybara.should_receive(:using_wait_time).with(6)
      @session.using_wait_time(6)
    end
  end
end
