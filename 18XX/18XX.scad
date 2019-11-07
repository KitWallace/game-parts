// 18XX Tray Library
// by W. Craig Trader
//
// --------------------------------------------------------------------------------------------------------------------
//
// This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License.
// To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-sa/4.0/
// or send a letter to Creative Commons, PO Box 1866, Mountain View, CA 94042, USA.
//
// --------------------------------------------------------------------------------------------------------------------

DEBUG_18XX = is_undef( DEBUG_18XX ) ? (is_undef( VERBOSE ) ? true : VERBOSE) : DEBUG_18XX;

include <../util/boxes.scad>;
include <../util/hexes.scad>;

// ----- Physical dimensions ------------------------------------------------------------------------------------------


STUB        = 2.00 * mm;  // Height of lid stubs
STUB_GAP    = 0.25 * mm;  // Separation between lid stubs and tray hex corners

FONT_NAME   = "helvetica:style=Bold";
FONT_SIZE   = 6.0;
FONT_HEIGHT = layers( 4 );

$fa=4; $fn=30;

// ----- Calculated dimensions ----------------------------------------------------------------------------------------

WALL1 = WALL_WIDTH[4];
WALL2 = WALL1 + 2*STUB_GAP;
WALL3 = WALL2 + 2*WALL_WIDTH[4];
PADDING = [ 4*WALL1, 2*WALL1, 0 ];

HEX_SPACING = 3 * mm;   // 1.5 mm padding on each side of the tile

if (DEBUG_18XX) {
    echo ( Walls = [WALL1, WALL2, WALL3], Spacing=HEX_SPACING );
}

SHIFTING = 1.00 * mm;    // Room for tiles to shift

WIDTH  = 0;     // (X) Card width
HEIGHT = 1;     // (Y) Card height
MARKER = 2;     // (Z) Marker diameter

// ----- Functions ----------------------------------------------------------------------------------------------------

function actual_size( size, optimum ) = [ size.x == 0 ? optimum.x : size.x, size.y == 0 ? optimum.y : size.y, size.z ];
function uniform_token_cells( rows, cols, tx, ty ) = [ for( r=[0:rows-1] ) [ for( c=[0:cols-1] ) [ tx, ty ] ] ];

// ----- Modules ------------------------------------------------------------------------------------------------------

module hex_box_labels( labels, layout, size, inside, delta) {
    if (len(labels) > 0) {
        sr = short_row( layout );
        config = hex_config( size );

        for (l=[len(labels)-1:-1:0]) {
            ly = layout[sr+2*l][0][1]*config.y + delta.y;
            translate( [inside.x-delta.x+1, ly, -OVERLAP] )
                rotate( [0,0,-90] ) linear_extrude( height=FONT_HEIGHT+OVERLAP )
                    text( labels[l], font=FONT_NAME, size=FONT_SIZE, halign="center", valign="top" );
        }
    }
}

/* hex_box_corners( layout, size, hex, labels, dimensions )
 *
 * Create a tray to hold hexagonal tiles
 *
 * layout     -- Arrangement of tiles in box
 * size       -- Vector describing the exterior size of the box
 * hex        -- Diameter of a hex tile (corner to opposite corner)
 * labels     -- List of labels to add to the box
 * dimensions -- List of physical dimensions
 */
module hex_box_corners( layout, size, hex, labels=[], dimensions=REASONABLE ) {
    bottom = dimensions[BOTTOM];
    outer  = dimensions[OUTER];

    hexed = hex + HEX_SPACING;
    walls  = [ 4*outer+2*GAP, 4*outer+2*GAP, 0];
    minimum = layout_size( layout, hexed );
    optimum = minimum + walls + PADDING;

    inside = actual_size( size, optimum ) - walls;
    border = (inside - minimum) / 2;


    if (DEBUG_18XX) {
        echo( HexBoxCorners_Size=size, InSize=inside, Minimum=minimum, Border=border );
    }

