require 'goliath/rack/templates'
require 'lib/twitocracy/router'
require 'lib/twitocracy/session'
require "lib/twitocracy/updater"
require 'bcrypt'

class API < Goliath::API
  
  include Goliath::Rack::Templates
  include Twitocracy::Router 
  
  use Rack::Static,                     
  :root => Goliath::Application.root_path("public"),
  :urls => ["/favicon.ico", '/styles', '/scripts', '/images']
  # :cache_control => 'public, max-age=3600'
  use Goliath::Rack::Render
  use Goliath::Rack::DefaultMimeType
  use Goliath::Rack::Params  
  use Goliath::Rack::SimpleAroundwareFactory, Twitocracy::Session
  
  plugin Twitocracy::Updater
  
  get "/" do
    render_view :index
  end  
  
  get "/connect"  do  
    suid = generate_sid
    request_token = env.twitter_oauth.authentication_request_token(oauth_callback: "#{ENV['CALLBACK_URL']}"  )        
    session["token"] = "#{request_token.token}!!!#{request_token.secret}"
    redirect request_token.authorize_url(token: request_token.token)
  end
  
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

  get "/disconnect" do
    authenticate_user!
    current_user.update(suid: nil)      
    session["suid"] = nil
    redirect "/"
  end
  
  get "/new"  do
    authenticate_user!
    render_view :new
  end
  
  get "/:id" do
    render_view :show
  end

  # PROPOSALS
  
  # index
  get "/proposals" do
    proposals = Proposal.open
    proposals = proposals.public_send params["scope"] if params["scope"]
    
    page = (params["page"] || 1).to_i
    total_page = [(proposals.count.to_f / Proposal::DEFAULT_LIMIT.to_f).ceil,1].max
    ap total_page

    render_json({models: proposals.page(page), page: page, total_page: total_page})
  end
  
  # show
  get "/proposals/:id" do
    if proposal = Proposal.find_by(id: params["id"])
      render_json proposal
    else
      error 404
    end  
  end
  
  # create
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
      if params["upvote"]
        render_json proposal.upvote_by(current_user)
      elsif params["downvote"]
        render_json proposal.downvote_by(current_user)        
      elsif params["un_upvote"]  
        render_json proposal.un_upvote_by(current_user)                
      elsif params["un_downvote"]  
        render_json proposal.un_downvote_by(current_user)                        
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
  
  # def respond_with(data, options = {})
  #   if env['HTTP_ACCEPT'].include?("json")
  #     render_json data, options
  #   else
  #     render_view options.delete(:view), options.merge({data: data})  
  #   end    
  # end
  
  def render_view(view, options = {})
    throw :halt, [ options[:status] || 200, options[:headers] || {}, erb(view, {locals: options[:data]}) ]    
  end
  
  def render_json(data = {}, options = {})
    throw :halt, [options[:status] || 200, (options[:header] || {}).merge({'Content-Type' => 'application/json'}), data.to_json(user: current_user)]   
  end
  
  def redirect(location, options = {})
    throw :halt, [302, {'Location'=> location}, []]
  end

  def error(status)
    if env['HTTP_ACCEPT'].include?("json")
      throw :halt,[status, {'Content-Type' => 'application/json'}, ""]      
    else
      throw :halt,[status, {}, File.open(Goliath::Application.root_path("public/#{status}.html"))]      
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
