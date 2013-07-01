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
        @model.on "change", @render, @
        @model.on "destroy", @remove, @                
        @render()        
      else
        @model = new Proposal(id: options.id)
        @model.on "change", @render, @
        @model.on "destroy", @remove, @        
        @model.fetch()
      
      @channel = app.pusher.subscribe("proposal-#{@model.get("id")}")
      @channel.bind 'update', (data) =>
        @model.set(data)
      @channel.bind 'destroy', (data) =>
        @remove()

    events: ->
      if @model.get("is_pool")
        events =
        "click .upvote"         :  "upvote"
        "click .downvote"       :  "downvote"  
        "click .un_upvote"      :  "un_upvote"
        "click .un_downvote"    :  "un_downvote"                
        "click .delete"         :  "delete"      
      else
        events =  
        "click .upvote"        :  "upvote"
        "click .un_upvote"     :  "un_upvote"        
        "click .delete"        :  "delete"        
            
    template: (data,options = {variable: "model"})->

      tmp = """
        <h2><a href="/<%= model.get('id') %>">“<%= model.get('subject') %>”</a>
        <br/>
        <small><a href="http://twitter.com/<%= model.get('owner') %>"><%= model.get('owner') %></a></small>
        </h2>
        <div class="clearfix">
            <span class="time"><%= model.remaining_time_to_human() %> remaining</span>                 
            <% if (model.get("is_pool")){ %>
            
            <% if (model.get("up_retweeted")) { %>
            <button class="un_upvote">Un-upvote! (<%= model.get('upvote_count') %>)</button>
            <% } else { %>
            <button class="upvote">Upvote! (<%= model.get('upvote_count') %>)</button>            
            <% } %>
            
            <% if (model.get("down_retweeted")) { %>
            <button class="un_downvote">Un-downvote! (<%= model.get('downvote_count') %>)</button>
            <% } else { %>
            <button class="downvote">Downvote! (<%= model.get('downvote_count') %>)</button>
            <% } %>
                          
            <% }else{ %>
            
            <% if (model.get("up_retweeted")) { %>
            <button class="un_upvote">Un-endorse! (<%= model.get('upvote_count') %>)</button>            
            <% } else { %>
            <button class="upvote">Endorse! (<%= model.get('upvote_count') %>)</button>            
            <% } %>
            
            <% } %>
            <% if(model.get("user_id") == $(".current_user").attr('id') ) { %>
            <small><button class="delete">Delete</button></small>             
            <% } %> 
        </div>               
        <p>–</p>
        """    
      _.template(tmp,data,options)
    
    render: () ->
      if @options.add is true
        $("ul.collection").append @$el.html(@template(@model))        
      else
        @$el.html @template(@model)        

      @    
      
    vote_hash: (vote) ->
      hash = {upvote: null, downvote: null, un_upvote: null, un_downvote: null}  
      hash[vote] = true
      hash
      
    do_vote: (e, vote) ->
      app.set_button_state e.currentTarget
      @model.save(@vote_hash(vote), {wait:true, patch: true, silent: true})
      @  
      
    upvote: (e) ->  
      @do_vote(e,"upvote")
      
    downvote: (e) ->  
      @do_vote(e,"downvote")
      
    un_upvote: (e) ->  
      @do_vote(e,"un_upvote")
      
    un_downvote: (e) ->  
      @do_vote(e,"un_downvote") 
      
    delete: (e) ->  
      app.set_button_state e.currentTarget
      @model.destroy
        wait: true
        success: (model) ->
          if window.location.pathname.match(/\/[0-9]+/) != null then window.location.href = "/"
      @            
  
  ProposalView  