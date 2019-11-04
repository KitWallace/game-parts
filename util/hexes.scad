// Hexagon Library
// by W. Craig Trader
//
// --------------------------------------------------------------------------------------------------------------------
//
// This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License.
// To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-sa/4.0/
// or send a letter to Creative Commons, PO Box 1866, Mountain View, CA 94042, USA.
//
// --------------------------------------------------------------------------------------------------------------------

DEBUG = is_undef( DEBUG ) ? (is_undef( VERBOSE ) ? true : VERBOSE) : DEBUG;

include <units.scad>;
include <printers.scad>;

assert( version_num() > 20190000, "********** Will NOT work with this version of OpenSCAD **********" );

// ----- Physical Measurements ----------------------------------------------------------------------------------------

// ----- X and Y Offsets for positioning hex corners ------------------------------------------------------------------

TILE_CORNERS = [
    [ 0, 2 ],   // 0 = North
    [ 2, 1 ],   // 1 = North East
    [ 2,-1 ],   // 2 = South East
    [ 0,-2 ],   // 3 = South
    [-2,-1 ],   // 4 = South West
    [-2, 1 ],   // 5 = North West
    [ 0, 2 ],   // 6 = North (again)
];

// ----- Functions ----------------------------------------------------------------------------------------------------

function hex_tile_pos( r, c ) = [2+c*4+2*(r%2), 2+r*3 ];
function hex_tile_row( r, cols ) = [ for( c=[0:cols-1] ) hex_tile_pos( r, c ) ];
function hex_tile_even_rows( rows, cols ) = [ for( r=[0:rows-1] ) hex_tile_row( r, cols ) ];
function hex_tile_uneven_rows( rows, cols ) = [ for( r=[0:rows-1] ) hex_tile_row( r, cols-r%2 ) ];

function hex_length( diameter ) = diameter;
function hex_width( diameter ) = hex_length( diameter ) * sin(60);
function hex_edge( diameter ) = hex_length( diameter ) / 2;
function hex_angle( c ) = ( 60 * c + 240 ) % 360;

function hex_config( diameter ) = [ hex_width( diameter )/4, hex_length( diameter )/4, hex_edge( diameter ) ];

function hex_rows( layout ) = len( layout );
function hex_cols( layout ) = max( len( layout[0] ), len( layout[1] ) );
function uneven_rows( layout ) = (len( layout[0] ) != len( layout[1] )) ? 0 : 0.5;
function short_row( layout ) = len( layout[0] ) > len( layout[1] ) ? 1 : 0;

function layout_size( layout, hex ) = [ (hex_cols( layout ) + uneven_rows( layout ) ) * hex_width( hex ), (hex_rows( layout ) * 3+1) / 4 * hex_length( hex ), 0 ];

// ----- Modules ------------------------------------------------------------------------------------------------------

/* hex_wall( corner, offset, width, height, size )
 *
 * This creates one wall of a hexagon, starting at a corner
 *
 * corner -- starting corner (0-5)
 * config -- vector that describes this hexagon
 * width  -- thickness of the wall
 * height -- height of the wall
 * size   -- This is how large a percentage of the wall to construct (-1 <= size < 0 || 0 < size <= 1).
 *
 * Hex walls rarely run from one corner to the next -- they either have a gap in the middle of the wall,
 * or gaps around either end of the wall. If the size is positive, it describes how large the centered wall is;
 * If the size is negative, it describes how large the centered gap between two end walls is.
 *
 * Examples:
 * +0.60  =>   *    ------------    *
 * -0.60  =>   *----            ----*
 */

module hex_wall( corner, config, width, height, size=+0.60, fn=6 ) {
    diff = TILE_CORNERS[ corner+1 ] - TILE_CORNERS[ corner ];

    m0 = 0.0;
    m1 = (1 - abs( size ) ) / 2;
    m2 = 1 - m1;
    m3 = 1.0;

    position = [ diff.x*config.x, diff.y*config.y, 0 ];

    if (size > 0) {
        w2l = width / config[2];
        hull() {
            translate( position*(m1+w2l) ) cylinder( d=width, h=height, $fn=fn );
            translate( position*(m2-w2l) ) cylinder( d=width, h=height, $fn=fn );
        }
    } else {
        hull() {
            translate( position*m0 ) cylinder( d=width, h=height, $fn=fn );
            translate( position*m1 ) cylinder( d=width, h=height, $fn=fn );
        }
        hull() {
            translate( position*m2 ) cylinder( d=width, h=height, $fn=fn );
            translate( position*m3 ) cylinder( d=width, h=height, $fn=fn );
        }
    }
}

module hex_cube_wall( corner, config, width, height, size ) {
    diff = TILE_CORNERS[ corner+1 ] - TILE_CORNERS[ corner ];

    m0 = 0.0;
    m1 = (1 - abs( size ) ) / 2;
    m2 = 1 - m1;
    m3 = 1.0;

    angle = corner * -60 - 30;
    position = [ diff.x*config.x, diff.y*config.y, 0 ];
    center = [0,-width/2,0];
    
    if (size > 0) {
        translate( position*m1 ) rotate( angle ) translate( center ) cube( [config[2]*(m2-m1), width, height] );
    } else {
        translate( position*m0 ) rotate( angle ) translate( center ) cube( [config[2]*(m1-m0), width, height] );
        translate( position*m2 ) rotate( angle ) translate( center ) cube( [config[2]*(m3-m2), width, height] );
    }
}