    difference() {
        union() {
            // Add bottom plate
            rounded_box( inside, HOLLOW );

            // Add tile corners
            hex_corner_layout( layout, hexed, [border.x,border.y,-OVERLAP] ) {
                hex_wall( $corner, $config, WALL1, size.z+2*OVERLAP, -0.6 );
            }

            // Add labels
            hex_box_labels( labels, layout, hexed, inside, border );
        }

        // Remove finger holes
        hex_layout( layout, hexed, [border.x,border.y,-bottom-OVERLAP] ) {
            hex_prism( bottom+2*OVERLAP, hex*0.75 );
        }
    }
}

/* hex_lid_corners( width, depth, height, outer, inner, remove_corners, add_stubs )
 *
 * Create a lid for a hexagon tile tray
 *
 * width          -- Width (X) of the tray (outside dimensions)
 * depth          -- Depth (Y) of the tray (outside dimensions
 * height         -- Height (Z) of the stack of tiles (inside dimensions)
 * outer          -- Outer wall thickness
 * inner          -- Inner wall thickness
 * remove_corners -- True to remove the corners of the inner walls
 * add_stubs      -- True to add stubs that fit with the hex corners from the tray
 */
module hex_lid_corners( layout, size, hex, add_stubs=false, remove_holes=true, dimensions=REASONABLE ) {
    top = dimensions[TOP];
    outer = dimensions[OUTER];

    hexed = hex + HEX_SPACING;
    walls  = [ 4*outer+2*GAP, 4*outer+2*GAP, 0];
    minimum = layout_size( layout, hexed );
    optimum = minimum + walls + PADDING;

    inside = actual_size( size, optimum ) - walls;
    border = (inside - minimum) / 2;

    if (DEBUG_18XX) {
        echo( HexLidCorners_Size=size, InSize=inside, Border=border );
    }

    // Mirrored so that the lid match its box
    mirror( [0,1,0] ) union() {
        difference() {
            rounded_lid( inside );

            // Remove finger holes
            if (remove_holes) {
                hex_layout( layout, hexed, [border.x,border.y,-top-OVERLAP] ) {
                    hex_prism( top+2*OVERLAP, hex*0.75 );
                }
            }
        }

        if (add_stubs) {
            stub_z = min( size.z, STUB );   // If box is really thin, use thin stubs

            translate( [0,0,-OVERLAP] ) intersection() {
                color( "white" ) cube( [inside.x, inside.y, stub_z+OVERLAP] );
                difference() {
                    hex_corner_layout( layout, hexed, [border.x,border.y,0] ) {
                        hex_wall( $corner, $config, WALL3, stub_z+OVERLAP, -0.6 );
                    }
                    
                    hex_corner_layout( layout, hexed, [border.x,border.y,0] ) {
                        hex_wall( $corner, $config, WALL2, stub_z+2*OVERLAP, -0.4 );
                    }
                }
            }
        }
    }
}


/* hex_box_walls( layout, size, hex, labels, dimensions )
 *
 * Create a tray to hold hexagonal tiles
 *
 * layout     -- Arrangement of tiles in box
 * size       -- Vector describing the exterior size of the box
 * hex        -- Diameter of a hex tile (corner to opposite corner)
 * labels     -- List of labels to add to the box
 * dimensions -- List of physical dimensions
 *
 * size.x     -- (X) Outside length of box (if zero, use optimum)
 * size.y     -- (Y) Outside width of box (if zero, use optimum)
 * size.z     -- (Z) Inside height of box
 */
module hex_box_walls( layout, size, hex, labels=[], dimensions=REASONABLE ) {
    bottom = dimensions[BOTTOM];
    outer  = dimensions[OUTER];

    hexed = hex + HEX_SPACING;
    walls  = [ 4*outer+2*GAP, 4*outer+2*GAP, 0];
    minimum = layout_size( layout, hexed );
    optimum = minimum + walls + PADDING;

    inside = actual_size( size, optimum ) - walls;
    border = (inside - minimum) / 2;

