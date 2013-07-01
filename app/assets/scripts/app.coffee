define [
  
  "jquery",
  "router"
  
], ($, Router) ->
  
  class App
    
    constructor: ()->
    
     window.app = @
     
     @router = new Router
     
     @loading_indicator = "&nbsp;&nbsp;&#10227;&nbsp;&nbsp;"
     
     # Pusher.log = (message) ->
     #   if (window.console && window.console.log) 
     #     window.console.log(message)

     @pusher = new Pusher('4fbe8880e77dc33c220e')
     
     @set_button_state = (el, loading = true) ->
       $el = $(el)
       if loading
         $el.data('text', $el.html())         
         $el.attr("disabled",true).html(@loading_indicator)
       else 
         $el.removeAttr("disabled").html($el.data("text"))
     
       # // Global Error Handler
   		$(document).ajaxError (event, jqXHR, ajaxSettings, thrownError) ->
   		  if jqXHR.status is 422
          alert("You need to sign in to complete this action")

       # // Global Ajax Event Handlers
       # $(document).ajaxStart () ->
       #   $("#indicator").show()
       # 
       # $(document).ajaxComplete () ->
       #   $("#indicator").hide()   
     
     Backbone.history.start pushState: true
     
     $("a.toggle").on "click", (e) ->
       e.preventDefault()
       $("nav#{e.currentTarget.id}").toggleClass("open")
       
  App