require 'goliath/rack/templates'
require 'lib/twitocracy/router'
require 'lib/twitocracy/session'
require "lib/twitocracy/updater"
require 'bcrypt'

class API < Goliath::API
  
  # to rendering erb templates
  include Goliath::Rack::Templates
  
  # easy routing for goliath
  include Twitocracy::Router 
  
  use Rack::Static,                     
  :root => Goliath::Application.root_path("public"),
  :urls => ["/favicon.ico", '/styles', '/scripts', '/images'],
  :cache_control => 'public, max-age=3600'
  use Goliath::Rack::Render
  use Goliath::Rack::DefaultMimeType
  use Goliath::Rack::Params  
  
  # bloody sessions
  use Goliath::Rack::SimpleAroundwareFactory, Twitocracy::Session
  
  # periodic worker to update reweet(vote) counts
  plugin Twitocracy::Updater
  
  # FRONT-END API
  
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

  # BACK-END API
  
  # index
  # returns json representation of latest proposals with given page (default 1)
  # valid parameters are page and scope
  # look Proposal model for all scopes
  # GET /proposals(?page=1, optional)(&scope=closed, optional)
  get "/proposals" do
    proposals = Proposal.all
    proposals = proposals.public_send params["scope"] || :open
    
    page = (params["page"] || 1).to_i
    total_page = [(proposals.count.to_f / Proposal::DEFAULT_LIMIT.to_f).ceil,1].max

    render_json({models: proposals.page(page), page: page, total_page: total_page})
  end
  
  # show
  # returns json representation of proposal with given id
  # GET /proposals/1
  get "/proposals/:id" do
    if proposal = Proposal.find_by(id: params["id"])
      render_json proposal
    else
      error 404
    end  
  end
  
  # create
  # creates a new proposal
  # accepts x-url-form-encoded post parameters
  # POST /proposals  
  post "/proposals" do
    authenticate_user!
    proposal = current_user.proposals.new(params)
    if proposal.save
      render_json proposal, status: 201
    else
      render_json proposal.errors, status: 406
    end
  end
  
  # update (up and down vote only)
  patch "/proposals/:id" do
    authenticate_user!
    if proposal = Proposal.open.find_by(id: params["id"])
      if proposal.respond_to?(params["method"])
        ap current_user.screenname
        if proposal.send(params["method"],current_user)
          render_json proposal
        else
          render_json proposal.errors, status: 406
        end
      else
        error 405
      end
    else
      error 404
    end
  end
  
  # delete
  delete "/proposals/:id" do
    authenticate_user!
    if proposal = Proposal.find_by(id: params["id"].to_i)
      if proposal.user.eql? current_user
        render_json proposal.destroy
      else
        error 422
      end
    else
      error 404
    end
  end
  
  # HELPERS
  
  private
  
  def render_view(view, options = {})
    respond [ options[:status] || 200, options[:headers] || {'Content-Type' => 'text/html'}, erb(view, {locals: options[:data]}) ]    
  end
  
  def render_json(data = {}, options = {})
    respond [options[:status] || 200, (options[:header] || {}).merge({'Content-Type' => 'application/json'}), data.to_json]   
  end
  
  def redirect(location, options = {})
    respond [302, {'Location'=> location}, []]
  end

  def error(status)
    if env['HTTP_ACCEPT'].include?("json")
      respond [status, {'Content-Type' => 'application/json'}, ""]      
    else
      respond [status, {}, File.open(Goliath::Application.root_path("public/#{status}.html"))]      
    end
  end

  def authenticate_user!
    error(422) unless current_user
  end

  def current_user
    User.online.find_by(suid: session["suid"])
  end

  def generate_sid(salt = Time.now)
    ::BCrypt::Password.create(salt)    
  end

  def session
    env[Twitocracy::Session::ENV_SESSION_KEY] || {}
  end
  
end
