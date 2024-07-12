#
# ---=== Ultimate LaTeX astronomy paper/proposal makefile ===---
#
# Run 'make' to compile a LaTeX source and display the reulting PDF with 'okular'
# The Makefile understands 'latex'/'pdflatex' with or without 'bibtex'.
# The Makefile will apply a set of tests aiming to catch common typos, repeated words, 
# check US/British spelling and some aspects of AAS/MNRAS journal style.
#
# The Makefile assumes it is run by GNUmake and relies on external tools including cat, cut, grep, sed, awk, and okular
# 
# The originla version of this Makefile was created by Kirill Sokolovsky <kirx@kirx.net>
#
######################################################################################################
# Manual setttings that modify the makefile behaviour

# Set to "yes" if this is an arXiv sumbission (needs .bbl file) otherwise set "no" (remove .bbl file on cleanup)
#ARXIV=no
ARXIV=yes

# Display the compiled document using okular PDF viewer? (yes/no)
LAUNCH_OKULAR_PDF_VIEWER_TO_DISPLAY_COMPILED_PAPER=yes

COUNT_NUMBER_OF_CHARACTERS_WITH_TEXCOUNT=yes

# Disable some individual tests if needed (yes/no)
TEST_SOFTWARE_TEXTSC=yes
TEST_NONASCII_CHARS=yes

######################################################################################################
# Automated setup: try hard to find the main tex file and recognize its format: PDF figure, BibTeX...
#
# Set *main.tex as the main TeX file, otherwise assume the largest TeX file is the main TeX file
TEXFILE_BASENAME := $(shell if [ -f *main.tex ];then ls *main.tex ;else ls -S *.tex ;fi | head -n1 | sed 's:.tex::g')

PDFTEX := $(shell cat *.tex | cut -f1 -d"%" | grep 'includegr' | grep --quiet -e '.pdf' -e '.png' && echo 'yes' )
BIBTEX := $(shell cat *.tex | cut -f1 -d"%" | grep --quiet 'bibliographystyle' && echo 'yes' )

BIBFILENAME := $(shell cat *.tex | cut -f1 -d"%" | grep 'bibliography{' | head -n1 | awk -F'bibliography{' '{print $$2}' | awk -F'}' '{print $$1".bib"}')

MODIFY_BIBFILE_ULTRACOMPACT_REF := $(shell cat *.tex | cut -f1 -d"%" | grep --quiet -e 'bibliographystyle.mnras_shortlisthack' -e 'bibliographystyle.supershort_numbers_oneline' && echo 'yes' )

MNRAS_MANUSCRIPT_REQUIRING_BRITISH_SPELLING := $(shell cat *.tex | cut -f1 -d"%" | grep 'documentclass' | grep --quiet 'mnras' && echo 'yes' )

AAS_MANUSCRIPT_REQUIRING_US_SPELLING := $(shell cat *.tex | cut -f1 -d"%" | grep 'documentclass' | grep --quiet 'aastex' && echo 'yes' )

ANY_KNOWN_SOFTWARE_MENTIONED := $(shell cat *.tex | cut -f1 -d"%" | grep --quiet -e 'IRAF' -e 'MIDAS' -e 'AIPS' -e 'CASA' -e 'DS9' -e 'ds9' -e 'VaST' -e 'HEASoft' -e 'HEASOFT' -e 'HEAsoft' -e 'Fermitools' -e 'Difmap' -e 'difmap' -e 'DiFx' -e 'SExtractor' -e 'sextractor' -e 'PSFEx' -e 'psfex' && echo 'yes' )

IS_SWIFT_UVOT_MENTIONED := $(shell cat *.tex | cut -f1 -d"%" | grep --quiet -e 'Swift' && cat *.tex | cut -f1 -d"%" | grep --quiet -e 'UVOT' && echo 'yes' )


all: info clean check_utf8 check_spell check_no_whitespace check_coma_instead_of_period check_extra_white_space try_to_find_duplicate_words shorten_journal_names_bib check_british_spelling check_us_spelling check_gamma_ray_math_mode check_software_small_capitals check_swift_uvot_lowercase_filternames check_units check_consistent_unbreakable_space_size_UT check_phrasing check_filenames_good_for_arXiv  $(TEXFILE_BASENAME).pdf  check_for_bonus_figures display_compiled_pdf


info: $(TEXFILE_BASENAME).tex
	@echo "Starting the ultimate LaTeX Makefile"
	@echo "TEXFILE_BASENAME= "$(TEXFILE_BASENAME)
ifeq ($(BIBTEX),yes)
	@echo "BIBFILENAME= "$(BIBFILENAME)
else
	@echo "No BibTeX, fine"
endif

clean: 
ifeq ($(ARXIV),yes)
	# do not remove .bbl file for arXiv submission
	rm -f $(TEXFILE_BASENAME).pdf $(TEXFILE_BASENAME).ps $(TEXFILE_BASENAME).dvi $(TEXFILE_BASENAME).log $(TEXFILE_BASENAME).aux $(TEXFILE_BASENAME).blg DEADJOE *~ *.bak main_paper.pdf online_material.pdf $(TEXFILE_BASENAME).out $(TEXFILE_BASENAME).teximulated mn2e.bst_backup missfont.log *~
else
	# remove .bbl file and everything else
	rm -f $(TEXFILE_BASENAME).bbl  $(TEXFILE_BASENAME).pdf $(TEXFILE_BASENAME).ps $(TEXFILE_BASENAME).dvi $(TEXFILE_BASENAME).log $(TEXFILE_BASENAME).aux $(TEXFILE_BASENAME).blg DEADJOE *~ *.bak main_paper.pdf online_material.pdf $(TEXFILE_BASENAME).out $(TEXFILE_BASENAME).teximulated mn2e.bst_backup missfont.log *~
endif

check_utf8: $(TEXFILE_BASENAME).tex
ifeq ($(TEST_NONASCII_CHARS),yes)
	#
	# Display any non-ASCII UTF8 characters higlighting them with color.
	# (If this check fails, but you see no color in the output -
	# the non-ASCII character is masquerading as white space and
	# you may need to select text with mouse to see the offending character.)
	#
	@echo "Searching for non-ASCII characters in TeX file"
	{ LC_ALL=C grep --color=always '[^ -~]\+' *.tex && exit 1 || true; }
	#{ LC_ALL=C grep --color=always '[^ -~]\+' $(TEXFILE_BASENAME).tex && exit 1 || true; }
	# Check that the TeX file type is not Unicode - but that may miss some stray Unicode character
	file *.tex | { grep -e 'Unicode' -e 'ISO-8859' && exit 1 || true; }
	#file $(TEXFILE_BASENAME).tex | { grep Unicode && exit 1 || true; }
ifeq ($(BIBTEX),yes)
	@echo "Searching for non-ASCII characters in BibTeX file"
	{ LC_ALL=C grep --color=always '[^ -~]\+' $(BIBFILENAME) && echo 'ERROR: Unicode character in .bib file' && exit 1 || true; }
endif
endif


