module Twitocracy
  
  # Simple dsl implementation for easy routing
  # based on helmet framework's api
  # https://github.com/tlewin/helmet
  
  module Router
  
    extend ActiveSupport::Concern
  
    module ClassMethods
    
      def routes
        @routes ||= {}
      end
    
      # ex usage;
      # get "/" do
      #  respond [200,{},"hello dsl"]
      # end
      def get(route, &block) 
        register_route('GET', route, &block);
        register_route('HEAD', route, &block);
      end
      def post(route, &block) register_route('POST', route, &block); end
      def put(route, &block) register_route('PUT', route, &block); end
      def patch(route, &block) register_route('PATCH', route, &block); end      
      def delete(route, &block) register_route('DELETE', route, &block); end
      def head(route, &block) register_route('HEAD', route, &block); end

      def register_route(method, route, &block)
        sig = self.signature(method, route)
        self.routes[sig] = block
      end
    
      def signature(method, route)
        "#{method}#{route}"
      end
    
    end
  
    def response(env)
      
      # little test for handling routes with scope and page
      # ex:
      # /scope/up/page/1
      # /page/1
      # /scope/closed 
      # better, smarter implementations welcome
      matches = env["REQUEST_PATH"].scan(/\/(scope|page)\/([a-zA-z0-9]+)/)
      if matches.any?
        path = "/"
        if matches[0][0] == "scope"
          params = {"scope" => matches[0][1]}
          params["page"] = matches[1][0] if matches.length > 1
        elsif matches[0][0] == "page"  
          params = {"page" => matches[0][1]}          
          params["scope"] = matches[1][0] if matches.length > 1          
        end
        env["params"] = (env["params"] || {}).merge(params)  
        
      # another test for route param :id
      # ex:
      # /proposals/1
      # /users/1
      elsif env["REQUEST_PATH"] =~ /\/([a-zA-Z]+)\/([0-9]+)/
        path = "/#{$1}/:id"
        env["params"] = (env["params"] || {}).merge("id" => $2)
      
      # and for /:id  
      elsif env["REQUEST_PATH"] =~ /\/([0-9]+)/
        path = "/:id"
        env["params"] = (env["params"] || {}).merge("id" => $1)  
      
      # handle rest as requested
      else
        path = env["REQUEST_PATH"]
      end

      # match route by parsed request
      sig = self.class.signature(env['REQUEST_METHOD'], path)
      block = self.class.routes[sig]

      # every
      catch :halt do |response|
        
        # run if there is a api for it
        if block
          instance_exec(&block)
          
        # 404 otherwise 
        else
          instance_exec do
            error 404
          end
        end
        
        # send response
        response
      end

    end
    
    def respond(response)
      throw :halt, response
    end
  
  end
end