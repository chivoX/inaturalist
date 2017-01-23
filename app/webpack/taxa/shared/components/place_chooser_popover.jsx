import React, { PropTypes } from "react";
import ReactDOM from "react-dom";
import {
  OverlayTrigger,
  Popover,
  Input
} from "react-bootstrap";
import inatjs from "inaturalistjs";
import _ from "lodash";
import mousetrap from "mousetrap";

const PLACE_TYPES = {
  0: "Undefined",
  1: "Building",
  2: "Street Segment",
  3: "Nearby Building",
  5: "Intersection",
  6: "Street",
  7: "Town",
  8: "State",
  9: "County",
  10: "Local Administrative Area",
  11: "Postal Code",
  12: "Country",
  13: "Island",
  14: "Airport",
  15: "Drainage",
  16: "Land Feature",
  17: "Miscellaneous",
  18: "Nationality",
  19: "Supername",
  20: "Point of Interest",
  21: "Region",
  22: "Suburb",
  23: "Sports Team",
  24: "Colloquial",
  25: "Zone",
  26: "Historical State",
  27: "Historical County",
  29: "Continent",
  31: "Time Zone",
  32: "Nearby Intersection",
  33: "Estate",
  35: "Historical Town",
  36: "Aggregate",
  100: "Open Space",
  101: "Territory",
  102: "District",
  103: "Province",
  1000: "Municipality",
  1001: "Parish",
  1002: "Department Segment",
  1003: "City Building",
  1004: "Commune",
  1005: "Governorate",
  1006: "Prefecture",
  1007: "Canton",
  1008: "Republic",
  1009: "Division",
  1010: "Subdivision",
  1011: "Village block",
  1012: "Sum",
  1013: "Unknown",
  1014: "Shire",
  1015: "Prefecture City",
  1016: "Regency",
  1017: "Constituency",
  1018: "Local Authority",
  1019: "Poblacion",
  1020: "Delegation"
};

class PlaceChooserPopover extends React.Component {

  constructor( props ) {
    super( props );
    this.state = {
      places: [],
      current: -1
    };
  }

  componentDidMount( ) {
    this.setPlacesFromProps( this.props );
  }

  componentWillReceiveProps( newProps ) {
    this.setPlacesFromProps( newProps );
  }

  setPlacesFromProps( props ) {
    if ( props.defaultPlace ) {
      let newPlaces = this.state.places;
      newPlaces = _.filter( newPlaces, p => p.id !== props.defaultPlace.id );
      newPlaces.splice( 0, 0, props.defaultPlace );
      this.setState( { places: newPlaces } );
    }
  }

  fetchPlaces( text ) {
    inatjs.places.autocomplete( { q: text } ).then( response => {
      let newPlaces = response.results;
      if (
        this.props.defaultPlace &&
        this.props.place &&
        this.props.place.id !== this.props.defaultPlace.id
      ) {
        newPlaces = _.filter( newPlaces, p => p.id !== this.props.defaultPlace.id );
        newPlaces.splice( 0, 0, this.props.defaultPlace );
      }
      this.setState( { places: newPlaces } );
    } );
  }

  highlightNext( ) {
    this.setState( {
      current: Math.min( this.state.places.length, this.state.current + 1 )
    } );
  }

  highlightPrev( ) {
    // TODO
    this.setState( {
      current: Math.max( -1, this.state.current - 1 )
    } );
  }

  chooseCurrent( ) {
    const currentPlace = this.state.places[this.state.current];
    // Dumb, but I don't see a better way to explicity close the popover
    $( "body" ).click( );
    if ( currentPlace ) {
      this.props.setPlace( currentPlace );
    } else {
      this.props.clearPlace( );
    }
  }

  bindArrowKeys( ) {
    const domNode = ReactDOM.findDOMNode( this.refs.input );
    mousetrap( domNode ).bind( "up", ( ) => this.highlightPrev( ) );
    mousetrap( domNode ).bind( "down", ( ) => this.highlightNext( ) );
    mousetrap( domNode ).bind( "enter", ( ) => this.chooseCurrent( ) );
  }

  unbindArrowKeys( ) {
    const domNode = ReactDOM.findDOMNode( this.refs.input );
    mousetrap( domNode ).unbind( "up" );
    mousetrap( domNode ).unbind( "down" );
    mousetrap( domNode ).unbind( "enter" );
  }

  render( ) {
    const { place, className } = this.props;
    return (
      <OverlayTrigger
        trigger="click"
        placement="bottom"
        rootClose
        onEntered={( ) => {
          this.bindArrowKeys( );
          $( "input", ReactDOM.findDOMNode( this.refs.input ) ).focus( );
        }}
        onExit={( ) => {
          this.unbindArrowKeys( );
        }}
        overlay={
          <Popover id="place-chooser" className="PlaceChooserPopover">
            <Input
              type="text"
              placeholder={I18n.t( "search" )}
              ref="input"
              onChange={ ( ) => {
                const text = $( "input", ReactDOM.findDOMNode( this.refs.input ) ).val( );
                if ( text.length === 0 ) {
                  this.setState( { places: [] } );
                } else {
                  this.fetchPlaces( text );
                }
              }}
            />
            <ul className="list-unstyled">
              <li
                className={this.state.current === -1 ? "current" : ""}
                onMouseOver={( ) => {
                  this.setState( { current: -1 } );
                }}
                onClick={( ) => this.chooseCurrent( )}
                className="pinned"
                style={{ display: this.props.place ? "block" : "none" }}
              >
                <i className="fa fa-times"></i>
                { _.capitalize( I18n.t( "clear" ) ) }
              </li>
              { _.map( this.state.places, ( p, i ) => {
                let placeType;
                if ( p && PLACE_TYPES[p.place_type] ) {
                  placeType = I18n.t( `place_geo.geo_planet_place_types.${_.snakeCase( PLACE_TYPES[p.place_type] )}` );
                }
                return (
                  <li
                    key={`place-chooser-place-${p.id}`}
                    className={
                      `media ${this.state.current === i ? "current" : ""}
                      ${this.props.defaultPlace && p.id === this.props.defaultPlace.id ? "pinned" : ""}`
                    }
                    onClick={( ) => this.chooseCurrent( )}
                    onMouseOver={( ) => {
                      this.setState( { current: i } );
                    }}
                  >
                    <div className="media-left">
                      <i className="media-object fa fa-map-marker"></i>
                    </div>
                    <div className="media-body">
                      {
                        I18n.t( `places_name.${_.snakeCase( p.name )}`, { defaultValue: p.display_name } )
                      } {
                        placeType ? <span className="text-muted place-type">({placeType})</span> : null
                      }
                    </div>
                  </li>
                );
              } ) }
            </ul>
          </Popover>
        }
      >
        <div
          className={`PlaceChooserPopoverTrigger ${place ? "chosen" : ""} ${className}`}
        >
          <i className="fa fa-map-marker"></i>
          {
            place ?
              I18n.t( `places_name.${_.snakeCase( place.name )}`, { defaultValue: place.display_name } )
              :
              _.startCase( I18n.t( "filter_by_place" ) ) }
        </div>
      </OverlayTrigger>
    );
  }
}

PlaceChooserPopover.propTypes = {
  place: PropTypes.object,
  defaultPlace: PropTypes.object,
  className: PropTypes.string,
  setPlace: PropTypes.func,
  clearPlace: PropTypes.func
};

export default PlaceChooserPopover;