check_spell: $(TEXFILE_BASENAME).tex
	# Case-insensitive search
	# sed 's/[^ ]*.eps[^ ]*//ig'   is to make sure figure filenames are ignored
	cat *.tex | sed 's:the A config::g' | sed 's:binary tree::g' | sed 's/[^ ]*.eps[^ ]*//ig' | { grep --color=always --ignore-case -e 'compliment' -e 'complimented' -e 'ile up' -e 'ile~up' -e '\bcan will\b' -e '\bmay can\b' -e '\bmay will\b' -e '\ba the\b' -e '\bthe a\b' -e '\bwhited\b' -e '\bneutrons star\b' -e '\bhotpot\b' -e '\brang\b' -e 'has be seen' -e 'synchroton' -e '\bhight\b' -e 'far from being settled' -e 'recourses' -e '\bwile\b' -e 'will allows' -e '\btree\b' -e '\ban new\b' && exit 1 || true; }
	# Case-sensitive search
	cat *.tex | sed 's:the A config::g' | { grep --color=always -e 'x-ray' -e ' tp ' && exit 1 || true; }
	#
	cat *.tex | cut -f1 -d"%" | sed -ie 's/\\[A-Za-z0-9]* / /g' | { grep --color=always 'countrate' && echo "SHOULD BE count rate" && exit 1 || true; }
	# Use \b to match on "word boundaries", which will make your search match on whole words only.
	cat *.tex | cut -f1 -d"%" | { grep --color=always '\bgenue\b' && echo "SHOULD BE genuine" && exit 1 || true; }
	#
	cat *.tex | cut -f1 -d"%" | { grep --color=always '\bTHe\b' && echo "SHOULD BE the" && exit 1 || true; }
	#
	cat *.tex | cut -f1 -d"%" | { grep --color=always --ignore-case 'maid' && echo "DID YOU MEAN made ?" && exit 1 || true; }
	# 'substraction' is a rare synonym for 'embezzlement' https://www.merriam-webster.com/dictionary/substraction
	cat *.tex | cut -f1 -d"%" | { grep --color=always --ignore-case 'substraction' && echo "DID YOU MEAN subtraction ?" && exit 1 || true; }
	# and the all-time classic
	cat *.tex | cut -f1 -d"%" | { grep --color=always --ignore-case 'redshit' && echo "DID YOU MEAN redshift ?" && exit 1 || true; }
	# 'common-envelop' is not your ordinary package for a letter
	cat *.tex | cut -f1 -d"%" | { grep --color=always --ignore-case '\bcommon-envelop\b' && echo "DID YOU MEAN common-envelope ?" && exit 1 || true; }
	# ' on Fig'
	cat *.tex | cut -f1 -d"%" | { grep --color=always --ignore-case '\bon Fig' && echo "DID YOU MEAN in Fig... ?" && exit 1 || true; }
	#
	# 'number if'
	cat *.tex | cut -f1 -d"%" | { grep --color=always --ignore-case '\bnumber if\b' && echo "DID YOU MEAN number of ?" && exit 1 || true; }
	# novae instead of novas, unless it looks like software name 'NOVAS' - a popular astrometry library
	cat *.tex | cut -f1 -d"%" | sed -e 's/textsc{[^{}]*}//g' | sed -e 's/texttt{[^{}]*}//g' | sed -e 's/url{[^{}]*}//g' | { grep --color=always '\bnovas\b' && echo "DID YOU MEAN novae ?" && exit 1 || true; }
	#
	
check_no_whitespace: $(TEXFILE_BASENAME).tex
	#  cut -f1 -d"%" -- ignore everything after %
	#  sed -e 's/\[[^][]*\]//g' -- ignore everything between []
	#  sed -e 's/{[^{}]*}//g'   -- ignore everything between {}
	#
	# period      sed 's:[A-Z].[A-Z].::g' will allow for two capital letter combinations like initials K.S.
	cat *.tex | cut -f1 -d"%" | sed -e 's/{[^{}]*}//g' | sed -e 's/{[^{}]*}//g' | sed -e 's/\[[^][]*\]//g' | sed -e 's/\[[^][]*\]//g' | sed 's:R.A.::g' | sed 's:L.A.Cosmic::g' | sed 's:\\.M::g' | sed 's:Obs.ID::g' | sed 's:U.S.::g' | sed 's:H.E.S.S.::g' | sed 's:J.D.L.::g' | sed 's:K.V.S.::g' | sed 's:E.A.::g' | sed 's:Ras.Pi::g' | sed 's:Ph.D.::g' | sed 's:P.O.::g' | sed 's:[A-Z].[A-Z].[A-Z].::g'  | sed 's:[A-Z].[A-Z].::g' | { grep --color=always -e '\.[A-Z]' && exit 1 || true; }
	# two periods
	# sed -e 's/\.\.\.//g' -- allow for three periods 
	# sed -e 's/\.\.\///g' -- allow for '../' as in file path
	cat *.tex | cut -f1 -d"%" | sed -e 's/{[^{}]*}//g' | sed -e 's/{[^{}]*}//g' | sed -e 's/\[[^][]*\]//g' | sed -e 's/\[[^][]*\]//g' | sed -e 's/\.\.\.//g' | sed -e 's/\.\.\///g' | { grep --color=always -e '\.\.' && exit 1 || true; }
	# coma periods;   sed 's:\\,::g' -- remove unbreakable half-spaces from the test
	#cat $(TEXFILE_BASENAME).tex | cut -f1 -d"%" | sed -e 's/{[^{}]*}//g' | sed -e 's/{[^{}]*}//g' | sed -e 's/\[[^][]*\]//g' | sed -e 's/\[[^][]*\]//g' | sed 's:\\,::g' | { grep --color=always -e '\,\.' && exit 1 || true; }
	cat *.tex | cut -f1 -d"%" | sed -e 's/{[^{}]*}//g' | sed -e 's/{[^{}]*}//g' | sed -e 's/\[[^][]*\]//g' | sed -e 's/\[[^][]*\]//g' | sed 's:\\,::g' | { grep --color=always -e ',\.' && exit 1 || true; }
	# some journal styles allow ".," combination: "e.g.,"
	#cat $(TEXFILE_BASENAME).tex | cut -f1 -d"%" | sed -e 's/{[^{}]*}//g' | sed -e 's/{[^{}]*}//g' | sed -e 's/\[[^][]*\]//g' | sed -e 's/\[[^][]*\]//g' | { grep --color=always -e '\.\,' && exit 1 || true; }
	# two comas;   sed 's:\\,::g' -- remove unbreakable half-spaces from the test
	#cat $(TEXFILE_BASENAME).tex | cut -f1 -d"%" | sed -e 's/{[^{}]*}//g' | sed -e 's/{[^{}]*}//g' | sed -e 's/\[[^][]*\]//g' | sed -e 's/\[[^][]*\]//g' | sed 's:\\,::g' | { grep --color=always -e '\,\,' && exit 1 || true; }
	cat *.tex | cut -f1 -d"%" | sed -e 's/{[^{}]*}//g' | sed -e 's/{[^{}]*}//g' | sed -e 's/\[[^][]*\]//g' | sed -e 's/\[[^][]*\]//g' | sed 's:\\,::g' | { grep --color=always -e ',,' && exit 1 || true; }
	#
	# White space between Fig. and ref
	cat *.tex | { grep --color=always 'Fig \\ref' && echo "SHOULD BE Fig.~\\ref{}" && exit 1 || true; }
	cat *.tex | { grep --color=always 'Figs \\ref' && echo "SHOULD BE Figs.~\\ref{}" && exit 1 || true; }
	cat *.tex | { grep --color=always 'Fig\, \\ref' && echo "SHOULD BE Fig.~\\ref{}" && exit 1 || true; }
	cat *.tex | { grep --color=always 'Figs\. \\ref' && echo "SHOULD BE Figs.~\\ref{}" && exit 1 || true; }
	cat *.tex | { grep --color=always 'Fig\.\\ref' && echo "SHOULD BE Fig.~\\ref{}" && exit 1 || true; }
	cat *.tex | { grep --color=always 'Figs\.\\ref' && echo "SHOULD BE Figs.~\\ref{}" && exit 1 || true; }
	cat *.tex | { grep --color=always 'Fig\\ref' && echo "SHOULD BE Fig.~\\ref{}" && exit 1 || true; }
	cat *.tex | { grep --color=always 'Figs\\ref' && echo "SHOULD BE Figs.~\\ref{}" && exit 1 || true; }
	cat *.tex | { grep --color=always 'Fig~\\ref' && echo "SHOULD BE Fig.~\\ref{}" && exit 1 || true; }
	cat *.tex | { grep --color=always 'Figs~\\ref' && echo "SHOULD BE Figs.~\\ref{}" && exit 1 || true; }
	cat *.tex | { grep --color=always 'Figure\\ref' && echo "SHOULD BE Figure~\\ref{}" && exit 1 || true; }
	cat *.tex | { grep --color=always 'Figures\\ref' && echo "SHOULD BE Figures~\\ref{}" && exit 1 || true; }
	cat *.tex | { grep --color=always 'Figure \\ref' && echo "SHOULD BE Figure~\\ref{}" && exit 1 || true; }
	cat *.tex | { grep --color=always 'Figures \\ref' && echo "SHOULD BE Figures~\\ref{}" && exit 1 || true; }
	# White space before \cite
	cat *.tex | sed 's:\\protect\\citeauthoryear::g' | sed 's:\\protect\\citename::g' | { grep --color=always '[a-z]\\cite' && echo "NO WHITE SPACE BEFORE \\cite" && exit 1 || true; }

