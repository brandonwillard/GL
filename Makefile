.PHONY: all clean %.pdf %.tar.gz FORCE_MAKE

TEX_FILES := $(shell egrep -l '^[^%]*\\begin\{document\}' *.tex)

SRC_DIR = $(abspath ./)
TEX_DIR = $(abspath ./)
DEST_DIR = $(abspath ./output)
FIGURES_DIR = $(abspath ./figures)
BUILD_DIR = $(abspath .build)

PDF_FILES = $(patsubst %.tex, ${DEST_DIR}/%.pdf, ${TEX_FILES})
DEP_FILES = $(patsubst %.tex, ${BUILD_DIR}/%.deps, ${TEX_FILES})
BUNDLE_FILES = $(patsubst %.deps, ${DEST_DIR}/%.tar.gz, $(notdir $(wildcard ${BUILD_DIR}/*.deps)))

# Perhaps we could `cd` into the directory and avoid this `openout_any=a` nonsense.
PDFLATEX_CMD = pdflatex -shell-escape -file-line-error -interaction=nonstopmode

# The `*_line` variables will (hopefully) stop unnecessary linebreaks in
# the pdflatex output--these linebreaks can complicate error message parsing.
LATEXMK_OPTS = max_print_line=1000 error_line=254 half_error_line=238 openout_any=a

TEXINPUTS_EXTRA=${BUILD_DIR}:${TEX_DIR}:${TEX_DIR}/ejpecp:${TEX_DIR}/texmf:${TEX_DIR}/biometrika:${TEXINPUTS}

LATEXMK = TEXINPUTS=${TEXINPUTS_EXTRA} ${LATEXMK_OPTS} latexmk \
          -recorder -pdf -dvi- -ps- -pv- -pvc- -bibtex-cond \
          -pdflatex="${PDFLATEX_CMD} -synctex=1"

all: ${PDF_FILES} ${BUNDLE_FILES}

# Include LaTeX dependencies from a latexmk generated deps file.
# $(foreach file,$(PDF_FILES),$(eval -include $(BUILD_DIR)/$(basename $(file)).mdep))

# Just some convenience targets...
%.pdf: ${DEST_DIR}/%.pdf ;

%.tar.gz: ${DEST_DIR}/%.tar.gz ;

${TEX_DIR}/ejpecp/ejpecp.cls: ${TEX_DIR}/ejpecp/ejpecp.ins ${TEX_DIR}/ejpecp/ejpecp.dtx
	cd ${TEX_DIR}/ejpecp && TEXINPUTS=${TEXINPUTS_EXTRA} $(PDFLATEX_CMD) ejpecp.ins


$(DEST_DIR)/%.pdf: %.tex ${TEX_DIR}/ejpecp/ejpecp.cls FORCE_MAKE
	mkdir -p $(FIGURES_DIR)
	mkdir -p $(BUILD_DIR)
	mkdir -p $(DEST_DIR)
	$(LATEXMK) -jobname=${BUILD_DIR}/$(basename $(@F)) $(realpath $<)
	mv -f ${BUILD_DIR}/$(@F) $@

#
# For this to work, you'll need to include `\RequirePackage{snapshot}%` in
# order to generate the requisite `*.deps` file(s).
#
$(DEST_DIR)/%.tar.gz: %.tex $(BUILD_DIR)/%.deps
	TEXINPUTS=${BUILD_DIR}:${FIGURES_DIR}:./:${TEXINPUTS} \
	          bundledoc \
	          --include="*.bbl" \
	          --texfile=$< \
	          $(filter-out $<,$^)
	mv -f ${BUILD_DIR}/$(@F) $@

clean:
	rm -rf ${BUILD_DIR}
	rm -f *.aux
	rm -rf _minted-*

.PRECIOUS: ${PDF_FILES} ${DEP_FILES}
