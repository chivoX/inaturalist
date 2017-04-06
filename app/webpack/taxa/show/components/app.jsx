import React, { PropTypes } from "react";
import { Grid, Row, Col } from "react-bootstrap";
import SplitTaxon from "../../../shared/components/split_taxon";
import TaxonAutocomplete from "../../../shared/components/taxon_autocomplete";
import PhotoPreviewContainer from "../containers/photo_preview_container";
import ChartsContainer from "../containers/charts_container";
import Leaders from "../components/leaders";
import TaxonPageTabsContainer from "../containers/taxon_page_tabs_container";
import PhotoModalContainer from "../containers/photo_modal_container";
import PhotoChooserModalContainer from "../containers/photo_chooser_modal_container";
import PlaceChooserContainer from "../containers/place_chooser_container";
import TaxonChangeAlertContainer from "../containers/taxon_change_alert_container";
import TaxonCrumbsContainer from "../containers/taxon_crumbs_container";
import AkaNamesContainer from "../containers/aka_names_container";
import StatusRow from "./status_row";

const App = ( { taxon, showNewTaxon } ) => (
  <div id="TaxonDetail">
    <Grid>
      <TaxonChangeAlertContainer />
      <Row className="preheader">
        <Col xs={8}>
          <TaxonCrumbsContainer />
          <a className="permalink" href={`/taxa/${taxon.id}-${taxon.name.split( " " ).join( "-" )}`}>
            <i className="icon-link"></i>
          </a>
        </Col>
        <Col xs={4}>
          <div className="pull-right">
            <TaxonAutocomplete
              inputClassName="input-sm"
              bootstrapClear
              placeholder={I18n.t( "search_species_" )}
              searchExternal={false}
              afterSelect={ function ( result ) {
                showNewTaxon( result.item );
              } }
              position={{ my: "right top", at: "right bottom", collision: "none" }}
            />
          </div>
        </Col>
      </Row>
      <Row id="TaxonHeader">
        <Col xs={12}>
          <div className="inner">
            <h1>
              <SplitTaxon
                taxon={taxon}
                forceRank={taxon.rank_level > 10 && !taxon.preferred_common_name}
              />
            </h1>
            <div>
              <PlaceChooserContainer />
            </div>
          </div>
        </Col>
        <Col xs={12}>
          <AkaNamesContainer />
        </Col>
      </Row>
    </Grid>
    <Grid fluid>
      <Row id="hero">
        <Col xs={12}>
          <Grid>
            <StatusRow
              conservationStatus={taxon.conservationStatus}
              establishmentMeans={taxon.establishment_means}
            />
            <Row>
              <Col xs={6}>
                <PhotoPreviewContainer />
              </Col>
              <Col xs={6}>
                <Leaders taxon={taxon} />
                <Row>
                  <Col xs={12}>
                    <ChartsContainer />
                  </Col>
                </Row>
              </Col>
            </Row>
          </Grid>
        </Col>
      </Row>
    </Grid>
    <TaxonPageTabsContainer />
    <PhotoModalContainer />
    <PhotoChooserModalContainer />
  </div>
);

App.propTypes = {
  taxon: PropTypes.object,
  showNewTaxon: PropTypes.func
};

export default App;
