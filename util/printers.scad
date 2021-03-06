// 3D-Printers
// by W. Craig Trader
//
// ----------------------------------------------------------------------------
// 
// This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License. 
// To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-sa/4.0/ 
// or send a letter to Creative Commons, PO Box 1866, Mountain View, CA 94042, USA.
//
// ----------------------------------------------------------------------------

include <units.scad>;

// ----- 3D Printer -----------------------------------------------------------

// Layer height is the preferred layer height for your printer / slicer.

LAYER_HEIGHT = 0.20 * mm;

// WALL_WIDTH is an array of extrusion widths for a given number of filament lines, starting at zero (0).
// For my Slicer (PrusaSlicer) I get these from the Print Settings / Layers and perimeters tab.
// Some extrapolation may be necessary.

WALL_WIDTH   = [ 0.00, 0.45, 0.86, 1.26, 1.67, 2.08, 2.49, 2.89, 3.30 ];

GAP       = WALL_WIDTH[1]/2;    // Gap between outer and inner walls for boxes
THIN_WALL = WALL_WIDTH[2];      // 2 perimeters
WIDE_WALL = WALL_WIDTH[4];      // 4 perimeters

OVERLAP      = 0.01 * mm;   // Ensures that there are no vertical artifacts leftover

// ----- Functions -------------------------------------------------------------

function layers( count ) = count * LAYER_HEIGHT;
function layer_height( height ) = ceil( height / LAYER_HEIGHT ) * LAYER_HEIGHT;