    if (DEBUG_18XX) {
        echo( HexBoxWalls_Size=size, InSize=inside, Border=border );
    }

    difference() {
        union() {
            rounded_box( inside, HOLLOW );

            // Add tile sides
            hex_corner_layout( layout, hexed, [border.x,border.y,-OVERLAP] ) {
                hex_wall( $corner, $config, WALL1, size.z+2*OVERLAP );
            }

            // Add labels
            hex_box_labels( labels, layout, hexed, inside, border );
        }

        // Remove finger holes
        hex_layout( layout, hexed, [border.x,border.y,-bottom-OVERLAP] ) {
            hex_prism( bottom+2*OVERLAP, hex*0.75 );
        }
    }
}

/* hex_lid_walls( width, depth, height, outer, inner, remove_corners, add_stubs )
 *
 * Create a lid for a hexagon tile tray
 *
 * width          -- Width (X) of the tray (outside dimensions)
 * depth          -- Depth (Y) of the tray (outside dimensions
 * height         -- Height (Z) of the stack of tiles (inside dimensions)
 * outer          -- Outer wall thickness
 * inner          -- Inner wall thickness
 * remove_corners -- True to remove the corners of the inner walls
 * add_stubs      -- True to add stubs that fit with the hex corners from the tray
 *
 * size.x         -- (X) Outside length of box (if zero, use optimum)
 * size.y         -- (Y) Outside width of box (if zero, use optimum)
 * size.z         -- (Z) Inside height of box
 */
module hex_lid_walls( layout, size, hex, add_stubs=false, remove_holes=true, dimensions=REASONABLE ) {
    top = dimensions[TOP];
    outer = dimensions[OUTER];

    hexed = hex + HEX_SPACING;
    walls  = [ 4*outer+2*GAP, 4*outer+2*GAP, 0];
    minimum = layout_size( layout, hexed );
    optimum = minimum + walls + PADDING;

    inside = actual_size( size, optimum ) - walls;
    border = (inside - minimum) / 2;

    if (DEBUG_18XX) {
        echo( HexLidWalls_Size=size, InSize=inside, Border=border );
    }

    // Mirrored so that the lid match its box
    mirror( [0,1,0] ) union() {
        difference() {
            rounded_lid( inside );

            // Remove finger holes
            if (remove_holes) {
                hex_layout( layout, hexed, [border.x,border.y,-top-OVERLAP] ) {
                    hex_prism( top+2*OVERLAP, hex*0.75 );
                }
            }
        }

        if (add_stubs) {
            stub_z = min( size.z, STUB );   // If box is really thin, use thin stubs

            translate( [0,0,-OVERLAP] ) intersection() {
                color( "white" ) cube( [inside.x, inside.y, stub_z+OVERLAP] );
                hex_corner_layout( layout, hexed, [border.x,border.y,0] ) {
                    difference() {
                        hex_wall( $corner, $config, WALL3, stub_z+OVERLAP );
                        hex_wall( $corner, $config, WALL2, stub_z+2*OVERLAP );
                    }
                }
            }
        }
    }
}

/* hex_tray_buck( layout, size, hex, dimensions )
 *
 * Create a tray to hold hexagonal tiles
 *
 * layout     -- Arrangement of tiles in box
 * size       -- Vector describing the exterior size of the box
 * hex        -- Diameter of a hex tile (corner to opposite corner)
 * dimensions -- List of physical dimensions
 */
module hex_tray_buck( layout, size, hex, dimensions=THERMOFORM ) {
    bottom = 1.0 * mm;
    outer  = 1.0 * mm;
    vacuum = 1.5 * mm;
    slope  = 10; // degrees
    spread = 1.0 + sin(slope) * sin( 45 );
    spacing = 4.0 * mm;
    
    hex1 = hex + 3.0 * mm;
    hex2 = hex1 + spacing;
    
    base = [0, 0, bottom];
    padding = [ 2*WALL1, 2*WALL1, 0];
    minimum = layout_size( layout, hex2 );
    optimum = minimum + padding;

