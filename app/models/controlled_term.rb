#encoding: utf-8
class ControlledTerm < ActiveRecord::Base

  include ActsAsElasticModel

  has_many :controlled_term_values, foreign_key: :controlled_attribute_id,
    class_name: "ControlledTermValue", dependent: :destroy
  has_many :controlled_term_value_attrs, foreign_key: :controlled_value_id,
    class_name: "ControlledTermValue", dependent: :destroy
  has_many :labels, class_name: "ControlledTermLabel", dependent: :destroy
  has_many :values, through: :controlled_term_values, source: :controlled_value
  has_many :attrs, through: :controlled_term_value_attrs, source: :controlled_attribute
  has_many :value_annotations, class_name: "Annotation", foreign_key: :controlled_value_id
  has_many :attribute_annotations, class_name: "Annotation", foreign_key: :controlled_attribute_id
  belongs_to :valid_within_taxon, foreign_key: :valid_within_clade,
    class_name: "Taxon"

  scope :active, -> { where(active: true) }
  scope :attributes, -> { where(is_value: false) }
  scope :values, -> { where(is_value: true) }
  scope :unassigned_values, -> {
    values.
    joins("LEFT JOIN controlled_term_values ctv ON (controlled_terms.id = ctv.controlled_value_id)").
    where("ctv.id IS NULL")
  }
  scope :for_taxon, -> (taxon) {
    joins("LEFT OUTER JOIN taxon_ancestors ta
      ON controlled_terms.valid_within_clade = ta.ancestor_taxon_id").
    where("controlled_terms.valid_within_clade IS NULL OR ta.taxon_id=?", taxon).distinct
  }

  VALUES_TO_MIGRATE = {
    male: :sex,
    female: :sex,
    juvenile: :life_stage,
    adult: :life_stage,
    pupa: :life_stage,
    pupae: :life_stage,
    larva: :life_stage,
    larvae: :life_stage,
    caterpillar: :life_stage,
    teneral: :life_stage,
    egg: :life_stage,
    nymph: :life_stage
  }

  attr_accessor :prepared_values

  def self.first_term_by_label(label)
    return unless label
    first_label = ControlledTermLabel.
      where("lower(label) = ?", label.downcase).first
    return first_label.controlled_term if first_label
  end

  def self.life_stage
    @@life_stage ||= ControlledTermLabel.
      where("lower(label) = 'life stage'").first.controlled_term
  end

  def term_label(options = { })
    options[:locale] = options[:locale].to_s || "en"
    all_labels = labels.order(:id)
    if options[:taxon] && options[:taxon].is_a?(Taxon)
      if match = all_labels.detect{ |l| l.locale == options[:locale] &&
          l.valid_within_taxon && options[:taxon].has_ancestor_taxon_id(l.valid_within_taxon.id) }
        return match
      end
    end
    if match = all_labels.detect{ |l| l.locale == options[:locale] }
      return match
    end
    all_labels.first
  end

  def label(options = { })
    if tl = term_label(options)
      tl.label
    end
  end

  def possible_attribute_associates
    return unless is_value?
    scope = ControlledTerm.attributes
    if controlled_term_value_attrs.any?
      scope = scope.where("id NOT IN (?)", controlled_term_value_attrs.map(&:controlled_attribute_id))
    end
    scope.map{ |t| [ t.label, t.id ] }
  end

  def values_for_observation(o)
    values - o.annotations.where(controlled_attribute: self).map{ |ct| ct.controlled_value }
  end

  def applicable_to_taxon(t)
    return false if t.blank? || !t.is_a?(Taxon)
    return true unless valid_within_taxon
    return true if t.has_ancestor_taxon_id(valid_within_taxon.id)
    false
  end

end
