.PHONY: wiki-new wiki-link-check wiki-moc-build wiki-toc-suggest

WIKI := python3 scripts/wiki/wiki.py

wiki-new:
	@if [ -z "$(TYPE)" ] || [ -z "$(SLUG)" ]; then \
		echo "Usage: make wiki-new TYPE=RESEARCH_NOTE SLUG=karpathy-llm-wiki"; exit 2; \
	fi
	$(WIKI) new $(TYPE) $(SLUG)

wiki-link-check:
	$(WIKI) link-check $(if $(FULL),--full,)

wiki-moc-build:
	$(WIKI) moc-build $(if $(DRY_RUN),--dry-run,)

wiki-toc-suggest:
	@if [ -z "$(NOTE)" ]; then echo "Usage: make wiki-toc-suggest NOTE=path/to/note.md"; exit 2; fi
	$(WIKI) toc-suggest $(NOTE) $(if $(JSON),--format json,)
