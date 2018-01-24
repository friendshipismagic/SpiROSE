# Simple tests: just a reference picture
TESTS_REF = tests/monkey.synth tests/monkey.view \
            tests/monkey-colorized.synth tests/monkey-colorized.view

# Object -> PNG
%.synth.png: %.obj $(EXE)
	LD_LIBRARY_PATH=$(LIBSPIROSE) ./$(EXE) $< $@
%.view.png: %.obj $(EXE)
	LD_LIBRARY_PATH=$(LIBSPIROSE) ./$(EXE) -V $< $@

# Compare
%-diff.png: %.png %-ref.png
	compare -metric AE $^ $@; code=$$?; echo; exit $$code

run-tests: $(TESTS_REF:=-diff.png)

# Cleanup
clean-tests:
	$(RM) tests/*.synth.png tests/*.view.png tests/*-diff.png

