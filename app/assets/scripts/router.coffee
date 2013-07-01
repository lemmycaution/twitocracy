define [
  
  "jquery",
  "underscore",
  "backbone",
  "models/proposal",
  "collections/proposals",  
  "views/proposal"
  "views/proposals"  
  
], ($, _, Backbone, Proposal, Proposals, ProposalView, ProposalsView) ->
  
  "use strict"
  
  class Router extends Backbone.Router
    
      routes:
        "(scope/:scope)(page/:page)"     : "index"
        "scope/:scope(/page/:page)"      : "index"
        "new"                            : "new"
        ":id"                            : "show" 

      index: (scope, page) ->
        app.view = new ProposalsView(data: {scope: scope, page: page})
        
      new: ->
        
        $("input[name=downvoting_enabled]").on "change", (e) =>
          if $(e.currentTarget).val() == "true"
            $("#proposal_up_tweet, #proposal_down_tweet").
            removeAttr("disabled").parent("p").show()
          else
            $("#proposal_up_tweet, #proposal_down_tweet").
            attr("disabled",true).parent("p").hide()            
          
        $("textarea, input").on "change", (e) =>
          $e = $(e.currentTarget)
          if $e.hasClass("error")
            $e.removeClass("error").parent("p").find("small").remove()
        
        d = new Date()
        $("#proposal_started_at").val "#{d.getDate()}/#{d.getMonth()+1}/#{d.getFullYear()-1}"
        $("#proposal_finished_at").val "#{d.getDate()}/#{d.getMonth()+1}/#{d.getFullYear()+1}"        
          
        $("#new_proposal").on "submit", (e) =>
          e.preventDefault()          
          $e = $(e.currentTarget)
          app.set_button_state $e.find("button")[0]
          data = _.serializeForm(e.currentTarget)
          proposals = new Proposals
          proposals.create(
            data,
            success: (model) ->
              window.location.href = "/#{model.get("id")}"
            error: (model,xhr) ->
              app.set_button_state $e.find("button")[0], false
              errors =  JSON.parse(xhr.responseText)
              $(".error_container").remove()
              for error of errors
                $("#proposal_#{error}").addClass("error").
                parent("p").append("<small class=\"error_container\"><br/>#{errors[error].join(",")}</small>")
          )
            
    
      show: (id) ->
        app.view = new ProposalView(id: id, add: true)
          
  Router  