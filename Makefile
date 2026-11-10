.PHONY: test setup

test: setup
	nvim --headless --clean -u spec/spec.vim -c "PlenaryBustedDirectory spec/ {keep_going = false}"

setup:
	@if [ ! -d "/tmp/plenary.nvim" ]; then \
		echo "Downloading plenary.nvim for testing..."; \
		git clone --depth 1 https://github.com/nvim-lua/plenary.nvim.git /tmp/plenary.nvim; \
	fi
	@if [ ! -d "/tmp/telescope.nvim" ]; then \
		echo "Downloading telescope.nvim for testing..."; \
		git clone --depth 1 https://github.com/nvim-telescope/telescope.nvim.git /tmp/telescope.nvim; \
	fi
