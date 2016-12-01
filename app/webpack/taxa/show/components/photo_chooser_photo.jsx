import React, { PropTypes } from "react";

const PhotoChooserPhoto = ( { removePhoto, infoURL, src, chooserID } ) => (
  <div>
    { typeof( removePhoto ) !== "function" ? null : (
      <a
        onClick={ ( ) => removePhoto( chooserID ) }
        href="#"
        className="control-link remove-link"
      >
        <i className="fa fa-times-circle"></i>
      </a>
    ) }
    { !infoURL ? null : (
      <a href={infoURL} target="_blank" className="control-link info-link">
        <i className="icon-link"></i>
      </a>
    ) }
    <img src={src} />
  </div>
);

PhotoChooserPhoto.propTypes = {
  removePhoto: PropTypes.func,
  infoURL: PropTypes.string,
  src: PropTypes.string.isRequired,
  chooserID: PropTypes.string.isRequired
};

export default PhotoChooserPhoto;
