require 'rack/utils'

module Twitocracy
  class Session
    
    ENV_SESSION_KEY       = 'rack.session'
    ENV_SESSION_ID_KEY    = 'rack.session.id'
    SID                   = 'twitocracy.sid'
  
    include Goliath::Rack::SimpleAroundware
    
    def pre_process
      get_session
      Goliath::Connection::AsyncResponse
    end
  
    def post_process
      set_session
      # headers = (headers || {}).merge({'Set-Cookie' => ["#{SID}=#{session_key};"]})
      Rack::Utils.set_cookie_header!(headers, SID, {value: session_key, path: "/"})                          
      [status, headers, body]
    end
    
    private
    
    def config
      env["config"]
    end
    
    def dalli
      config[:dalli]
    end
    
    def get_session
      session = dalli.get(dalli_session_key)
      env[ENV_SESSION_KEY] = session ? Oj.load(session) : {}
    end
    
    def set_session
      dalli.set( 
      dalli_session_key, 
      Oj.dump( env[ENV_SESSION_KEY].delete_if{ |k, v| v.nil? } ) 
      )
    end
    
    def dalli_session_key
      "sessions::#{session_key}"
    end
    
    def session_key
      cookie = ::Rack::Utils.parse_query(env["HTTP_COOKIE"])
      env[ENV_SESSION_ID_KEY] = cookie.present? ? cookie[SID] : BCrypt::Password.create(Time.now)
    end

  end 
end