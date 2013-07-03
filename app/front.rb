module Front
  
  extend ActiveSupport::Concern
  
  included do
    
    # main page
    # GET /
    get "/" do
      render_view :index
    end  
  
    # tiwtter oauth leg 1,2
    # redirects user to twitter for signing-in
    # and saves request token on return
    # GET /connect
    get "/connect"  do  
      suid = generate_sid
      request_token = env.twitter_oauth.authentication_request_token(oauth_callback: "#{ENV['CALLBACK_URL']}"  )        
      session["token"] = "#{request_token.token}!!!#{request_token.secret}"
      redirect request_token.authorize_url(token: request_token.token)
    end
  
    # twitter oauth leg3
    # handles twitter oauth callback, verifies tokens
    # saves the user in session if everything is ok
    # GET /auth
    get "/auth" do
        
      if session["token"]
    
        token, secret = session["token"].split("!!!")

        access_token = env.twitter_oauth.authorize(
        token,
        secret,
        :oauth_verifier => env.params["oauth_verifier"]
        )

        if env.twitter_oauth.authorized?

          user = User.find_or_create_by(
          screenname: access_token.params[:screen_name]
          )
          user.update(token: access_token.params[:oauth_token],
          secret: access_token.params[:oauth_token_secret],
          suid: generate_sid)
        
          session["token"] = nil
          session["suid"] = user.suid

        end  
      end  

      redirect "/"
    end

    # sign-outs the current user & clean ups the session
    # GET /disconnect
    get "/disconnect" do
      authenticate_user!
      current_user.update(suid: nil)      
      session["suid"] = nil
      redirect "/"
    end
  
    # renders new proposal form
    # requires authenticated user
    # GET /new
    get "/new"  do
      authenticate_user!
      render_view :new
    end
  
    # renders single proposal
    # GET /1
    get "/:id" do
      render_view :show
    end
    
  end
  
end