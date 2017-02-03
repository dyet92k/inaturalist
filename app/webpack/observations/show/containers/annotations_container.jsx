import { connect } from "react-redux";
import Annotations from "../components/annotations";
import { addAnnotation, deleteAnnotation, voteAnnotation,
  unvoteAnnotation } from "../ducks/observation";

function mapStateToProps( state ) {
  return {
    observation: state.observation,
    config: state.config,
    controlledTerms: state.controlledTerms
  };
}

function mapDispatchToProps( dispatch ) {
  return {
    addAnnotation: ( controlledAttributeID, controlledValueID ) => {
      dispatch( addAnnotation( controlledAttributeID, controlledValueID ) );
    },
    deleteAnnotation: ( id ) => { dispatch( deleteAnnotation( id ) ); },
    voteAnnotation: ( id, vote ) => { dispatch( voteAnnotation( id, vote ) ); },
    unvoteAnnotation: ( id ) => { dispatch( unvoteAnnotation( id ) ); }
  };
}

const AnnotationsContainer = connect(
  mapStateToProps,
  mapDispatchToProps
)( Annotations );

export default AnnotationsContainer;
