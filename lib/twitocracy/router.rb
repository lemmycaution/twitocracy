module Twitocracy
  module Router
  
    extend ActiveSupport::Concern
  
    module ClassMethods
    
      def routes
        @routes ||= {}
      end
    
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

      if env["REQUEST_PATH"] =~ /\/([a-zA-Z]+)\/([0-9]+)/
        path = "/#{$1}/:id"
        env["params"] = (env["params"] || {}).merge("id" => $2)
      elsif env["REQUEST_PATH"] =~ /\/([0-9]+)/
        path = "/:id"
        env["params"] = (env["params"] || {}).merge("id" => $1)  
      else
        path = env["REQUEST_PATH"]
      end

      sig = self.class.signature(env['REQUEST_METHOD'], path)
      block = self.class.routes[sig]

      
      
      catch :halt do |response|
        if block
          instance_exec(&block)
        else
          instance_exec do
            error 404
          end
        end
        response
      end

    end
  
  end
end