    actual = actual_size( size, optimum );
    inside = actual;
    border = (inside - minimum) / 2;
    
    if (DEBUG_18XX) {
        echo( HexTrayBuck_size=size, minimum=minimum, optimum=optimum, inside=inside, border=border, padding=padding );
        echo( Slope=slope, Spread=spread );
    }
    
    module buck_base( bsize, bangle, radius ) {
        mx = bsize.x;
        my = bsize.y;
        mz = bsize.z - OVERLAP;
        dr = radius;
        ds = mz * sin( bangle ) / 2;
        
        points = [
            [ ds+dr, ds+dr, 0 ],
            [ mx-ds-dr, ds+dr, 0],
            [ mx-ds-dr, my-ds-dr, 0 ],
            [ ds+dr, my-ds-dr, 0 ],
            [ dr, dr, mz ],
            [ mx-dr, dr, mz ],
            [ mx-dr, my-dr, mz ],
            [ dr, my-dr, mz ],
        ];
        faces = [
            [0,1,2,3],  // bottom
            [4,5,1,0],  // front
            [7,6,5,4],  // top
            [5,6,2,1],  // right
            [6,7,3,2],  // back
            [7,4,0,3],  // left        
        ];
        
        if (DEBUG_18XX) {
            actual = bsize+[2*ds+0.040*inch,2*ds+0.040*inch,0.020*inch];
            echo( BuckBase=bsize, dr=dr, ds=ds, mm=actual, inches=actual/25.4 );
        }
        
        minkowski() {
            polyhedron( points, faces );
            cylinder( r=radius, h=OVERLAP, $fn=48 );
        }
    }
    
    difference() {
        buck_base( inside+base, slope, 1*mm ); // cube( inside + base );
        
        hex_layout( layout, hex2, [border.x, border.y, bottom] ) {
            hex_prism( size.z+OVERLAP, hex1, slope );

            translate( [0,0,-bottom-OVERLAP] ) cylinder( d=vacuum, h=bottom+size.z+2*OVERLAP );

            for (c = [0:5]) {
                tc = TILE_CORNERS[c];
                hconfig = hex_config( hex1-spacing/2 );
                hposition = [ tc.x*hconfig.x, tc.y*hconfig.y, -bottom-OVERLAP ];
                translate( hposition ) cylinder( d=vacuum, h=bottom+size.z+2*OVERLAP, $fn=30 );
                translate( hposition+[0,0,+bottom*4/5] ) hex_cube_wall( c, hconfig, vacuum, size.z+bottom/5+2*OVERLAP, 1.0 );

                outside = hex_outside_wall(layout, $row, $col, c);
                if (!outside) {
                    cposition = [ tc.x*$config.x, tc.y*$config.y, 0 ];
                    translate( cposition ) hex_angle_wall( c, $config, spacing, size.z+2*OVERLAP, 0.5, spread );
                }
            }

        }
    }    
}

/* card_box( sizes, dimensions )
 *
 * Create a box to hold cards and tokens
 *
 * sizes      -- Width aand Height of cards, diameter of Marker
 * dimensions -- List of physical dimensions
 */
module card_box( sizes, dimensions=REASONABLE ) {
    inner  = dimensions[INNER];
    bottom = dimensions[BOTTOM];
    width  = sizes[WIDTH];
    height = sizes[HEIGHT];
    marker = sizes[MARKER];
    border = 10 * mm;

    inside = [
        marker + inner + width + 3 * SHIFTING,
        height + 2 * SHIFTING,
        layer_height( marker )
    ];

    mr = (marker + SHIFTING) / 2;   // Marker Radius

    window = [ inside.x-2*border-2*mr-inner, inside.y-2*border, bottom+2*OVERLAP ];

    if (DEBUG_18XX) {
        echo( CardBox=sizes, CardBoxInside=inside );
    }

