define [

  "backbone",
  "models/proposal"
  
], (Backbone, Proposal) ->
  
  "use strict"
  
  class Proposals extends Backbone.Collection
    
    model: Proposal
    
    url: "/proposals"
    
    # comparator: (proposal) ->
    #   return proposal.get("created_at")
    
    parse: (response) ->
      @pagination = {page: response.page, total: response.total_page}
      return response.models
    
  Proposals  