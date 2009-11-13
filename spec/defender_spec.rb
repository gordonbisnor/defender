require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "Defender" do
  before(:each) do
    @defender = Defender.new(:api_key => "validkey", :owner_url => "validurl")
  end

  it "should raise a StandardError if a method fails" do
    lambda do
      Defender.raise_if_error({
        "status" => "fail",
        "message" => "Failed!"
       })
    end.should raise_error(StandardError, "Failed!")
  end
  
  it "should return the correct URL for any given action" do
    @defender.instance_eval do
      url("foobar")
    end.should == "http://api.defensio.com/blog/#{Defender::API_VERSION}/foobar/validkey.yaml"
  end
  
  it "should correctly identify a valid API key" do
    @defender.stubs(:call_action).with("validate-key").returns(
      {"status" => "success", "message" => ""}
    )
    @defender.valid_key?.should be_true
  end
  
  it "should correctly identify an invalid API key" do
    @defender.stubs(:call_action).with("validate-key").returns(
      {"status" => "fail", "message" => "Invalid key"}
    )
    @defender.valid_key?.should be_false
  end
  
  it "should correctly identify a spammy comment" do
    @defender.
      stubs(:call_action).
      with('audit-comment', {
        "user-ip" => "127.0.0.1",
        "article-date" => Time.now.strftime("%Y/%m/%d"),
        "comment-author" => "Henrik Hodne",
        "comment-type" => "comment",
        "test-force" => "spam,0.5000",
      }).
      returns(
      {"signature" => "abc123", "spam" => true, "spaminess" => 0.5}
    )
    @defender.audit_comment(
      :user_ip => "127.0.0.1",
      :article_date => Time.now,
      :comment_author => "Henrik Hodne",
      :comment_type => "comment",
      :test_force => "spam,0.5000"
    ).spam?.should be_true
  end
  
  it "should correctly identify a meaty comment" do
    @defender.
      stubs(:call_action).
      with('audit-comment', {
        "user-ip" => "127.0.0.1",
        "article-date" => Time.now.strftime("%Y/%m/%d"),
        "comment-author" => "Henrik Hodne",
        "comment-type" => "comment",
        "test-force" => "ham,0.1000",
      }).
      returns(
      {"signature" => "abc123", "spam" => false, "spaminess" => 0.1}
    )
    @defender.audit_comment(
      :user_ip => "127.0.0.1",
      :article_date => Time.now,
      :comment_author => "Henrik Hodne",
      :comment_type => "comment",
      :test_force => "ham,0.1000"
    ).spam?.should be_false
  end
  
  it "should correctly set the spaminess" do
    @defender.
      stubs(:call_action).
      with('audit-comment', {
        "user-ip" => "127.0.0.1",
        "article-date" => Time.now.strftime("%Y/%m/%d"),
        "comment-author" => "Henrik Hodne",
        "comment-type" => "comment",
        "test-force" => "spam,0.5000",
      }).
      returns(
      {"signature" => "abc123", "spam" => true, "spaminess" => 0.5}
    )
    @defender.audit_comment(
      :user_ip => "127.0.0.1",
      :article_date => Time.now,
      :comment_author => "Henrik Hodne",
      :comment_type => "comment",
      :test_force => "spam,0.5000"
    ).spaminess.should == 0.5
  end
  
  it "should change IPv6-style IPv4 adresses to IPv4 adresses" do
    @defender.
      stubs(:call_action).
      with('audit-comment', {
        "user-ip" => "127.0.0.1",
        "article-date" => Time.now.strftime("%Y/%m/%d"),
        "comment-author" => "Henrik Hodne",
        "comment-type" => "comment",
        "test-force" => "spam,0.5000",
      }).
      returns(
      {"signature" => "abc123", "spam" => true, "spaminess" => 0.5}
    )
    
    @defender.audit_comment(
      :user_ip => "::ffff:127.0.0.1",
      :article_date => Time.now,
      :comment_author => "Henrik Hodne",
      :comment_type => "comment",
      :test_force => "spam,0.5000"
    ).spaminess.should == 0.5
  end
  
  it "should fail without valid API credentials" do
    @defender.
      stubs(:call_action).
      with('audit-comment', {
        "user-ip" => "127.0.0.1",
        "article-date" => Time.now.strftime("%Y/%m/%d"),
        "comment-author" => "Henrik Hodne",
        "comment-type" => "comment",
        "test-force" => "ham,0.1000",
      }).
      raises(StandardError)
    lambda {
      d.audit_comment(
        :user_ip => "127.0.0.1",
        :article_date => Time.now,
        :comment_author => "Henrik Hodne",
        :comment_type => "comment",
        :test_force => "ham,0.1000"
      )
    }.should raise_error(StandardError)
  end
  
  it "should correctly call the report-false-positives action with one signature given" do
    @defender.
      stubs(:call_action).
      with('report-false-positives', {
        "signatures" => "1"
      }).
      returns(true)
    @defender.report_false_positives(1).should == true
  end
  
  it "should correctly call the report-false-positives action with one signature given (array)" do
    @defender.
      stubs(:call_action).
      with('report-false-positives', {
        "signatures" => "1"
      }).
      returns(true)
    @defender.report_false_positives([1]).should == true
  end
  
  it "should correctly call the report-false-positives action with multiple signature given" do
    @defender.
      stubs(:call_action).
      with('report-false-positives', {
        "signatures" => "1,2,3"
      }).
      returns(true)
    @defender.report_false_positives([1,2,3]).should == true
  end

  it "should correctly call the report-false-negatives action with one signature given" do
    @defender.
      stubs(:call_action).
      with('report-false-negatives', {
        "signatures" => "1"
      }).
      returns(true)
    @defender.report_false_negatives(1).should == true
  end
  
  it "should correctly call the report-false-negatives action with one signature given (array)" do
    @defender.
      stubs(:call_action).
      with('report-false-negatives', {
        "signatures" => "1"
      }).
      returns(true)
    @defender.report_false_negatives([1]).should == true
  end
  
  it "should correctly call the report-false-negatives action with multiple signature given" do
    @defender.
      stubs(:call_action).
      with('report-false-negatives', {
        "signatures" => "1,2,3"
      }).
      returns(true)
    @defender.report_false_negatives([1,2,3])
  end
end
