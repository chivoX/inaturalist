class Identification < ActiveRecord::Base

  include ActsAsElasticModel

  DEFAULT_ES_BATCH_SIZE = 500

  scope :load_for_index, -> { includes(:taxon,
    { observation: [ :taxon, :user ] }, :user) }

  settings index: { number_of_shards: 1, analysis: ElasticModel::ANALYSIS } do
    mappings(dynamic: true) do
      indexes :uuid, type: "keyword"
      indexes :body, type: "text", analyzer: "ascii_snowball_analyzer"
      indexes :category, type: "keyword"
      indexes :observation do
        indexes :uuid, type: "keyword"
        indexes :quality_grade, type: "keyword"
        indexes :taxon do
          indexes :ancestry, type: "keyword"
          indexes :min_species_ancestry, type: "keyword"
          indexes :rank, type: "keyword"
          indexes :name, type: "text", analyzer: "ascii_snowball_analyzer"
        end
        indexes :user do
          indexes :login, type: "keyword"
        end
      end
      indexes :taxon do
        indexes :ancestry, type: "keyword"
        indexes :min_species_ancestry, type: "keyword"
        indexes :rank, type: "keyword"
        indexes :name, type: "text", analyzer: "ascii_snowball_analyzer"
      end
      indexes :user do
        indexes :login, type: "keyword"
      end
    end
  end

  def as_indexed_json(options={})
    created = created_at.in_time_zone((observation && observation.timezone_object) || "UTC")
    json = {
      id: id,
      uuid: uuid,
      user: user ? user.as_indexed_json(no_details: true) : nil,
      created_at: created_at,
      created_at_details: ElasticModel.date_details(created_at),
      body: body,
      category: category,
      current: current
    }
    if observation && taxon && !options[:no_details]
      json.merge!({
        own_observation: (user_id == observation.user_id),
        current_taxon: (taxon_id == observation.taxon_id),
        taxon: taxon.as_indexed_json(no_details: true, for_identification: true),
        observation: observation.as_indexed_json(no_details: true, for_identification: true)
      })
    end
    json
  end

  def self.prepare_batch_for_index(identifications)
    obs = identifications.map(&:observation).compact
    # bulk load the IDs' observations' places
    Observation.prepare_batch_for_index(obs, { places: true })
  end
end
