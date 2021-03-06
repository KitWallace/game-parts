# 18XX: Organizing trays for tiles and other components
# by W. Craig Trader
#
# --------------------------------------------------------------------------------------------------------------------
#
# This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License.
# To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-sa/4.0/
# or send a letter to Creative Commons, PO Box 1866, Mountain View, CA 94042, USA.
#
# --------------------------------------------------------------------------------------------------------------------
#
# Override PREFIX on the command line to select the parts to produce.
#
#     make all PREFIX=1846
#     make all PREFIX=steam
#
# To list all available prefixes:
#
#     make list
#
# To build all for every model:
#
#     make everything
#
# This makefile expects an OpenSCAD file named $(PREFIX).scad that defines
# the following variables:
#
# PART    -- the name of a part to generate
# VERBOSE -- logically true if you want verbose output (optional)
#
# The OpenSCAD program should have logic that renders a single part by name:
#
# if (PART == "foo") {
#     foo();
# } else if (PART == "bar") {
#     bar();
# } else if (PART == "foo-bar") {
#     foo_bar();
# }
#
# This makefile will use OpenSCAD to create individual model (STL) files and
# image (PNG) files for each declared part
#
# So if PREFIX=widget, then the created files will be:
#
# stl/widget-foo.stl stl/widget-bar.stl stl/widget-foo-bar.stl
# png/widget-foo.png png/widget-bar.png png/widget-foo-bar.png

# ----- Local OpenSCAD settings -----------------------------------------------

TIMESTAMP=$(shell date +"%Y-%M-%dT%H:%m")

# OpenSCAD binary and options
OPENSCAD=/opt/openscad/latest
OPENSCAD_OPTIONS=-DVERBOSE=false -DTIMESTAMP=\"$(TIMESTAMP)\"
IMAGE_OPTIONS=--imgsize=1024,768 --colorscheme=DeepOcean

# ----- Everything after this should not need modification

check_defined = $(strip $(foreach 1,$1, $(call __check_defined,$1,$(strip $(value 2)))))
__check_defined = $(if $(value $1),, $(error Undefined $1$(if $2, ($2))$(if $(value @), required by target `$@')))

# Scripts
EXPAND=../bin/scad-expand.py
DEPEND=../bin/scad-dependencies.py

# Name of all model prefixes
PREFIXES=$(shell ls *.scad | egrep -v 18XX | sed "s/.scad//" | tr "\n" " ")

# directories
BOM=bom
STL=stl
AIO=all-in-one
IMAGE=png

# Names of parts to build
ifneq ($(PREFIX),)
PARTS=$(shell grep 'PART == ' $(PREFIX).scad | cut -d'"' -f2)
SOURCES=$(shell $(DEPEND) $(PREFIX).scad)

BOMS=$(BOM)/$(PREFIX)-bom.md
MODELS=$(patsubst %,$(STL)/$(PREFIX)/$(PREFIX)-%.$(STL),$(PARTS))
IMAGES=$(patsubst %,$(IMAGE)/$(PREFIX)/$(PREFIX)-%.$(IMAGE),$(PARTS))
AIOSCAD=$(AIO)/$(PREFIX)-all-in-one.scad
endif


all:	models images boms aio

everything:
	@for prefix in $(PREFIXES) ; do \
		$(MAKE) PREFIX=$${prefix} all ; \
	done

all-boms:
	@for prefix in $(PREFIXES) ; do \
		$(MAKE) PREFIX=$${prefix} boms ; \
	done

list:
	@fgrep -l "include <18XX.scad>" *.scad | sed "s/.scad//" | \
		while read prefix ; do \
			description=$$(head -1 $${prefix}.scad | sed "s;// ;;") ; \
			printf "%10s => %s\n" $$prefix "$$description" ; \
		done

directories:
	@:$(call check_defined, PREFIX, game prefix)
	@mkdir -p $(STL)/$(PREFIX) $(IMAGE)/$(PREFIX) $(BOM) $(AIO)

models: directories $(MODELS)

images: directories $(IMAGES)

boms:   directories $(BOMS)

aio: directories $(AIOSCAD)

clean:
	@:$(call check_defined, PREFIX, game prefix)
	rm $(STL)/$(PREFIX)/$(PREFIX)-* $(IMAGE)/$(PREFIX)/$(PREFIX)-* $(BOM)/$(PREFIX)-bom.md

cleanall:
	rm -rf $(STL) $(IMAGE) $(BOM)

# Dependencies for BOM
$(BOM)/$(PREFIX)-$(BOM).md : $(PREFIX).scad
	@:$(call check_defined, PREFIX, game prefix)
	@/bin/echo "Creating BOM for $(PREFIX)"
	@/bin/echo "| Model | Qty | Description |" > $@
	@/bin/echo "| ----- | --- | ----------- |" >> $@
	@fgrep '// bom:' $(PREFIX).scad | tr -s '":()/' '|||||' | cut -d '|' -f3,6,7 | sed 's/|/.stl |/;s/^/| $(PREFIX)-/;s/$$/|/' >> $@

# Generate model files
$(MODELS) : $(STL)/$(PREFIX)/$(PREFIX)-%.$(STL) : $(SOURCES)
	@:$(call check_defined, PREFIX, game prefix)
	$(OPENSCAD) $(OPENSCAD_OPTIONS) -o $@ -DPART=\"$(subst $(PREFIX)-,,$(subst .$(STL),,$(@F)))\" $<

# Generate image snapshots
$(IMAGES) : $(IMAGE)/$(PREFIX)/$(PREFIX)-%.$(IMAGE) : $(SOURCES)
	@:$(call check_defined, PREFIX, game prefix)
	$(OPENSCAD) $(OPENSCAD_OPTIONS) -o $@ -DPART=\"$(subst $(PREFIX)-,,$(subst .$(IMAGE),,$(@F)))\" $(IMAGE_OPTIONS) $<

# Generate all-in-one SCAD files
$(AIOSCAD) : $(SOURCES) $(EXPAND)
	@:$(call check_defined, PREFIX, game prefix)
	$(EXPAND) $< $@