    difference() {
        union() {
            // Start with a hollow box
            rounded_box( inside, HOLLOW );

            // Add a marker rack
            difference() {
                cube( [2*mr, inside.y, mr] );
                translate( [mr, 0, mr] ) rotate( [-90,0,0] ) cylinder( r=mr, h = inside.y, center=false );
            }

            // Add a divider
            translate( [2*mr, 0, 0] ) cube( [inner, inside.y, inside.z] );
        }

        // Remove a finger hole
        translate( [inside.x-window.x-border, border, -bottom-OVERLAP] ) cube( window );
    }
}

/* card_lid( sizes, dimensions )
 *
 * Create a lid for a card box
 *
 * sizes      -- Width aand Height of cards, diameter of Marker
 * dimensions -- List of physical dimensions
 */
module card_lid( sizes, dimensions=REASONABLE ) {
    inner  = dimensions[INNER];
    top    = dimensions[TOP];
    width  = sizes[WIDTH];
    height = sizes[HEIGHT];
    marker = sizes[MARKER];
    border = 10 * mm;

    inside = [
        marker + inner + width + 3 * SHIFTING,
        height + 2 * SHIFTING,
        layer_height( marker )
    ];

    mr = (marker + SHIFTING) / 2;   // Marker Radius

    window = [ inside.x-2*border-2*mr-inner, inside.y-2*border, top+2*OVERLAP ];

    mirror( [0,1,0] ) difference() {
        rounded_lid( inside );
        translate( [inside.x-window.x-border, border, -top-OVERLAP] ) cube( window );
    }
}

/* deep_card_box( sizes, dimensions )
 *
 * Create a box to hold cards and tokens
 *
 * sizes      -- Width aand Height of cards, diameter of Marker
 * dimensions -- List of physical dimensions
 */
module deep_card_box( sizes, dimensions=REASONABLE ) {
    inner  = dimensions[INNER];
    bottom = dimensions[BOTTOM];
    width  = sizes[WIDTH];
    height = sizes[HEIGHT];
    marker = sizes[MARKER];
    border = 10 * mm;

    inside = [
        width + 2 * SHIFTING,
        marker + inner + height + 3 * SHIFTING,
        layer_height( marker )
    ];

    mr = (marker + SHIFTING) / 2;   // Marker Radius

    window = [ inside.x-2*border, inside.y-2*border-2*mr-inner, bottom+2*OVERLAP ];

    if (DEBUG_18XX) {
        echo( CardBox=sizes, CardBoxInside=inside );
    }

    difference() {
        union() {
            // Start with a hollow box
            rounded_box( inside, HOLLOW );

            // Add a marker rack
            difference() {
                cube( [inside.x, 2*mr, mr] );
                translate( [0, mr, mr] ) rotate( [0,90,0] ) cylinder( r=mr, h = inside.x, center=false );
            }

            // Add a divider
            translate( [0, 2*mr, 0] ) cube( [inside.x, inner, inside.z] );
        }

        // Remove a finger hole
        translate( [border, inside.y-window.y-border, -bottom-OVERLAP] ) cube( window );
    }
}

/* deep_card_lid( sizes, dimensions )
 *
 * Create a lid for a card box
 *
 * sizes      -- Width aand Height of cards, diameter of Marker
 * dimensions -- List of physical dimensions
 */
module deep_card_lid( sizes, dimensions=REASONABLE ) {
    inner  = dimensions[INNER];
    top    = dimensions[TOP];
    width  = sizes[WIDTH];
    height = sizes[HEIGHT];
    marker = sizes[MARKER];
    border = 10 * mm;

    inside = [
        width + 2 * SHIFTING,
        marker + inner + height + 3 * SHIFTING,
        layer_height( marker )
    ];

    mr = (marker + SHIFTING) / 2;   // Marker Radius

    window = [ inside.x-2*border, inside.y-2*border-2*mr-inner, top+2*OVERLAP ];

    mirror( [0,1,0] ) difference() {
        rounded_lid( inside );
        translate( [border, inside.y-window.y-border, -top-OVERLAP] ) cube( window );
    }
}

