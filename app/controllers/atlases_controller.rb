class AtlasesController < ApplicationController
  before_filter :authenticate_user!
  before_filter :curator_required, :only => [:new, :create, :edit, :update,
    :destroy, :alter_atlas_presence, :destroy_all_alterations, :remove_atlas_alteration,
    :remove_listed_taxon_alteration, :refresh_atlas]
  before_filter :find_atlas, except: [ :new, :create, :index ]
  layout "bootstrap"

  def new
    @atlas = Atlas.new( taxon_id: params[:taxon_id].to_i )
  end

  def edit
    @exploded_atlas_places = @atlas.exploded_atlas_places.includes( :place )
    @atlas_places = @atlas.places
  end

  def show
    @atlas_places = @atlas.places
    @atlas_presence_places_with_establishment_means = @atlas.presence_places_with_establishment_means
    @atlas_presence_places_with_establishment_means_hash = Hash[@atlas_presence_places_with_establishment_means.map{ |e| [ e[:id], e[:establishment_means] ] }]
    @exploded_places = Hash[@atlas.exploded_atlas_places.map{ |e| [ e.place_id, e.id ] }]
    @atlas_presence_places_with_establishment_means_hash_json = @atlas_presence_places_with_establishment_means_hash.to_json
    @exploded_places_json = @exploded_places.to_json
    
    #any obs outside of the complete set
    @observations_not_in_atlas_places_params = { 
      taxon_id: @atlas.taxon_id, 
      quality_grade: ["research","needs_id"].join( "," ), 
      not_in_place: @atlas_presence_places_with_establishment_means.map{|p| p[:id] }.join( "," )
    }
    @num_obs_not_in_atlas_places = INatAPIService.observations( @observations_not_in_atlas_places_params.merge( per_page: 0 ) ).total_results
    respond_to do |format|
      format.html do
        @is_curator = "#{current_user.is_curator?}"
        @atlas_alterations = @atlas.atlas_alterations.includes( :place, :user ).order( "created_at DESC" ).
          limit( 30 ).reverse
        @listed_taxon_alterations = @atlas.relevant_listed_taxon_alterations.includes( :place, :user ).
          order( "listed_taxon_alterations.created_at DESC" ).limit( 30 ).reverse
      end
      format.json { render json: {
          presence_places: @atlas_presence_places_with_establishment_means_hash,
          exploded_places: @exploded_places
        }
      }
    end
  end
  
  def index
    @marked_atlases = Atlas.where(is_active: true, is_marked: true).page(params[:page]).per_page(10)
  end

  def create
    @atlas = Atlas.new( params[:atlas].merge(:user_id => current_user.id) )
    respond_to do |format|
      if @atlas.save
        format.html { redirect_to( @atlas, notice: "Atlas was successfully created." ) }
      else
        format.html { render action: "new" }
      end
    end
  end

  def update
    respond_to do |format|
      if @atlas.update_attributes( params[:atlas] )
        @atlas.taxon
        format.html { redirect_to( @atlas, notice: "Atlas was successfully updated." ) }
      else
        format.html { render action: "edit" }
      end
    end
  end

  def destroy
    @atlas.destroy
    respond_to do |format|
      format.html { redirect_to( @atlas.taxon ) }
    end
  end

  ## Custom actions ############################################################

  def alter_atlas_presence
    taxon_id = params[:taxon_id]
    @place_id = params[:place_id]
    place = Place.find( @place_id )
    taxon = Taxon.find( taxon_id )
    lts = taxon.atlas.get_atlas_presence_place_listed_taxa( @place_id )
    if lts.count > 0
      lts.each do |lt|
        lt.updater = current_user
        lt.destroy
      end
      @presence = false
    else
      list_id = place.check_list_id
      lt = ListedTaxon.create( taxon_id: taxon_id, place_id: @place_id, list_id: list_id, user_id: current_user.id )
      if lt.errors.any?
        @presence = "not allowed"
      else
        @presence = true
      end
    end

    respond_to do |format|
      format.json { render json: { place_name: place.name, place_id: @place_id, presence: @presence }, status: :ok }
    end
  end

  def destroy_all_alterations
    atlas_id = @atlas.id
    AtlasAlteration.where( atlas_id: atlas_id ).destroy_all
    respond_to do |format|
      format.json { render json: {}, status: :ok }
    end
  end

  def remove_atlas_alteration
    aa_id = params[:aa_id]
    aa = AtlasAlteration.find( aa_id )
    aa.destroy
    respond_to do |format|
      format.json { render json: {}, status: :ok}
    end
  end

  def remove_listed_taxon_alteration
    lta_id = params[:lta_id]
    lta = ListedTaxonAlteration.find( lta_id )
    lta.destroy
    respond_to do |format|
      format.json { render json: {}, status: :ok }
    end
  end

  def get_defaults_for_taxon_place
    taxon_id = params[:taxon_id]
    place_id = params[:place_id]
    lt = ListedTaxon.get_defaults_for_taxon_place( place_id, taxon_id, { limit: 10 } )
    render json: lt, include: { taxon: { only: :name }, place: { only: :name } }, only: :id
  end
  
  def refresh_atlas
    is_marked = Atlas.still_is_marked(@atlas)
    respond_to do |format|
      format.json { render json: is_marked, status: :ok }
    end
  end

  private

  def find_atlas
    begin
      @atlas = Atlas.find( params[:id] )
    rescue
      render_404
    end
  end

end
