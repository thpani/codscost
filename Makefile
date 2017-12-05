OCB_FLAGS = -use-ocamlfind -I src -I src/programs -I src/heaps
OCB = ocamlbuild $(OCB_FLAGS)

TREIBER_FUNCS := emp pop push
TREIBER := testt $(foreach func,$(TREIBER_FUNCS),testt_$(func))
MS_FUNCS := emp deq enq
MS_FUNCS_PREFIXED := $(foreach func,$(MS_FUNCS),testms_$(func))
MS := testms $(MS_FUNCS_PREFIXED) $(foreach func,$(MS_FUNCS_PREFIXED),$(func)_nolag)

.PHONY: all clean native unit doc install test testclean $(TREIBER) $(MS)

all: native

clean:
	$(OCB) -clean

native:
	$(OCB) main.native

unit:
	$(OCB) -package oUnit -I test/unit sca.native
	./sca.native

doc:
	$(OCB) doc/api.docdir/index.html
	$(OCB) doc/api.docdir/api.dot

install: native
	install main.native /usr/bin/l2ca

test: $(TREIBER) $(MS)

testclean:
	$(MAKE) -C test/e2e/treiber clean
	$(MAKE) -C test/e2e/ms clean

$(TREIBER): native
	@$(MAKE) -C test/e2e/treiber $(patsubst _%,%,$(patsubst testt%,%,$@))

$(MS): native
	@$(MAKE) -C test/e2e/ms $(patsubst _%,%,$(patsubst testms%,%,$@))