/* card_rack( count, slot_depth, width, height )
 *
 * Create a card rack, sized for the share / engine cards
 *
 * count      -- Number of card slots
 * slot_depth -- How thick a stack of cards will fit in a slot
 * width      -- How wide should the rack be (~60% of width of cards)
 * height     -- How tall should the rack be?
 */
module card_rack( count=9, slot_depth=10*CARD_THICKNESS, width=1.5*inch, height=20*mm ) {

    rounding = 2*mm; // radius

    offset = [
        (height - 3*mm) / tan(60) + WALL_WIDTH[6],
        width/2 - CARD_WIDTH/2,
        3*mm
    ];

    dx = slot_depth / sin(60) + WALL_WIDTH[6];

    length = dx*count + offset.x;


    difference() {
        translate( [rounding, rounding, rounding] ) minkowski() {
            cube( [ length-2*rounding, width-2*rounding, height-2*rounding ] );
            sphere( r=rounding );
        }

        // Remove slots for cards
        for (x=[0:1:count-1]) { // Extra slot bevels the front of the rack
            translate( [offset.x+x*dx, offset.y, offset.z] )
                rotate( [0,-30, 0] )
                    cube( [ slot_depth, CARD_WIDTH, CARD_HEIGHT ] );
        }

        // Slope the front of the rack
        translate( [offset.x+count*dx, offset.y, offset.z] ) rotate( [0, -30, 0 ] )
            cube( [3*slot_depth, CARD_WIDTH, CARD_HEIGHT] );
    }
}

// ----- Testing ------------------------------------------------------------------------------------------------------

if (0) {
    CARDS = [ 2.50 * inch, 1.75 * inch, 15*mm ];
    translate( [ 5,  5, 0] ) deep_card_box( CARDS );
    translate( [ 5, -5, 0] ) deep_card_lid( CARDS );
    translate( [-5, -5, 0] ) rotate( [0, 0, 180] ) card_box( CARDS );
    translate( [-5,  5, 0] ) rotate( [0, 0, 180] ) card_lid( CARDS );
}

if (0) {
    VERBOSE = true;

    // Part box dimensions
    PART_WIDTH      = 35.0; // 1.25 * inch;  // X
    PART_DEPTH      = 17.5; // 0.75 * inch;  // Y
    PART_HEIGHT     = 6.00 * mm;    // Z

    px = PART_WIDTH; py = PART_DEPTH;

    PART_CELLS = [
        [ [ px, py ], [ px, py ], [ px, py ] ],
        [ [ px, py ], [ px, py ], [ px, py ] ],
        [ [ px, py ], [ px, py ], [ px, py ] ]
    ];

    TEST_CELLS = [
        [ [ 20, 20 ], [ 30, 20 ], [ 40, 20 ] ],
        [ [ 20, 15 ], [ 30, 15 ], [ 40, 15 ] ],
        [ [ 20, 10 ], [ 30, 10 ], [ 40, 10 ] ]
    ];

    cell_box( PART_CELLS, PART_HEIGHT );
    translate( [0, 70, 0] )
    cell_lid( PART_CELLS, PART_HEIGHT );
}

if (0) {
    box_size = [0,0,6];
    
    translate( [5, 5, 0] ) hex_box_corners( hex_tile_uneven_rows( 2,2 ), box_size, 43, ["ONE"] );
    translate( [5,-5, 0] ) hex_lid_corners( hex_tile_uneven_rows( 2,2 ), box_size, 43, true );
}

if (0) {
    box_size = [0,0,5];
    
    translate( [5, 5, 0] ) hex_box_walls( hex_tile_even_rows( 2,2 ), box_size, 43, ["ONE"] );
    translate( [5,-5, 0] ) hex_lid_walls( hex_tile_even_rows( 2,2 ), box_size, 43, true );
}

if (1) {
    box_size = [9.625 * inch, 11.500 * inch, 12]; // [0,0,11]; // 
    layout = hex_tile_uneven_rows( 7,5 ) ;
    hex_tray_buck( layout, box_size, 44 );
}