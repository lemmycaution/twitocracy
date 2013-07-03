module Twitocracy
  
  module Helpers
  
    extend ActiveSupport::Concern
  
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
  
  end
end