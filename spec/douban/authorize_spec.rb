require File.join(File.dirname(__FILE__), '/../spec_helper')

require 'douban/authorize'

module Douban
  describe Authorize do
    before(:each) do
      Authorize.debug = true
      @api_key = '042bc009d7d4a04d0c83401d877de0e7'
      @secret_key = 'a9bb2d7f8cc00110'
      @authorize = Authorize.new(@api_key, @secret_key)
    end

    context "helper" do
      context "url_encode" do
        it "should support integer" do
          @authorize.url_encode(1).should == "1"
        end
      end
    end

    context "when oauth login" do
      it "should return login url and request token" do
        @authorize.authorized?.should be_false
        @authorize.get_authorize_url.should =~ %r{^http://.*oauth_token=[0-9a-f]{32}&oauth_callback=.*$}
        @authorize.authorized?.should be_false
        @authorize.request_token.token.should =~ /[0-9a-f]{32}/
        @authorize.request_token.secret.should =~ /[0-9a-f]{16}/
      end
    end
    
    context "oauth verify" do
      before(:each) do
        @request_token = "a" * 32
        @request_secret = "b" * 16
        
        @access_token = "c"*32
        @access_secret = "d"*16
      end
      
      it "should support set request token" do
        @authorize.request_token = OAuth::Token.new(@request_token, @request_secret)
        @authorize.request_token.kind_of?(OAuth::RequestToken).should == true
      end
      
      it "auth should works" do
        request_token_mock = mock("request_token")
        request_token_mock.stub!(:kind_of?).with(OAuth::RequestToken).and_return(true)
        request_token_mock.stub!(:get_access_token).and_return(
          OAuth::Token.new(@access_token, @access_secret)
        )
        
        @authorize.request_token = request_token_mock
        @authorize.auth
        @authorize.access_token.class.should == OAuth::AccessToken
        @authorize.access_token.token.should == @access_token
        @authorize.access_token.secret.should == @access_secret
      end
    end
    
  context "logged in with oauth" do
    before(:each) do
      Authorize.debug = true
      @access_token = '0306646daca492b609132d4905edb822'
      @access_secret = '22070cec426cb925'
      @authorize.access_token = OAuth::Token.new(@access_token, @access_secret)
    end
      
    
    it "should authorized?" do
      @authorize.authorized?.should == true
    end

    it "get_people should works" do
      people = @authorize.get_people
      people.nil?.should == false
      people.uid.should == "41502874"
    end

    context "miniblog" do
      it "should publish miniblog with html characters and return Miniblog" do
        miniblog = @authorize.create_miniblog("<b>单元测试#{rand}")
        miniblog.kind_of?(Douban::Miniblog).should == true
      end

      it "delete miniblog should works" do
        miniblog = @authorize.create_miniblog("<b>单元测试#{rand}")
        miniblog.kind_of?(Douban::Miniblog).should == true
        id = %r{http://api.douban.com/miniblog/(\d+)}.match(miniblog.id)[1]
        @authorize.delete_miniblog(id).should == true
      end
    end
    
    context "recommendation" do
      context "get_recommendation" do
        it "should work" do
          recommendation = @authorize.get_recommendation(28732532)
          recommendation.class.should == Douban::Recommendation
          recommendation.title.should == "推荐小组话题：理证：试论阿赖耶识存在之必然性"
        end
      end
      context "get_user_recommendations" do
        it "should work" do
          recommendations = @authorize.get_user_recommendations("aka")
          recommendations.size.should == 10
          recommendations[0].class.should == Douban::Recommendation
          recommendations[0].id.should_not == recommendations[-1].id
        end
      end
      context "get_recommendation_comments" do
        it "should work" do
          recommendations = @authorize.get_recommendation_comments(4312524)
          recommendations.size.should >= 2
          recommendations[0].class.should == Douban::RecommendationComment
          recommendations[0].id.should_not == recommendations[-1].id
        end
      end
      context "create_recommendation & delete_recommendation" do
        it "should return a Recommendation and can be delete" do
          recommendation = @authorize.create_recommendation("http://api.douban.com/movie/subject/1424406", "标题", "神作")
          recommendation.class.should == Douban::Recommendation
          recommendation.comment.should == "神作"
          @authorize.delete_recommendation(recommendation).should == true
        end
        it "should can delete through recommendation_id" do
          @authorize.delete_recommendation(
              @authorize.create_recommendation("http://api.douban.com/movie/subject/1424406", "标题", "神作").recommendation_id).should == true
        end
      end

      context "create_recommendation_comment & delete_recommendation_comment" do
        it "should return a RecommendationComment and can be delete" do
          comment = @authorize.create_recommendation_comment(28732532, "好文")
          comment.class.should == Douban::RecommendationComment
          comment.content.should == "好文"
          @authorize.delete_recommendation_comment(comment).should == true
        end
        it "should can be delete through recommendation and comment_id" do
          comment = @authorize.create_recommendation_comment(28732532, "好文")
          @authorize.delete_recommendation_comment(@authorize.get_recommendation(28732532), comment.comment_id).should == true
        end
          it "should can be delete through recommendation_id and comment_id" do
            comment = @authorize.create_recommendation_comment(28732532, "好文")
            @authorize.delete_recommendation_comment(28732532, comment.comment_id).should == true
          end
        end
      end

      context "collection" do
        context "create_collection" do
          it "should return Collection" do
            @authorize.create_collection("http://api.douban.com/movie/subject/1424406", "a", 5, "watched", ["tag"]).class.should == Douban::Collection
          end
        end
      end

      context "event" do
        context "create_event" do
          it "should return Event" do
            event = @authorize.create_event("a", "b", "大山子798艺术区 IT馆")
            event.class.should == Douban::Event
          end
        end
      end

      context "mail" do
        context "get_mail_inbox" do
          it "should works" do
            @mails = @authorize.get_mail_inbox
            @mails.size.should >= 2
            @mails[0].id.should_not == @mails[-1].id
          end
        end

        context "create_mail" do
          it "should return captcha_token in the first time" do
            mail = @authorize.create_mail("lidaobing", "hello", "world")
            if mail.class != Hash
              mail.class.should == true
            end
          end
        end

        context "get_mail" do
          it "should work" do
            mail = @authorize.get_mail(82937520)
            mail.class.should == Mail
          end
        end
      end
    end
  end
end
