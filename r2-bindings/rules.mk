include ../config.mk

include ../libs.mk

.SUFFIXES: .$(SOEXT)

all: ${LIBS}

w32:
	# TODO: add support for debian
	CC=i486-mingw32-gcc \
	CXX=i486-mingw32-g++ \
	LDFLAGS="-L${W32PY}/libs ${LDFLAGS}" \
	CFLAGS="-Wl,--enable-auto-import -L../../radare2-w32-${VERSION} ${CFLAGS}" \
	export CC CXX CFLAGS LDFLAGS ; \
	${MAKE}

ifeq ($(DEVEL_MODE),1)
%.${SOEXT}:
ifeq (${LANG},cxx)
	mod=`echo $@ | sed -e s,.${SOEXT},,` ; \
	echo "MOD=$$mod" ; \
	valabind --cxx -m $$mod --vapidir=../vapi $$mod && \
	${CXX} -shared -fPIC -o $@ $${mod}.cxx `pkg-config --cflags --libs $$mod`
else
	@-test ../vapi/`echo $@|sed -e s,.${SOEXT},.vapi,` -nt ${LIBS_PFX}$@ ; \
	if [ ! $$? = 0 ]; then \
	  if [ ! -e ${LIBS_PFX}$@ ]; then \
            true ; \
          else \
            false ; \
          fi ; \
	fi ; \
	[ $$? = 0 ] && \
	  (cd .. && RELEASE=$(RELEASE) \
		sh do-swig.sh ${LANG} `echo $@ | sed -e s,.${SOEXT},,`) ; true
endif

clean:
	rm -f *.${SOEXT} r_*
else
%.${SOEXT}:
	@VAPI=`echo $@|sed -e s,.${SOEXT},.vapi,` ; \
	test ../vapi/$${VAPI} -nt ${LIBS_PFX}$@ -o ! -e ${LIBS_PFX}$@ ; \
	if [ $$? = 0 ]; then echo " - ${LANG} $@" ; \
	LIB=`echo $@ | sed -e s,.${SOEXT},,` ; \
	case "${LANG}" in \
	"python") \
		${CXX} -fPIC -shared $${LIB}_wrap.cxx `../python-config-wrapper --cflags --libs` \
			`pkg-config --cflags --libs $${LIB}` ${CFLAGS} ${LDFLAGS} -o ${LIBS_PFX}$@ ; \
		;; \
	"lua") \
		${CXX} -fPIC -shared $${LIB}_wrap.cxx -I/usr/include/lua5.1 ${CFLAGS} ${LDFLAGS} -o ${LIBS_PFX}$@ ; \
		;; \
	esac ; fi ; true

clean:
	@rm -f *.${SOEXT} ; rm -rf *.dSYM
endif

test:
	-${LANG} test-r_bp.${LANG_EXT}
	-${LANG} test-r_asm.${LANG_EXT}
	-${LANG} test-r_hash.${LANG_EXT}

.PHONY: all test clean w32