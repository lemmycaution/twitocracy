define [

  "backbone",
  "models/proposal"
  
], (Backbone, Proposal) ->
  
  "use strict"
  
  class Proposals extends Backbone.Collection
    
    model: Proposal
    
    url: "/proposals"
    
  Proposals  