check_extra_white_space: $(TEXFILE_BASENAME).tex
	cat *.tex | cut -f1 -d"%" | grep -v -e '\.\.\/' -e ' \.\/' | { grep --color=always ' \.' && exit 1 || true; }
	cat *.tex | { grep --color=always ' \,' && exit 1 || true; }

check_coma_instead_of_period: $(TEXFILE_BASENAME).tex
	cat *.tex | cut -f1 -d"%" | sed -e 's/{[^{}]*}//g' | sed -e 's/{[^{}]*}//g' | sed -e 's/\[[^][]*\]//g' | sed -e 's/\[[^][]*\]//g' | grep -v -e 'Uni' -e 'Obs' -e 'Inst' -e 'The Netherlands' -e 'The United' | { grep --color=always -e '\,The' -e '\, The' && exit 1 || true; }

check_units: $(TEXFILE_BASENAME).tex
	cat *.tex | cut -f1 -d"%" | sed -e 's/{[^{}]*}//g' | sed -e 's/{[^{}]*}//g' | sed -e 's/\[[^][]*\]//g' | sed -e 's/\[[^][]*\]//g' | { grep --color=always '\bhr\b' && echo "SHOULD BE h ACCORDING TO IAU RECOMMENDATIONS ON UNITS https://www.iau.org/publications/proceedings_rules/units/" && exit 1 || true; }

check_phrasing: $(TEXFILE_BASENAME).tex
	cat *.tex | sed 's:\\it : :g' | sed 's:\\em : :g' | sed 's:\\bf : :g' | sed 's/%.*$$//' | sed '/^[[:space:]]*$$/d' | awk 'BEGIN{getline l;} {combined=l " " $$0; printf(" %.5d - %.5d: %s\n",FNR-1,FNR, combined); l=$$0;}' | grep -v 'tabular' | sed 's:caption{::g' | sed 's:captionbox{::g' | sed -e 's/{[^{}]*}//g' | sed -e 's/{[^{}]*}//g' | sed -e 's/\[[^][]*\]//g' | sed -e 's/\[[^][]*\]//g' | { grep --color=always -e '\ballow one to identify\b' -e '\ballow to identify\b' && echo "SHOULD BE allow the identification of" && exit 1 || true; }