module hex_angle_wall( corner, config, width, height, size, zscale = 1.0 ) {
    diff = TILE_CORNERS[ corner+1 ] - TILE_CORNERS[ corner ];

    m0 = 0.0;
    m1 = (1 - abs( size ) ) / 2;
    m2 = 1 - m1;
    m3 = 1.0;

    angle = corner * -60 - 30;
    position = [ diff.x*config.x, diff.y*config.y, 0 ];
    center = [0,-0,0];
    
    module angle_wall( size, zscale ) {
        d1 = size.y/2; d3 = size.x; d2 = d3-d1;
        // linear_extrude( size.z, scale=zscale ) polygon( [ [d1,0], [0,d1], [d3,d1], [d2,0], [d2,-d1], [0,-d1] ] );
        linear_extrude( size.z, scale=zscale ) polygon( [ [d1,d1], [d2,d1], [d2,-d1], [d1,-d1] ] );
    }
    
    if (size > 0) {
        translate( position*m1 ) rotate( angle ) translate( center ) angle_wall( [config[2]*(m2-m1), width, height], zscale );
    } else {
        translate( position*m0 ) rotate( angle ) translate( center ) angle_wall( [config[2]*(m1-m0), width, height], zscale );
        translate( position*m2 ) rotate( angle ) translate( center ) angle_wall( [config[2]*(m3-m2), width, height], zscale );
    }
}

/* hex_corner( corner, height )
 *
 * This creates a short segment of the corner of a hexagonal wall
 *
 * corner -- 0-5, specifying which corner of the hexagon to create, clockwise
 * height -- Height of the wall segment in millimeters
 * gap    -- Fraction of a millimeter, to tweak the width of the corner
 * size   -- width of the wall segment 
 *
 * @deprecated
 */
module hex_corner( corner, height, gap=0, size = WIDE_WALL ) {
    offset = corner * -60;
    for ( angle=[210,330] ) {
        rotate( [0, 0, angle+offset] ) translate( [ 0, -size/2-gap/2, 0 ] ) cube( [4*size, size+gap, height ] );
    }
    cylinder( d=size+2*gap, h=height );
}

/* hex_prism( height, diameter )
 *
 * Create a vertical hexagonal prism of a given height and diameter
 */
module hex_prism( height, diameter, angle=0 ) {
    bot_d = diameter;
    top_d = diameter + height * sin( angle );
    rotate( [ 0, 0, 90 ] ) cylinder( h=height, d1=bot_d, d2=top_d, $fn=6 );
}

/* hex_layout( layout, size, delta )
 *
 * This is an operation module that loops through all of the tiles in a hex layout,
 * coloring and positioning each child at the center of its hex.
 *
 * layout -- An array of tile offsets for each row/column
 * size   -- the diameter of each hexagon in the layout
 * delta  -- an optional position offset applied to each tile location
 *
 * Special variables defined for each child:
 *
 * $config -- the hex_config for this size of hex
 * $row    -- the row number for this child
 * $col    -- the column number for this child
 * $tile   -- the tile offsets for this child
 */
module hex_layout( layout, size, delta=[0,0,0] ) {
    $config = hex_config( size );
    maxRows = len( layout );
    for ($row = [0:maxRows-1] ) {
        maxCols = len( layout[$row] );
        for ($col = [0:maxCols-1] ) {
            $tile = layout[$row][$col];
            hue = [ $tile.x/(maxCols*4), $tile.y/(maxRows*3-1), 0.5, 1 ];
            position = [ $tile.x*$config.x+delta.x, $tile.y*$config.y+delta.y, delta.z ];
            color( hue ) translate( position ) children();
        }
    }
}

/* hex_corner_layout( layout, size, delta )
 *
 * This is an operation module that loops through all of the corners of all of the tiles in a hex layout,
 * coloring and positioning each child at the corner of its hex.
 *
 * layout -- An array of tile offsets for each row/column
 * size   -- the diameter of each hexagon in the layout
 * delta  -- an optional position offset applied to each tile location
 *
 * Special variables defined for each child:
 *
 * $config -- the hex_config for this size of hex
 * $row    -- the row number for this child (0-based)
 * $col    -- the column number for this child (0-based)
 * $corner -- the corner number for this child (0-5)
 * $tile   -- the tile offsets for this child
 */
module hex_corner_layout( layout, size, delta=[0,0,0] ) {
    $config = hex_config( size );
    maxRows = len( layout );
    for ($row = [0:maxRows-1] ) {
        maxCols = len( layout[$row] );
        for ($col = [0:maxCols-1] ) {
            $tile = layout[$row][$col];
            hue = [ $tile.x/(maxCols*4), $tile.y/(maxRows*3-1), 0.5, 1 ];
            for ($corner = [0:5] ) {
                tc = TILE_CORNERS[$corner];
                position = [ ($tile.x+tc.x)*$config.x+delta.x, ($tile.y+tc.y)*$config.y+delta.y, delta.z ];
                color( hue ) translate( position ) children();
            }
        }
    }
}

if (0) {
    layout = hex_tile_uneven_rows( 3,3 );
    color( "gray" ) hex_layout( layout, 40*mm ) hex_prism( 0.1*mm, 40*mm );
    color( "white" ) hex_layout( layout, 40*mm ) hex_prism( 0.2*mm, 39*mm );
    hex_corner_layout( layout, 40*mm ) {
        hex_angle_wall( $corner, $config, 3*mm, 10, 0.6, 1.1 );
    }
}

