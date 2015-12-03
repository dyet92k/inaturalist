var iNatModels = iNatModels || { };

iNatModels.Observation = function( attrs ) {
  var that = this;
  _.each( attrs, function( value, attr ) {
    that[ attr ] = value;
  });
};

iNatModels.Observation.prototype.photo = function( ) {
  if( this.photos && this.photos.length > 0 ) {
    var url = this.photos[0].url;
    url = url.replace( "square.jpg", "large.jpg" );
    url = url.replace( "square.JPG", "large.JPG" );
    return url;
  }
};