try_to_find_duplicate_words: $(TEXFILE_BASENAME).tex
	#
	# Checking for repeated words over linebreaks
	# We do not exclude comments, so line numbers will be correct
	# sed -n '/filecontents/,/filecontents/!p'  -- ignore everything between these lines (it's an embedded file)
	# grep -v ' \-\-[A-Za-z]'    -- remove command line arguments examples
	#                   ' & '    -- ignore tables that may well have duplicate words/numbers
	cat *.tex | grep -v -e ' \--[A-Za-z]' -e ' & ' | cut -f1 -d"%" | sed -n '/filecontents/,/filecontents/!p' | sed 's:\\it : :g' | sed 's:\\em : :g' | sed 's:\\bf : :g' | awk 'BEGIN{getline l;} {combined=l " " $$0; printf(" %.5d - %.5d: %s\n",FNR-1,FNR, combined); l=$$0;}' | grep -v 'tabular' | sed 's:caption{::g' | sed 's:captionbox{::g' | sed -e 's/{[^{}]*}//g' | sed -e 's/{[^{}]*}//g' | sed -e 's/\[[^][]*\]//g' | sed -e 's/\[[^][]*\]//g' | { grep -Ei --color  "\b(\w+)\b\s*\1\b" && exit 1 || true; }
	#  sed 's/%.*$//'    -- remove everything after %
	#  sed '/^[[:space:]]*$/d' -- remoove empty lines
	# The output line nubers may not be exact as we skip comment lines
	# sed -n '/filecontents/,/filecontents/!p'  -- ignore everything between these lines (it's an embedded file)
	cat *.tex | grep -v -e ' \--[A-Za-z]' -e ' & ' | cut -f1 -d"%" | sed -n '/filecontents/,/filecontents/!p' | sed 's:\\it : :g' | sed 's:\\em : :g' | sed 's:\\bf : :g' | sed 's/%.*$$//' | sed '/^[[:space:]]*$$/d' | awk 'BEGIN{getline l;} {combined=l " " $$0; printf(" %.5d - %.5d: %s\n",FNR-1,FNR, combined); l=$$0;}' | grep -v 'tabular' | sed 's:caption{::g' | sed 's:captionbox{::g' | sed -e 's/{[^{}]*}//g' | sed -e 's/{[^{}]*}//g' | sed -e 's/\[[^][]*\]//g' | sed -e 's/\[[^][]*\]//g' | { grep -Ei --color  "\b(\w+)\b\s*\1\b" && exit 1 || true; }
	#
	# Catch word repeats in one line (obsolete)
	# The old version that doesn't catch everything
	# sed -n '/filecontents/,/filecontents/!p'  -- ignore everything between these lines (it's an embedded file)
	#cat $(TEXFILE_BASENAME).tex | sed -n '/filecontents/,/filecontents/!p' | sed 's:\\it : :g' | grep -v -E '[0-9]cm' | grep -v -E '[0-9]in' | grep -v -e '&' -e 'textwidth' -e 'includegraphicx' -e 'includegraphics' -e 'tabular' | { egrep "(\b[a-zA-Z]+) \1\b"  && exit 1 || true; }
	# The new experimental version
	#  sed -e 's/\[[^][]*\]//g' -- ignore everything between []
	#  sed -e 's/{[^{}]*}//g'   -- ignore everything between {}
	# mess 'caption{}' and 'captionbox{}' as we still want to check for repeated words in captions
	# sed -n '/filecontents/,/filecontents/!p'  -- ignore everything between these lines (it's an embedded file)
	cat *.tex | grep -v -e ' \--' -e ' & ' | sed -n '/filecontents/,/filecontents/!p' | sed 's:\\it : :g' | sed 's:\\em : :g' | sed 's:\\bf : :g' | grep -v 'tabular' | sed 's:caption{::g' | sed 's:captionbox{::g' | sed -e 's/{[^{}]*}//g' | sed -e 's/{[^{}]*}//g' | sed -e 's/\[[^][]*\]//g' | sed -e 's/\[[^][]*\]//g' | { grep -Ein --color  "\b(\w+)\b\s*\1\b" && exit 1 || true; }
	# Last-trench effort -- just grep for the most common repetitions
	cat *.tex | { grep --color=always -e ' the the ' -e ' a the ' && exit 1 || true; }
	#
	#######################
	# sed 's/[[:blank:]]\+/ /g' - replace multiple white spaces with one white space
	# Search for suspicious word combinations
	cat *.tex | sed 's:\\it : :g' | sed 's:\\em : :g' | sed 's:\\bf : :g' | sed 's/%.*$$//' | sed '/^[[:space:]]*$$/d' | awk 'BEGIN{getline l;} {combined=l " " $$0; printf(" %.5d - %.5d: %s\n",FNR-1,FNR, combined); l=$$0;}' | grep -v 'tabular' | sed 's:caption{::g' | sed 's:captionbox{::g' | sed -e 's/{[^{}]*}//g' | sed -e 's/{[^{}]*}//g' | sed -e 's/\[[^][]*\]//g' | sed -e 's/\[[^][]*\]//g' | sed 's/[[:blank:]]\+/ /g' | { grep --color=always  "\bare know\b" && exit 1 || true; }
	cat *.tex | sed 's:\\it : :g' | sed 's:\\em : :g' | sed 's:\\bf : :g' | sed 's/%.*$$//' | sed '/^[[:space:]]*$$/d' | awk 'BEGIN{getline l;} {combined=l " " $$0; printf(" %.5d - %.5d: %s\n",FNR-1,FNR, combined); l=$$0;}' | grep -v 'tabular' | sed 's:caption{::g' | sed 's:captionbox{::g' | sed -e 's/{[^{}]*}//g' | sed -e 's/{[^{}]*}//g' | sed -e 's/\[[^][]*\]//g' | sed -e 's/\[[^][]*\]//g' | sed 's/[[:blank:]]\+/ /g' | { grep --color=always -e "\bmission line\b" -e "\bmission lines\b" && exit 1 || true; }
	cat *.tex | sed 's:\\it : :g' | sed 's:\\em : :g' | sed 's:\\bf : :g' | sed 's/%.*$$//' | sed '/^[[:space:]]*$$/d' | awk 'BEGIN{getline l;} {combined=l " " $$0; printf(" %.5d - %.5d: %s\n",FNR-1,FNR, combined); l=$$0;}' | grep -v 'tabular' | sed 's:caption{::g' | sed 's:captionbox{::g' | sed -e 's/{[^{}]*}//g' | sed -e 's/{[^{}]*}//g' | sed -e 's/\[[^][]*\]//g' | sed -e 's/\[[^][]*\]//g' | sed 's/[[:blank:]]\+/ /g' | { grep --color=always "\bwill be also be\b" && exit 1 || true; }
	cat *.tex | sed 's:\\it : :g' | sed 's:\\em : :g' | sed 's:\\bf : :g' | sed 's/%.*$$//' | sed '/^[[:space:]]*$$/d' | awk 'BEGIN{getline l;} {combined=l " " $$0; printf(" %.5d - %.5d: %s\n",FNR-1,FNR, combined); l=$$0;}' | grep -v 'tabular' | sed 's:caption{::g' | sed 's:captionbox{::g' | sed -e 's/{[^{}]*}//g' | sed -e 's/{[^{}]*}//g' | sed -e 's/\[[^][]*\]//g' | sed -e 's/\[[^][]*\]//g' | sed 's/[[:blank:]]\+/ /g' | { grep --color=always "\bdivided my the\b" && exit 1 || true; }
	cat *.tex | sed 's:\\it : :g' | sed 's:\\em : :g' | sed 's:\\bf : :g' | sed 's/%.*$$//' | sed '/^[[:space:]]*$$/d' | awk 'BEGIN{getline l;} {combined=l " " $$0; printf(" %.5d - %.5d: %s\n",FNR-1,FNR, combined); l=$$0;}' | grep -v 'tabular' | sed 's:caption{::g' | sed 's:captionbox{::g' | sed -e 's/{[^{}]*}//g' | sed -e 's/{[^{}]*}//g' | sed -e 's/\[[^][]*\]//g' | sed -e 's/\[[^][]*\]//g' | sed 's/[[:blank:]]\+/ /g' | { grep --color=always "\bthe on\b" && exit 1 || true; }
	# "the were" -> "they were"
	#cat *.tex | sed 's/%.*$$//' | sed '/^[[:space:]]*$$/d' | awk 'BEGIN{getline l;} {combined=l " " $$0; printf(" %.5d - %.5d: %s\n",FNR-1,FNR, combined); l=$$0;}' | sed 's/[[:blank:]]\+/ /g' | { grep --color=always --ignore-case '\bthe were\b' && echo "DID YOU MEAN they were ?" && exit 1 || true; }
	cat *.tex | sed '/^[[:space:]]*$$/d' | awk 'BEGIN{getline l;} {combined=l " " $$0; printf(" %.5d - %.5d: %s\n",FNR-1,FNR, combined); l=$$0;}' | sed 's/[[:blank:]]\+/ /g' | { grep --color=always --ignore-case '\bthe were\b' && echo "DID YOU MEAN they were ?" && exit 1 || true; }
	# "Through this paper" -> "Throughout this paper"
	#cat *.tex | sed 's/%.*$$//' | sed '/^[[:space:]]*$$/d' | awk 'BEGIN{getline l;} {combined=l " " $$0; printf(" %.5d - %.5d: %s\n",FNR-1,FNR, combined); l=$$0;}' | sed 's/[[:blank:]]\+/ /g' | { grep --color=always --ignore-case '\bThrough this paper\b' && echo "DID YOU MEAN throughout this paper ?" && exit 1 || true; }
	cat *.tex | sed '/^[[:space:]]*$$/d' | awk 'BEGIN{getline l;} {combined=l " " $$0; printf(" %.5d - %.5d: %s\n",FNR-1,FNR, combined); l=$$0;}' | sed 's/[[:blank:]]\+/ /g' | { grep --color=always --ignore-case '\bThrough this paper\b' && echo "DID YOU MEAN throughout this paper ?" && exit 1 || true; }
	# "in order to not" -> "in order not to"
	#cat *.tex | sed 's/%.*$$//' | sed '/^[[:space:]]*$$/d' | awk 'BEGIN{getline l;} {combined=l " " $$0; printf(" %.5d - %.5d: %s\n",FNR-1,FNR, combined); l=$$0;}' | sed 's/[[:blank:]]\+/ /g' | { grep --color=always --ignore-case '\bin order to not\b' && echo "DID YOU MEAN in order not to ?" && exit 1 || true; }	
	cat *.tex | sed '/^[[:space:]]*$$/d' | awk 'BEGIN{getline l;} {combined=l " " $$0; printf(" %.5d - %.5d: %s\n",FNR-1,FNR, combined); l=$$0;}' | sed 's/[[:blank:]]\+/ /g' | { grep --color=always --ignore-case '\bin order to not\b' && echo "DID YOU MEAN in order not to ?" && exit 1 || true; }	
	# two version -> two versions
	#cat *.tex | sed 's/%.*$$//' | sed '/^[[:space:]]*$$/d' | awk 'BEGIN{getline l;} {combined=l " " $$0; printf(" %.5d - %.5d: %s\n",FNR-1,FNR, combined); l=$$0;}' | sed 's/[[:blank:]]\+/ /g' | { grep --color=always --ignore-case -e '\btwo version\b' -e '\bthree version\b' -e '\bfour version\b' -e '\bfive version\b' -e '\bsix version\b' -e '\bseven version\b' -e '\beight version\b' -e '\bnine version\b' -e '\bten version\b' -e '\beleven version\b' -e '\btwleve version\b' && echo "DID YOU MEAN versions ?" && exit 1 || true; }	
	cat *.tex | sed '/^[[:space:]]*$$/d' | awk 'BEGIN{getline l;} {combined=l " " $$0; printf(" %.5d - %.5d: %s\n",FNR-1,FNR, combined); l=$$0;}' | sed 's/[[:blank:]]\+/ /g' | { grep --color=always --ignore-case -e '\btwo version\b' -e '\bthree version\b' -e '\bfour version\b' -e '\bfive version\b' -e '\bsix version\b' -e '\bseven version\b' -e '\beight version\b' -e '\bnine version\b' -e '\bten version\b' -e '\beleven version\b' -e '\btwleve version\b' && echo "DID YOU MEAN versions ?" && exit 1 || true; }	
	# minor and minor axes
	#cat *.tex | sed 's/%.*$$//' | sed '/^[[:space:]]*$$/d' | awk 'BEGIN{getline l;} {combined=l " " $$0; printf(" %.5d - %.5d: %s\n",FNR-1,FNR, combined); l=$$0;}' | sed 's/[[:blank:]]\+/ /g' | { grep --color=always --ignore-case 'minor and minor axes' && echo "DID YOU MEAN major and minor axes ?" && exit 1 || true; }	
	cat *.tex | sed '/^[[:space:]]*$$/d' | awk 'BEGIN{getline l;} {combined=l " " $$0; printf(" %.5d - %.5d: %s\n",FNR-1,FNR, combined); l=$$0;}' | sed 's/[[:blank:]]\+/ /g' | { grep --color=always --ignore-case 'minor and minor axes' && echo "DID YOU MEAN major and minor axes ?" && exit 1 || true; }	
	
	
