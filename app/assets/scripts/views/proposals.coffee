define [
  
  "jquery",
  "underscore",
  "backbone",
  "collections/proposals",
  "views/proposal"
  
], ($, _, Backbone, Proposals, ProposalView) ->
  
  "use strict"
  
  class ProposalsView extends Backbone.View
    
    el: "ul.collection"
    
    initialize: (options) ->
      @collection = new Proposals
      @collection.on "reset",   @render, @
      @collection.on "add",     @addProposal, @
      @collection.fetch()
      
      @channel = app.pusher.subscribe("proposals")      
      @channel.bind 'create', (data) =>
        @collection.add data
      @
    
    render: ->
      addProposal proposal for proposal of @collection.models
      @
      
    addProposal: (proposal) ->
      view = new ProposalView(model: proposal)
      @$el.append(view.render().el)
        
  ProposalsView  