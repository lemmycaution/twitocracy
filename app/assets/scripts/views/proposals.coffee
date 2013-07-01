define [
  
  "jquery",
  "underscore",
  "backbone",
  "models/proposal",
  "collections/proposals",
  "views/proposal",
  "/scripts/vendor/jquery.insert_at.js"
  
], ($, _, Backbone, Proposal, Proposals, ProposalView) ->
  
  "use strict"
  
  class ProposalsView extends Backbone.View
    
    el: "ul.collection"
    
    initialize: (options) ->
      
      @collection = new Proposals
      @collection.on "add", @addProposal, @
      
      @collection.fetch
        data: _.compact(options.data)
        success: @renderPagination
          
      @channel = app.pusher.subscribe("proposals")      
      @channel.bind 'create', (data) =>
        @collection.add data, {at: 0}
        
      @
      
    addProposal: (proposal) ->
      view = new ProposalView(model: proposal)
      @$el.insertAt(@collection.indexOf(proposal),view.render().el)
    
    renderPagination: => 
      if @collection.pagination.total > 1     
        scope = ""      
        scope = "/scope/#{@options.data.scope}" if @options.data.scope
          
        template = """
        <ul class="pagination">
        <% for(var i = 1; i < total+1; i++) { %>
        <% if (i == page) { %>
        <li><a class="current"><%= i %></a></li>      
        <% } else { %>
        <li><a href="#{scope}/page/<%= i %>"><%= i %></a></li>            
        <% } %>  
        <% } %>  
        </ul>
        """
        $(_.template(template,@collection.pagination)).insertAfter @$el
      @
        
  ProposalsView  