# This hack will modify the .bib file replacing some long journal names if we are using mnras_shortlisthack.bst style
shorten_journal_names_bib: $(BIBFILENAME)
ifeq ($(MODIFY_BIBFILE_ULTRACOMPACT_REF),yes)
	# Modify .bib
	@echo "I WILL RUIN THE BIBFILE"
	echo $(MODIFY_BIBFILE_ULTRACOMPACT_REF)
	# If the bibfile looks unmodified, save a backup copy
	cat $(BIBFILENAME) | { grep -e '{ATel}' -e '{RNAAS}' -e '{AN}' || cp -v $(BIBFILENAME) $(BIBFILENAME)_backup_long_journal_names ; }
	# Do the actual modification
	cat $(BIBFILENAME) | sed 's:{The Astronomer.s Telegram}:{ATel}:g' | sed 's:{Research Notes of the American Astronomical Society}:{RNAAS}:g' | sed 's:{Astronomische Nachrichten}:{AN}:g' > $(BIBFILENAME)_tmp && mv -v $(BIBFILENAME)_tmp $(BIBFILENAME)
else
	# Nothing to do
	@echo "KEEP THE ORIGINAL BIBFILE"
	echo $(MODIFY_BIBFILE_ULTRACOMPACT_REF)
endif

check_british_spelling:
ifeq ($(MNRAS_MANUSCRIPT_REQUIRING_BRITISH_SPELLING),yes)
	# Check for British spelling
	# MNRAS style guide https://academic.oup.com/mnras/pages/General_Instructions#6%20Style%20guide
	cat *.tex | cut -f1 -d"%" | grep -v '$^{' | grep -v '\\center' | { grep --color=always 'centered' && echo "SHOULD BE centred" && exit 1 || true; }
	cat *.tex | cut -f1 -d"%" | grep -v '$^{' | grep -v '\\center' | { grep --color=always 'center' && echo "SHOULD BE centre" && exit 1 || true; }
	cat *.tex | cut -f1 -d"%" | { grep --color=always --ignore-case 'sulfur' && echo "SHOULD BE sulphur" && exit 1 || true; }
	cat *.tex | cut -f1 -d"%" | { grep --color=always --ignore-case 'labeled' && echo "SHOULD BE labelled" && exit 1 || true; }
	#
	cat *.tex | cut -f1 -d"%" | { grep --color=always --ignore-case 'analyze' && echo "SHOULD BE analyse" && exit 1 || true; }
	cat *.tex | cut -f1 -d"%" | { grep --color=always --ignore-case 'parametrise' && echo "SHOULD BE parametrize" && exit 1 || true; }
	#
	cat *.tex | cut -f1 -d"%" | { grep --color=always --ignore-case 'acknowledgments' && echo "SHOULD BE acknowledgements" && exit 1 || true; }
	#
	cat *.tex | cut -f1 -d"%" | { grep --color=always --ignore-case 'artifact' && echo "SHOULD BE artefact" && exit 1 || true; }
	cat *.tex | cut -f1 -d"%" | { grep --color=always --ignore-case 'best-fit ' && echo "SHOULD BE best-fitting" && exit 1 || true; }
	cat *.tex | cut -f1 -d"%" | { grep --color=always --ignore-case 'disk' && echo "SHOULD BE disc" && exit 1 || true; }
	cat *.tex | cut -f1 -d"%" | { grep --color=always --ignore-case 'halos' && echo "SHOULD BE haloes" && exit 1 || true; }
	cat *.tex | cut -f1 -d"%" | { grep --color=always --ignore-case 'hot-spot' && echo "SHOULD BE hotspot" && exit 1 || true; }
	cat *.tex | cut -f1 -d"%" | { grep --color=always --ignore-case 'nonlinear' && echo "SHOULD BE non-linear" && exit 1 || true; }
	cat *.tex | cut -f1 -d"%" | { grep --color=always --ignore-case ' onto ' && echo "SHOULD BE on to" && exit 1 || true; }
	cat *.tex | cut -f1 -d"%" | { grep --color=always --ignore-case 'timescale' && echo "SHOULD BE time-scale" && exit 1 || true; }
	# random collection of astronomy-specific words
	cat *.tex | cut -f1 -d"%" | { grep --color=always --ignore-case 'barycenter' && echo "SHOULD BE barycentre" && exit 1 || true; }
	# random collection of words
	# sed 's/\\[^~]*{//g'  will remove \textcolor{
	cat *.tex | cut -f1 -d"%" | sed 's/\\[^~]*{//g' | grep -v -e 'xcolor' -e 'rgbcolor' | { grep --color=always --ignore-case 'color' && echo "SHOULD BE colour" && exit 1 || true; }
	cat *.tex | cut -f1 -d"%" | { grep --color=always --ignore-case 'flavor' && echo "SHOULD BE flavour" && exit 1 || true; }
	cat *.tex | cut -f1 -d"%" | { grep --color=always --ignore-case 'humor' && echo "SHOULD BE humour" && exit 1 || true; }
	# Use \b to match on "word boundaries", which will make your search match on whole words only.
	cat *.tex | cut -f1 -d"%" | sed 's:laborator::g' | sed 's:ollaboration::g' | grep -v '$^{' | { grep --color=always '\blabor\b' && echo "SHOULD BE labour" && exit 1 || true; }
	cat *.tex | cut -f1 -d"%" | { grep --color=always --ignore-case 'neighbor' && echo "SHOULD BE neighbour" && exit 1 || true; }
	cat *.tex | cut -f1 -d"%" | { grep --color=always --ignore-case 'paralyze' && echo "SHOULD BE paralyse" && exit 1 || true; }
	cat *.tex | cut -f1 -d"%" | sed 's:talogue::g' | { grep --color=always --ignore-case 'catalog' && echo "SHOULD BE catalogue" && exit 1 || true; }
	cat *.tex | cut -f1 -d"%" | { grep --color=always --ignore-case '\banalog\b' && echo "SHOULD BE analogue" && exit 1 || true; }
	cat *.tex | cut -f1 -d"%" | { grep --color=always --ignore-case 'centimeter' && echo "SHOULD BE centimetre" && exit 1 || true; }
	#
	cat *.tex | cut -f1 -d"%" | { grep --color=always --ignore-case 'modeling' && echo "SHOULD BE modelling" && exit 1 || true; }
	# Other MNRAS things
	# https://academic.oup.com/mnras/pages/general_instructions#6.5%20Miscellaneous%20journal%20style
	cat *.tex | { grep --color=always --ignore-case -e '\\%' -e 'percent' && echo "SHOULD BE per cent" && exit 1 || true; }
	cat *.tex | cut -f1 -d"%" | { grep --color=always --ignore-case -e '~sec ' -e ' sec ' -e '\\,sec' && echo "SHOULD BE s" && exit 1 || true; }
	cat *.tex | cut -f1 -d"%" | { grep --color=always --ignore-case 'e\.g\.\,' && echo "SHOULD BE e.g." && exit 1 || true; }
	cat *.tex | cut -f1 -d"%" | { grep --color=always --ignore-case 'i\.e\.\,' && echo "SHOULD BE i.e." && exit 1 || true; }
	cat *.tex | cut -f1 -d"%" | { grep --color=always --ignore-case -e 'cf\.\,' -e ' cf ' && echo "SHOULD BE cf." && exit 1 || true; }
	cat *.tex | cut -f1 -d"%" | { grep --color=always --ignore-case ' etc ' && echo "SHOULD BE etc." && exit 1 || true; }
	cat *.tex | cut -f1 -d"%" | { grep --color=always --ignore-case '``' && echo "SHOULD BE \`" && exit 1 || true; }
	cat *.tex | cut -f1 -d"%" | { grep --color=always --ignore-case "''" && echo "SHOULD BE \'" && exit 1 || true; }
	cat *.tex | cut -f1 -d"%" | { grep --color=always --ignore-case -e 'eq\.' -e 'eqn\.' -e 'Eq\.' -e 'Eqn\.' && echo "SHOULD BE equation~()" && exit 1 || true; }
