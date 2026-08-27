-- Telescope extension entrypoint for emse.nvim

return require("telescope").register_extension({
  exports = {
    environments = function(opts)
      require("emse.telescope.environments").picker(opts)
    end,
    scripts = function(opts)
      require("emse.telescope.scripts").picker(opts)
    end,
    options = function(opts)
      require("emse.telescope.options").picker(opts)
    end,
    initializers = function(opts)
      require("emse.telescope.initializers").picker(opts)
    end,
    templates = function(opts)
      require("emse.telescope.templates").picker(opts)
    end,
    scratchpads = function(opts)
      require("emse.telescope.scratchpads").picker(opts)
    end,
  }
})