-- This file contains the built-in components. Each componment is a function
-- that takes the following arguments:
--      config: A table containing the configuration provided by the user
--              when declaring this component in their renderer config.
--      node:   A NuiNode object for the currently focused node.
--      state:  The current state of the source providing the items.
--
-- The function should return either a table, or a list of tables, each of which
-- contains the following keys:
--    text:      The text to display for this item.
--    highlight: The highlight group to apply to this text.

local highlights = require("neo-tree.ui.highlights")
local common = require("neo-tree.sources.common.components")
local utils = require("neo-tree.utils")

local M = {}

M.current_filter = function(config, node, state)
  local filter = node.search_pattern or ""
  if filter == "" then
    return {}
  end
  return {
    {
      text = "Find ",
      highlight = highlights.DIM_TEXT,
    },
    {
      text = string.format('"%s"', filter),
      highlight = config.highlight or highlights.FILTER_TERM,
    },
    {
      text = " in ",
      highlight = highlights.DIM_TEXT,
    },
  }
end

M.symlink_target = function(config, node, state)
  if node.is_link then
    return {
      text = string.format(" ➛ %s", node.link_to),
      highlight = config.highlight or highlights.SYMBOLIC_LINK_TARGET,
    }
  else
    return {}
  end
end

M.name = function(config, node, state)
  local highlight = "NeoTreeFileName"
  if node.type == "directory" then
    highlight = "NeoTreeDirectoryName"
  end
  if node:get_depth() == 1 then
    highlight = "NeoTreeRootName"
  else
    if config.use_git_status_colors == nil or config.use_git_status_colors then
      local git_status = state.components.git_status({}, node, state)
      if git_status and git_status.highlight then
        highlight = git_status.highlight
      end
    end
  end
  -- make root-folder shorter and upper-case
  local function newName(name)
    if name:sub(1, 1) == "~" then
      local function split(inputstr, sep)
        if sep == nil then
          sep = "%s"
        end
        local t = {}
        for str in string.gmatch(inputstr, "([^" .. sep .. "]+)") do
          table.insert(t, str)
        end
        return t
      end
      local dirs = split(name, "/")
      local ans = dirs[#dirs]
      return string.upper(ans)
    else
      return name
    end
  end
  node.name = newName(node.name)

  return {
    text = node.name,
    highlight = highlight,
  }
end

M.icon = function(config, node, state)
  local icon = config.default or " "
  local highlight = "NeoTreeFileIcon"
  if node.type == "directory" then
    highlight = "NeoTreeDirectoryIcon"
    if node.loaded and not node:has_children() then
      icon = config.folder_empty or config.folder_open or "-"
    elseif node:is_expanded() then
      icon = config.folder_open or "-"
    else
      icon = config.folder_closed or "+"
    end
    if node:get_depth() == 1 then
      highlight = "NeoTreeRootName"
    else
      if config.use_git_status_colors == nil or config.use_git_status_colors then
        local git_status = state.components.git_status({}, node, state)
        if git_status and git_status.highlight then
          highlight = git_status.highlight
        end
      end
    end
  elseif node.type == "file" or node.type == "terminal" then
    local success, web_devicons = pcall(require, "dev-icons")
    if success then
      local devicon, hl = web_devicons.get_icon(node.name, node.ext)
      icon = devicon or icon
      highlight = hl or highlight
    end
  end
  -- Don't render icon in root folder
  if node:get_depth() == 1 then
    return {
      text = "",
      highlight = highlight,
    }
    -- Don't insert space between icon and filename (Only have a space in icon)
  else
    return {
      text = icon .. " ",
      highlight = highlight,
    }
  end
end

return vim.tbl_deep_extend("force", common, M)