else
	# Nothing to do
	@echo "THIS DOES NOT LOOK LIKE A MNRAS MANUSCRIPT - NOT ENFORCING BRITISH SPELLING"
	echo $(MNRAS_MANUSCRIPT_REQUIRING_BRITISH_SPELLING)
endif

check_us_spelling:
ifeq ($(AAS_MANUSCRIPT_REQUIRING_US_SPELLING),yes)
	# Check for US spelling
	# AAS style guide https://journals.aas.org/aas-style-guide/
	# they also suggest follow The Chicago Manual of Style https://www.chicagomanualofstyle.org/home.html
	#cat $(TEXFILE_BASENAME).tex | cut -f1 -d"%" | grep -v '$^{' | grep -v '\\center' | { grep --color=always 'centered' && echo "SHOULD BE centred" && exit 1 || true; }
	cat *.tex | cut -f1 -d"%" | grep -v '$^{' | grep -v '\\center' | { grep --color=always 'centred' && echo "SHOULD BE centered" && exit 1 || true; }
	#cat $(TEXFILE_BASENAME).tex | cut -f1 -d"%" | grep -v '$^{' | grep -v '\\center' | { grep --color=always 'center' && echo "SHOULD BE centre" && exit 1 || true; }
	cat *.tex | cut -f1 -d"%" | grep -v '$^{' | grep -v '\\center' | { grep --color=always 'centre' && echo "SHOULD BE center" && exit 1 || true; }
	#cat $(TEXFILE_BASENAME).tex | cut -f1 -d"%" | { grep --color=always --ignore-case 'sulfur' && echo "SHOULD BE sulphur" && exit 1 || true; }
	cat *.tex | cut -f1 -d"%" | { grep --color=always --ignore-case 'sulphur' && echo "SHOULD BE sulfur" && exit 1 || true; }
	#cat $(TEXFILE_BASENAME).tex | cut -f1 -d"%" | { grep --color=always --ignore-case 'labeled' && echo "SHOULD BE labelled" && exit 1 || true; }
	cat *.tex | cut -f1 -d"%" | { grep --color=always --ignore-case 'labelled' && echo "SHOULD BE labeled" && exit 1 || true; }
	#
	#cat $(TEXFILE_BASENAME).tex | cut -f1 -d"%" | { grep --color=always --ignore-case 'analyze' && echo "SHOULD BE analyse" && exit 1 || true; }
	cat *.tex | cut -f1 -d"%" | { grep --color=always --ignore-case 'analyse' && echo "SHOULD BE analyze" && exit 1 || true; }
	cat *.tex | cut -f1 -d"%" | { grep --color=always --ignore-case 'parametrized' && echo "SHOULD BE parameterized" && exit 1 || true; }
	#cat $(TEXFILE_BASENAME).tex | cut -f1 -d"%" | { grep --color=always --ignore-case 'parametrise' && echo "SHOULD BE parametrize" && exit 1 || true; }
	cat *.tex | cut -f1 -d"%" | { grep --color=always --ignore-case 'parametrize' && echo "SHOULD BE parametrise" && exit 1 || true; }
	# Why I was under impression that 'acknowledgements' is the correct spelling in AAS journals?
	# Their style guide spells 'acknowledgments' https://journals.aas.org/manuscript-preparation/#acknowledgments
	#cat $(TEXFILE_BASENAME).tex | cut -f1 -d"%" | { grep --color=always --ignore-case 'acknowledgments' && echo "SHOULD BE acknowledgements" && exit 1 || true; }
	cat *.tex | cut -f1 -d"%" | { grep --color=always --ignore-case 'acknowledgements' && echo "SHOULD BE acknowledgments" && exit 1 || true; }
	#
	#cat $(TEXFILE_BASENAME).tex | cut -f1 -d"%" | { grep --color=always --ignore-case 'artifact' && echo "SHOULD BE artefact" && exit 1 || true; }
	cat *.tex | cut -f1 -d"%" | { grep --color=always --ignore-case 'artefact' && echo "SHOULD BE artifact" && exit 1 || true; }
	# Yes, best-fitting seems to be OK at AAS
	#cat $(TEXFILE_BASENAME).tex | cut -f1 -d"%" | { grep --color=always --ignore-case 'best-fit ' && echo "SHOULD BE best-fitting" && exit 1 || true; }
	#cat $(TEXFILE_BASENAME).tex | cut -f1 -d"%" | { grep --color=always --ignore-case 'best-fitting ' && echo "SHOULD BE best-fit" && exit 1 || true; }
	#cat $(TEXFILE_BASENAME).tex | cut -f1 -d"%" | { grep --color=always --ignore-case 'disk' && echo "SHOULD BE disc" && exit 1 || true; }
	cat *.tex | cut -f1 -d"%" | { grep --color=always --ignore-case -e ' disc\,' -e ' disc\.' -e 'disc$$' -e 'disc ' && echo "SHOULD BE disk" && exit 1 || true; }
	#cat $(TEXFILE_BASENAME).tex | cut -f1 -d"%" | { grep --color=always --ignore-case 'halos' && echo "SHOULD BE haloes" && exit 1 || true; }
	cat *.tex | cut -f1 -d"%" | { grep --color=always --ignore-case 'haloes' && echo "SHOULD BE halos" && exit 1 || true; }
	#cat $(TEXFILE_BASENAME).tex | cut -f1 -d"%" | { grep --color=always --ignore-case 'hot-spot' && echo "SHOULD BE hotspot" && exit 1 || true; }
	#cat $(TEXFILE_BASENAME).tex | cut -f1 -d"%" | { grep --color=always --ignore-case 'nonlinear' && echo "SHOULD BE non-linear" && exit 1 || true; }
	#cat $(TEXFILE_BASENAME).tex | cut -f1 -d"%" | { grep --color=always --ignore-case ' onto ' && echo "SHOULD BE on to" && exit 1 || true; }
	cat *.tex | cut -f1 -d"%" | { grep --color=always --ignore-case ' on to ' && echo "SHOULD BE onto" && exit 1 || true; }
	cat *.tex | cut -f1 -d"%" | { grep --color=always --ignore-case 'time-scale' && echo "SHOULD BE timescale" && exit 1 || true; }
	#
	# random collection of words
	#cat $(TEXFILE_BASENAME).tex | cut -f1 -d"%" | { grep --color=always --ignore-case 'color' && echo "SHOULD BE colour" && exit 1 || true; }
	cat *.tex | cut -f1 -d"%" | { grep --color=always --ignore-case 'colour' && echo "SHOULD BE color" && exit 1 || true; }
	#cat $(TEXFILE_BASENAME).tex | cut -f1 -d"%" | { grep --color=always --ignore-case 'flavor' && echo "SHOULD BE flavour" && exit 1 || true; }
	cat *.tex | cut -f1 -d"%" | { grep --color=always --ignore-case 'flavour' && echo "SHOULD BE flavor" && exit 1 || true; }
	#cat $(TEXFILE_BASENAME).tex | cut -f1 -d"%" | { grep --color=always --ignore-case 'humor' && echo "SHOULD BE humour" && exit 1 || true; }
	cat *.tex | cut -f1 -d"%" | { grep --color=always --ignore-case 'humour' && echo "SHOULD BE humor" && exit 1 || true; }
	#cat $(TEXFILE_BASENAME).tex | cut -f1 -d"%" | grep -v '$^{' | { grep --color=always 'labor' && echo "SHOULD BE labour" && exit 1 || true; }
	cat *.tex | cut -f1 -d"%" | grep -v '$^{' | { grep --color=always 'labour' && echo "SHOULD BE labor" && exit 1 || true; }
	#cat $(TEXFILE_BASENAME).tex | cut -f1 -d"%" | { grep --color=always --ignore-case 'neighbor' && echo "SHOULD BE neighbour" && exit 1 || true; }
	cat *.tex | cut -f1 -d"%" | { grep --color=always --ignore-case 'neighbour' && echo "SHOULD BE neighbor" && exit 1 || true; }
	#cat $(TEXFILE_BASENAME).tex | cut -f1 -d"%" | { grep --color=always --ignore-case 'paralyze' && echo "SHOULD BE paralyse" && exit 1 || true; }
	cat *.tex | cut -f1 -d"%" | { grep --color=always --ignore-case 'paralyse' && echo "SHOULD BE paralyze" && exit 1 || true; }
	#cat $(TEXFILE_BASENAME).tex | cut -f1 -d"%" | sed 's:talogue::g' | { grep --color=always --ignore-case 'catalog' && echo "SHOULD BE catalogue" && exit 1 || true; }
	cat *.tex | cut -f1 -d"%" | sed 's:talogue::g' | { grep --color=always --ignore-case 'catalogue' && echo "SHOULD BE catalog" && exit 1 || true; }
	#cat $(TEXFILE_BASENAME).tex | cut -f1 -d"%" | { grep --color=always --ignore-case 'analog' && echo "SHOULD BE analogue" && exit 1 || true; }
	cat *.tex | cut -f1 -d"%" | { grep --color=always --ignore-case 'analogue' && echo "SHOULD BE analog" && exit 1 || true; }
	#
	#cat $(TEXFILE_BASENAME).tex | cut -f1 -d"%" | { grep --color=always --ignore-case 'modeling' && echo "SHOULD BE modelling" && exit 1 || true; }
	cat *.tex | cut -f1 -d"%" | { grep --color=always --ignore-case 'modelling' && echo "SHOULD BE modeling" && exit 1 || true; }
	# Other AAS things
	#cat $(TEXFILE_BASENAME).tex | { grep --color=always --ignore-case '\\%' && echo "SHOULD BE per cent" && exit 1 || true; }
	cat *.tex | cut -f1 -d"%" | { grep --color=always --ignore-case -e '~sec ' -e ' sec ' -e '\\,sec' && echo "SHOULD BE s" && exit 1 || true; }
	cat *.tex | cut -f1 -d"%" | { grep --color=always --ignore-case 'e\.g\. ' && echo "SHOULD BE e.g.," && exit 1 || true; }
	cat *.tex | cut -f1 -d"%" | { grep --color=always --ignore-case 'e\.g\.\]' && echo "SHOULD BE e.g.," && exit 1 || true; }
	cat *.tex | cut -f1 -d"%" | { grep --color=always --ignore-case 'i\.e\. ' && echo "SHOULD BE i.e.," && exit 1 || true; }
	#cat $(TEXFILE_BASENAME).tex | cut -f1 -d"%" | { grep --color=always --ignore-case -e 'cf\.\,' -e ' cf ' && echo "SHOULD BE cf." && exit 1 || true; }
	#cat $(TEXFILE_BASENAME).tex | cut -f1 -d"%" | { grep --color=always --ignore-case ' etc ' && echo "SHOULD BE etc." && exit 1 || true; }
	cat *.tex | cut -f1 -d"%" | { grep --color=always --ignore-case ' `[a-zA-Z]' && echo "SHOULD BE \`\`" && exit 1 || true; }
	cat *.tex | cut -f1 -d"%" | grep -v "s' " | { grep --color=always --ignore-case "[a-zA-Z]' " && echo "SHOULD BE \'\'" && exit 1 || true; }
	# super AAS-specific
	cat *.tex | cut -f1 -d"%" | { grep --color=always 'Fig\.' && echo "SHOULD BE Figure" && exit 1 || true; }
	cat *.tex | cut -f1 -d"%" | { grep --color=always 'Figs\.' && echo "SHOULD BE Figures" && exit 1 || true; }
	cat *.tex | cut -f1 -d"%" | { grep --color=always 'Sec\.' && echo "SHOULD BE Section" && exit 1 || true; }
	#
	cat *.tex | cut -f1 -d"%" | { grep --color=always 'errorbar' && echo "SHOULD BE error bar" && exit 1 || true; }
	cat *.tex | cut -f1 -d"%" | { grep --color=always 'free-fall' && echo "SHOULD BE freefall" && exit 1 || true; }
	cat *.tex | cut -f1 -d"%" | { grep --color=always 'free fall' && echo "SHOULD BE freefall" && exit 1 || true; }
	cat *.tex | cut -f1 -d"%" | { grep --color=always 'free~fall' && echo "SHOULD BE freefall" && exit 1 || true; }
