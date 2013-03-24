// Utility functions by W. Craig Trader are dual-licensed under 
// Creative Commons Attribution-ShareAlike 3.0 Unported License and
// GNU Lesser GPL 3.0 or later.

// ----- Measurements ---------------------------------------------------------

inch = 25.4;            // millimeters in an inch

// ----- Place a part via translation and rotation ----------------------------

module place( translation=[0,0,0], angle=0, hue="" ) {
	for (i = [0 : $children-1]) {
		translate( translation ) 
			rotate( a=angle ) 
				if ( hue != "" ) {
					color( hue ) child(i);
				} else {
					child(i);
				}
	}
}


