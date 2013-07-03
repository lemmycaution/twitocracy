module Back

  extend ActiveSupport::Concern
    
  included do
  
    # index
    # returns json representation of latest proposals with given page (default 1)
    # valid parameters are page and scope
    # look Proposal model for all scopes
    # GET /proposals(?page=1, optional)(&scope=closed, optional)
    get "/proposals" do
      proposals = Proposal.all
      proposals = proposals.public_send params["scope"] || :open
    
      page = (params["page"] || 1).to_i
      total_page = [(proposals.count.to_f / Proposal::DEFAULT_LIMIT.to_f).ceil,1].max

      render_json({models: proposals.page(page), page: page, total_page: total_page})
    end
  
    # show
    # returns json representation of proposal with given id
    # GET /proposals/1
    get "/proposals/:id" do
      error 404 unless proposal = Proposal.find_by(id: params["id"])
      render_json proposal 
    end
  
    # create
    # creates a new proposal
    # accepts x-url-form-encoded post parameters
    # POST /proposals  
    post "/proposals" do
      authenticate_user!
      proposal = current_user.proposals.new(params)
      if proposal.save
        render_json proposal, status: 201
      else
        render_json proposal.errors, status: 406
      end
    end
  
    # update (up and down vote only)
    patch "/proposals/:id" do
      authenticate_user!
      error 404 unless proposal = Proposal.open.find_by(id: params["id"])
      error 405 unless proposal.respond_to?(params["method"])
      if proposal.send(params["method"],current_user)
        render_json proposal
      else
        render_json proposal.errors, status: 406
      end
    end
  
    # delete
    delete "/proposals/:id" do
      authenticate_user!
      error 404 unless proposal = Proposal.find_by(id: params["id"].to_i)
      error 422 unless proposal.user.eql? current_user
      render_json proposal.destroy
    end
    
  end
  
end