else
	# Nothing to do
	@echo "THIS DOES NOT LOOK LIKE AN AAS MANUSCRIPT - NOT ENFORCING US SPELLING"
	echo $(AAS_MANUSCRIPT_REQUIRING_US_SPELLING)
endif

# We want to check for a consistent use of 'gamma-ray' vs '$\gamma$-ray', but only if it's a journal paper:
# in a proposal draft we may have an ASCII-only abstract and LaTeX text body.
DO_IT_CHECK_GAMMA_RAY_MATH_MODE=no
ifeq ($(AAS_MANUSCRIPT_REQUIRING_US_SPELLING),yes)
DO_IT_CHECK_GAMMA_RAY_MATH_MODE=yes
endif
ifeq ($(MNRAS_MANUSCRIPT_REQUIRING_BRITISH_SPELLING),yes)
DO_IT_CHECK_GAMMA_RAY_MATH_MODE=yes
endif
check_gamma_ray_math_mode:
ifeq ($(DO_IT_CHECK_GAMMA_RAY_MATH_MODE),yes)
	@echo "THIS IS AN MNRAS OR AAS MANUSCRIPT"
	echo $(DO_IT_CHECK_GAMMA_RAY_MATH_MODE)
	{ cat $(TEXFILE_BASENAME).tex | cut -f1 -d"%" | grep --quiet 'gamma-ray' && cat $(TEXFILE_BASENAME).tex | cut -f1 -d"%" | grep --quiet '$$\\gamma$$-ray' && cat $(TEXFILE_BASENAME).tex | cut -f1 -d"%" | grep --color=always -e 'gamma-ray' -e '$$\\gamma$$-ray' && echo "SHOULD BE USING CONSISTENTLY 'gamma-ray' or '$$\\gamma\$$-ray'" && exit 1 || true; }
