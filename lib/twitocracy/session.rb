require 'rack/utils'

module Twitocracy
  class Session
    
    ENV_SESSION_KEY       = 'rack.session'
    SID                   = 'twitocracy.sid'
  
    include Goliath::Rack::SimpleAroundware
    
    def pre_process
      get_session
      ap "get session #{env[ENV_SESSION_KEY].inspect}"
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
      session_data = env[ENV_SESSION_KEY].delete_if{ |k, v| v.nil? }
      if session_data.empty?
        dalli.delete dalli_session_key
      else
        dalli.set dalli_session_key, Oj.dump( session_data )
      end
    end
    
    def dalli_session_key
      "sessions::#{session_key}"
    end
    
    def session_key
      cookie = ::Rack::Utils.parse_query(env["HTTP_COOKIE"])
      ap "cookie #{cookie.inspect}"
      cookie.present? ? cookie[SID] : BCrypt::Password.create(Time.now)      
    end

  end 
end