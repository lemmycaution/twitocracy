define [
  
  "jquery",
  "underscore",
  "backbone",
  "models/proposal"
  
], ($, _, Backbone, Proposal) ->
  
  "use strict"
  
  class ProposalView extends Backbone.View
    
    tagName: "li"
    
    initialize: (options) ->
      if options.model
        @model = options.model
        @model.bind "change", @render, @
        @model.bind "destroy", @remove, @                
        @render()        
      else
        @model = new Proposal(id: options.id)
        @model.bind "change", @render, @
        @model.bind "destroy", @remove, @        
        @model.fetch()
      
      @channel = app.pusher.subscribe("proposal-#{@model.get("id")}")
      @channel.bind 'update', (data) =>
        @model.set(data)
      @channel.bind 'destroy', (data) =>
        @remove()

    events:
      "click .upvote"         :  "upvote"
      "click .downvote"       :  "downvote"  
      "click .delete"         :  "delete"      

    template: (data,options = {variable: "model"})->

      tmp = """
        <h2><a href="/<%= model.get('id') %>">“<%= model.get('subject') %>”</a>
        <br/>
        <small><a href="http://twitter.com/<%= model.get('owner') %>"><%= model.get('owner') %></a></small>
        </h2>
        <div class="clearfix">
            <span class="time"><%= model.voting_time_to_human() %></span>                 
            <% if (model.get("is_pool")){ %>
            <button class="upvote">Yes<sup><%= model.get('upvote_count') %></sup> &#8593;</button>            
            <button class="downvote">No<sup><%= model.get('downvote_count') %></sup> &#8595;</button>
            <% }else{ %>
            <button class="upvote">Endorse<sup><%= model.get('upvote_count') %></sup> &#8593;</button>            
            <% } %>
            <% if(model.get("user_id") == $(".current_user").attr('id') ) { %>
            <small><button class="delete">Delete</button></small>             
            <% } %> 
        </div>               
        <i class="sep">&#10020;</i>
        """    
      _.template(tmp,data,options)
    
    render: () ->
      if @options.add is true
        $("ul.collection").append @$el.html(@template(@model))        
      else
        @$el.html @template(@model)        

      @    
      
    do_vote: (e, vote) ->
      app.set_button_state e.currentTarget
      @model.save {method: "#{vote}_by"}, {wait: true, patch: true, error: (model,xhr,sync) => @on_vote_error(e,model,xhr,sync)}
      @  
      
    upvote: (e) ->  
      @do_vote(e,"upvote")
      
    downvote: (e) ->  
      console.log e
      @do_vote(e,"downvote")
      
    delete: (e) ->  
      app.set_button_state e.currentTarget
      @model.destroy
        wait: true
        success: (model) ->
          if window.location.pathname.match(/\/[0-9]+/) != null then window.location.href = "/"
      @  
    
    on_vote_error: (e,model,xhr,sync) =>
      app.set_button_state e.currentTarget,false
      unless xhr.status is 422
        errors = JSON.parse(xhr.responseText)
        for error of errors
          alert(if error is "base" then errors[error] else "#{error} #{errors[error]}")
  
  ProposalView  