else
	# Nothing to do
	@echo "THIS DOES NOT LOOK LIKE AN MNRAS OR AAS MANUSCRIPT - NOT ENFORCING MATH MODE for 'gamma-ray'"
	echo $(DO_IT_CHECK_GAMMA_RAY_MATH_MODE)
endif

check_software_small_capitals:
ifeq ($(ANY_KNOWN_SOFTWARE_MENTIONED),yes)
ifeq ($(TEST_SOFTWARE_TEXTSC),yes)
	# Check that \textsc is used in the text
	@echo "CHECK IF \\textsc{SoftWare} IS USED"
	cat $(TEXFILE_BASENAME).tex | cut -f1 -d"%" | grep -e '\\textsc' -e '\\scshape'
endif
else
	# Nothing to do
	@echo "NO KNOWN SOFTWARE NAMES RECOGNIZED"
	echo $(ANY_KNOWN_SOFTWARE_MENTIONED)
endif

check_swift_uvot_lowercase_filternames:
ifeq ($(IS_SWIFT_UVOT_MENTIONED),yes)
	# Check that Swift/UVOT filter names are lowercase
	cat *.tex | cut -f1 -d"%" | { grep --color=always 'UVW1' && echo "Swift/UVOT FILTER NAMES SHOULD BE LOWECASE uvw1 ?" && exit 1 || true; }
	cat *.tex | cut -f1 -d"%" | { grep --color=always 'UVM2' && echo "Swift/UVOT FILTER NAMES SHOULD BE LOWECASE uvm2 ?" && exit 1 || true; }
	cat *.tex | cut -f1 -d"%" | { grep --color=always 'UVW2' && echo "Swift/UVOT FILTER NAMES SHOULD BE LOWECASE uvw2 ?" && exit 1 || true; }
else
	# Nothing to do
	@echo "NO MENTION OF SWIFT UVOT"
	echo $(IS_SWIFT_UVOT_MENTIONED)
endif

check_consistent_unbreakable_space_size_UT:
	{ cat *.tex | cut -f1 -d"%" | grep --quiet '~UT' && cat *.tex | cut -f1 -d"%" | grep --quiet '\\\,UT' && cat *.tex | cut -f1 -d"%" | grep --color=always -e '~UT' -e '\\\,UT' && echo "SHOULD BE USING CONSISTENTLY '~UT' or '\\,UT" && exit 1 || true; }

check_filenames_good_for_arXiv:
	# Check if all filenames in the current directory contain only characters that are good for arXiv
	# as listed at https://info.arxiv.org/help/submit/index.html#files
	{ for FILENAME in * ;do if [[ "$$FILENAME" =~ ^[0-9A-Za-z_\\.\\,\-\\=\\+]+$$ ]]; then echo "The filename '$$FILENAME' looks good"; else echo "The filename '$$FILENAME' has characters not good for arXiv"; fi ;done | grep --color=always 'characters not good for arXiv' && exit 1 || true; }



$(TEXFILE_BASENAME).pdf: $(TEXFILE_BASENAME).tex
ifeq ($(PDFTEX),yes)
	# pdflatex
	@echo "YES PDF"
	echo $(PDFTEX)
ifeq ($(BIBTEX),yes)
	@echo "YES BibTeX"
	echo $(BIBTEX)
	# This works with .pdf/.png figures
	pdflatex $(TEXFILE_BASENAME).tex && pdflatex $(TEXFILE_BASENAME).tex && bibtex $(TEXFILE_BASENAME) && pdflatex $(TEXFILE_BASENAME).tex && pdflatex $(TEXFILE_BASENAME).tex 
ifeq ($(COUNT_NUMBER_OF_CHARACTERS_WITH_TEXCOUNT),yes)
	texcount -v3 -merge -incbib -dir -sub=none -utf8 -sum $(TEXFILE_BASENAME).tex 
endif
else
	@echo "NO BibTeX"
	echo $(BIBTEX)
	# No BibTeX, .pdf/.png figures
	pdflatex $(TEXFILE_BASENAME).tex && pdflatex $(TEXFILE_BASENAME).tex 
ifeq ($(COUNT_NUMBER_OF_CHARACTERS_WITH_TEXCOUNT),yes)
	texcount -v3 -merge -incbib -dir -sub=none -utf8 -sum $(TEXFILE_BASENAME).tex 
endif
endif

else
	# latex
	@echo "NO PDF  "
	echo $(PDFTEX)
ifeq ($(BIBTEX),yes)
	@echo "YES BibTeX"
	echo $(BIBTEX)
	# BibTeX and .eps figures (the right way)
	latex $(TEXFILE_BASENAME).tex && latex $(TEXFILE_BASENAME).tex && bibtex $(TEXFILE_BASENAME) && latex $(TEXFILE_BASENAME).tex && { latex $(TEXFILE_BASENAME).tex 2>&1 | grep --color=always 'undefined on input line' && exit 1 || true; } && dvips -o $(TEXFILE_BASENAME).ps $(TEXFILE_BASENAME).dvi && ps2pdf $(TEXFILE_BASENAME).ps 
ifeq ($(COUNT_NUMBER_OF_CHARACTERS_WITH_TEXCOUNT),yes)
	texcount -v3 -merge -incbib -dir -sub=none -utf8 -sum $(TEXFILE_BASENAME).tex 
endif
else
	@echo "NO BibTeX"
	echo $(BIBTEX)	
	# This works with .eps figures or when \usepackage[demo]{graphicx} is activated
	latex $(TEXFILE_BASENAME).tex && latex $(TEXFILE_BASENAME).tex && dvips -o $(TEXFILE_BASENAME).ps $(TEXFILE_BASENAME).dvi && ps2pdf $(TEXFILE_BASENAME).ps 
ifeq ($(COUNT_NUMBER_OF_CHARACTERS_WITH_TEXCOUNT),yes)
	texcount -v3 -merge -incbib -dir -sub=none -utf8 -sum $(TEXFILE_BASENAME).tex 
endif
endif

endif


check_for_bonus_figures: $(TEXFILE_BASENAME).tex
	{ for i in *eps *png *jpg ;do if [ ! -f $$i ];then continue ;fi ; cat *.tex | cut -f1 -d'%' | grep --quiet "$$i" && continue ; echo "WARNING: a bonus figure not included in the TeX source: $$i" ;done ; echo " " ; }  && { cat *.tex | cut -f1 -d'%' | grep 'label{fig:' | awk -F'label{' '{print $$2}' | awk -F'}' '{print $$1}' | while read LABELLED_FIGURE ; do cat *.tex | cut -f1 -d'%' | grep --quiet "ref{$$LABELLED_FIGURE}" && continue ; echo "WARNING: a figure not referenced in the main text: $$LABELLED_FIGURE" ;done ; echo " " ; }


display_compiled_pdf: $(TEXFILE_BASENAME).pdf
	@echo "The document is successfully compiled: "$(TEXFILE_BASENAME).pdf
ifeq ($(LAUNCH_OKULAR_PDF_VIEWER_TO_DISPLAY_COMPILED_PAPER),yes)
	@echo "Starting Okular PDF viewer to display "$(TEXFILE_BASENAME).pdf
	okular $(TEXFILE_BASENAME).pdf
endif
