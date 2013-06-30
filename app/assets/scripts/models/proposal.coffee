define [

  "backbone",
  
], (Backbone) ->
  
  "use strict"
  
  class Proposal extends Backbone.Model
    
    url: ->
      if @get("id")
        "/proposals/#{@get("id")}"
      else
        "/proposals"  
        
    remaining_time_to_human: ->
      remaining = Math.round(new Date(@get('finished_at')) - new Date(@get('started_at'))) / 1000
      # less than a hour
      if remaining <= 3600
        "#{remaining / 60} minutes"
      # less than a day  
      else if remaining <= 86400
        "#{remaining / 3600} hours"
      else
        "#{remaining / 86400} days"    
    
  Proposal  