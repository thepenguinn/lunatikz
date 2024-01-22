#!/data/data/com.termux/files/usr/bin/lua5.3


local function tb_log(lvl, msg)
    if lvl == "warn" then
        print("WARN: " .. msg)
    end
end


local function read_file(file)

    assert(
        type(file) == "string",
        "read_file: file is not a string"
    )

    local fd = io.open(file, "r")
    local source

    if fd then
        source = fd:read("a")
        fd:close()
        return source
    else
        return nil
    end

end

-- Param: root_dir string, path to the root dir
-- Return: a table
local function read_dep_cache(root_dir)

    local dep_file = io.open(root_dir .. "/tikzpics/dep_cache.lua", "r")
    local dep_cache = nil

    if dep_file then
        dep_file:close()
        local dep = dofile(root_dir .. "/tikzpics/dep_cache.lua")
        if dep then
            dep_cache = dep
        end
    end

    dep_cache = dep_cache or {}

    setmetatable(dep_cache, {
        __newindex = function (tbl, key, val)
            rawset(tbl, key, val)
            if type(val) == "table" then
                setmetatable(val, getmetatable(tbl).__index_for_child)
            end
        end,
        __index_for_child = {
            __index = function (tbl, key)
                if key == "parent_nodes"
                    or key == "child_nodes" then
                    local val = {}
                    rawset(tbl, key, val)
                    return val
                end
            end
        },
    })

    local mt = getmetatable(dep_cache).__index_for_child

    for _, tbl in pairs(dep_cache) do
        if type(tbl) == "table" then
            setmetatable(tbl, mt)
        end
    end

    return dep_cache

end

local function write_dep_cache(root_dir, dep_cache)

    local function writetable(fd, tbl, depth)

        for key, child in pairs(tbl) do
            if type(child) == "table" then
                for i = 0, depth do
                    fd:write("    ")
                end
                if type(key) == "string" then
                    fd:write("[\"" .. key .. "\"] = {\n")
                else
                    fd:write("{\n")
                end
                writetable(fd, child, depth + 1)
                for i = 0, depth do
                    fd:write("    ")
                end
                fd:write("},\n")
            else
                for i = 0, depth do
                    fd:write("    ")
                end
                if type(key) == "string" then
                    fd:write("[\"" .. key .. "\"] = ")
                end
                if type(child) == "string" then
                    local str = child:gsub("\"", "\\\"")
                    fd:write("\"" .. str .. "\",\n")
                else
                    fd:write(tostring(child) .. ",\n")
                end
            end
        end
    end

    local file_fd = io.open(
        root_dir
        .. "/tikzpics/dep_cache.lua",
        "w"
    )

    assert(file_fd,
        "Couldn't open "
        .. root_dir
        .. "/tikzpics/dep_cache.lua to write dep_cache"
    )


    file_fd:write("return {\n")
    writetable(file_fd, dep_cache, 0)
    file_fd:write("}\n")

end

-- Param: file_list a table of paths, should be relative paths from root_dir.
-- Return: a hashmap with each file name without extention as keys to tables,
--         and each having the parent_dir(string), and lmodt(nummer) as values
local function get_end_pics_list(file_list)

    -- Param: end_pics_data = {
    --              file_list = { -- a table
    --                  parent_dir = path of the parent dir,
    --                  file_name = name of the file
    --              },
    --              pics_list[key] = { -- a hashmap -- key = file name without extention
    --                  parent_dir = path of the parent dir,
    --                  lmodt = last modified time of tex file
    --              },
    --              read_files[key] = true -- a hashmap -- key = path of read files
    --        }
    -- Return: a hashmap with each file name without extention as keys to tables,
    --         and each having the parent_dir(string), and lmodt(nummer) as values
    local function _get_end_pics_list(end_pics_data)

        local child_file_list = {}

        for _, file in pairs(end_pics_data.file_list) do

            local file_path = file.parent_dir .. "/" .. file.file_name

            assert(not (end_pics_data.read_files[file_path]),
                "Seems like this file has been read: \""
                .. file_path
                .. "\""
            )

            end_pics_data.read_files[file_path] = true

            local file_fd = io.open(file_path, "r")
            assert(file_fd, "Invalid file path")

            local file_source = file_fd:read("a")

            local is_abs_path
            local parent_dir
            local file_name
            local is_dir
            local file_basename

            for macro, fstarg in file_source:gmatch("\\([%w-_]+)[ \n\t]-{(.-)}") do

                if macro == "subfile"
                    or macro == "subfileinclude"
                    or macro == "include"
                    or macro == "input" then

                    is_abs_path, parent_dir, file_name, is_dir =
                    fstarg:match("^(/?)(.-)/-([%w%.-_ ]+)(/?)$")

                    assert(not (is_dir == "/"), "File name ends with a /")

                    if is_abs_path == "/" then
                        if parent_dir == "" then
                            child_file_list[#child_file_list + 1] = {
                                parent_dir = "/",
                                file_name = file_name
                            }
                        else
                            child_file_list[#child_file_list + 1] = {
                                parent_dir = "/" .. parent_dir,
                                file_name = file_name
                            }
                        end

                    else
                        if parent_dir == "" then
                            child_file_list[#child_file_list + 1] = {
                                parent_dir = file.parent_dir,
                                file_name = file_name
                            }
                        else
                            child_file_list[#child_file_list + 1] = {
                                parent_dir = file.parent_dir .. "/" .. parent_dir,
                                file_name = file_name
                            }
                        end
                    end

                elseif macro == "includegraphics" then

                    is_abs_path, parent_dir, file_name, is_dir =
                    fstarg:match("^(/?)(.-)/-([%w%.-_ ]+)(/?)$")

                    assert(not (is_dir == "/"), "File name ends with a /")

                    file_basename = file_name:match("(.-)%.[%w-_]+ *$")
                    assert(file_basename, "File basename is empty")

                    if end_pics_data.pics_list[file_basename] then
                        goto continue
                    end

                    local rl_parent_dir
                    local abs_parent_dir
                    local tmp_fd

                    if is_abs_path == "/" then
                        if parent_dir == "" then
                            rl_parent_dir = "/"
                        else
                            rl_parent_dir = "/" .. parent_dir
                        end
                    else

                        if parent_dir == "" then
                            rl_parent_dir = file.parent_dir
                        else
                            rl_parent_dir = file.parent_dir .. "/" .. parent_dir
                        end

                    end

                    tmp_fd = io.popen(
                        "readlink -e "
                        .. rl_parent_dir
                    )

                    abs_parent_dir = tmp_fd:read("a"):gsub("\n", "")

                    tmp_fd:close()

                    end_pics_data.pics_list[file_basename] = {
                        parent_dir = abs_parent_dir
                    }

                end

                ::continue::
            end

            file_fd:close()

        end

        if #child_file_list == 0 then
            return end_pics_data.pics_list
        else
            end_pics_data.file_list = child_file_list
            return _get_end_pics_list(end_pics_data)
        end

    end

    return _get_end_pics_list({
        file_list = file_list,
        pics_list = {},
        read_files = {}
    })

end

-- Param: file_path, relative path of file from current
--        working directory
-- Return: root_dir(string), root_file(string)
local function get_root_dir(file_path)

    assert(type(file_path) == "string",
        "get_root_dir: Expected file_path to be string type"
    )

    local parent_dir
    local file_name
    local is_dir

    parent_dir, file_name, is_dir =
    file_path:match("^(/?.-)/-([%w%.-_ ]+)(/?)$")
    assert(not (is_dir == "/"), "File name ends with a /")

    local file_fd = io.open(file_path, "r")
    assert(file_fd, "Failed to open: " .. file_path)

    local file_source = file_fd:read("a")
    file_fd:close()

    local oparg
    local fstarg

    oparg, fstarg = file_source:match(
        "\\documentclass[ \n\t]*%[(.-)%][ \n\t]*{(.-)}"
    )

    local oais_abs_path
    local oaparent_dir
    local oafile_name
    local oais_dir

    local rl_parent_dir
    local root_file_name

    if fstarg == "subfiles" then
        oais_abs_path, oaparent_dir, oafile_name, oais_dir =
        oparg:match("^(/?)(.-)/-([%w%.-_ ]+)(/?)$")
        assert(not (oais_dir == "/"), "File name ends with a /")

        -- checking of extention
        if not oafile_name:match(".-%.([%w-_]+) *$") then
            oafile_name = oafile_name .. ".tex"
        end

        if parent_dir == "" then
            if oaparent_dir == "" then
                rl_parent_dir = ".", oafile_name
            else
                rl_parent_dir = oais_abs_path .. oaparent_dir
            end
        else
            if oaparent_dir == "" then
                rl_parent_dir = parent_dir
            else
                if oais_abs_path == "" then
                    rl_parent_dir = parent_dir .. "/" .. oaparent_dir
                else
                    rl_parent_dir = "/" .. oaparent_dir
                end
            end
        end

        root_file_name = oafile_name

    else
        if parent_dir == "" then
            rl_parent_dir = "."
        else
            rl_parent_dir = parent_dir
        end
        root_file_name = file_name
    end

    local tmp_fd
    local abs_parent_dir

    tmp_fd = io.popen(
        "readlink -e "
        .. rl_parent_dir
    )

    abs_parent_dir = tmp_fd :read("a")
        :gsub("\n", "")

    tmp_fd:close()

    return abs_parent_dir, root_file_name

end

-- Param: file_path, relative path of file from current
--        working directory
-- Return: parent_dir(string), file_name(string)
local function split_path(file_path)

    local parent_dir
    local file_name
    local is_dir

    parent_dir, file_name, is_dir =
    file_path:match("^(/?.-)/-([%w%.-_ ]+)(/?)$")
    assert(not (is_dir == "/"), "File name ends with a /")

    assert(not (file_name == ""),
        "split_path: Got a file_name with empty string"
    )

    if parent_dir == "" then
        parent_dir = "."
    end

    return parent_dir, file_name

end

local function get_gdep_list(root_dir, dirs_to_add)

    local function add_files(dir, gdep_list)

        local files_fd
        local lmodt_fd
        local lmodt

        local parent_dir
        local file_basename

        files_fd = io.popen(
            "find "
            .. dir
            .. " -type f -name \"*.tex\""
        )

        for file in files_fd:lines() do

            parent_dir, file_basename = file:match(
                "^(/?.-)/-([%w%.-_ ]+)%.tex$"
            )

            lmodt_fd = io.popen(
                "stat --printf \"%Y\" "
                .. file
            )

            lmodt = tonumber(lmodt_fd:read("a"))

            lmodt_fd:close()

            gdep_list[file_basename] = {
                parent_dir = parent_dir,
                lmodt = lmodt
            }

        end

        files_fd:close()
    end

    local read_dirs = {}
    local gdep_list = {}
    local dirs_fd

    dirs_fd = io.popen(
        "find "
        .. root_dir
        .. " -type d -name tikzpics"
    )

    for dir in dirs_fd:lines() do
        if read_dirs[dir] then
            goto continue
        end
        add_files(dir, gdep_list)

        read_dirs[dir] = true
        ::continue::
    end

    dirs_fd:close()

    for _, dir_list in pairs(dirs_to_add) do

        for _, dir in pairs(dir_list) do

            if read_dirs[dir.parent_dir] then
                goto continue
            end

            add_files(gdep_list, dir.parent_dir)

            read_dirs[dir.parent_dir] = true
            ::continue::
        end

    end

    return gdep_list

end

local function build_dep_for_file(key, gdep_list, dep_cache)

    assert(type(key) == "string")
    assert(type(gdep_list) == "table")
    assert(type(dep_cache) == "table")

    assert(
        not gdep_list[key].been_here,
        "cyclic referencing in dependency tree of "
        .. key
    )

    local file_fd
    local file_source
    local need_to_build = false
    local new_parent_nodes = {}

    if gdep_list[key].dep_added then
        return need_to_build
    end

    if not dep_cache[key]
        or not dep_cache[key].lmodt
        or dep_cache[key].lmodt < gdep_list[key].lmodt then

        if not dep_cache[key] then
            print("no dep_cache: " .. key)
        elseif not dep_cache[key].lmodt then
            print("no lmodt: " .. key)
        elseif dep_cache[key].lmodt < gdep_list[key].lmodt then
            print("file modified: " .. key)
        end

        need_to_build = true

        file_source = read_file(
            gdep_list[key].parent_dir
            .. "/"
            .. key
            .. ".tex"
        )

        for macro in file_source:gmatch(
            "\\([%w%-_]+)[ \n\t]*{[^}]-}[ \n\t]*{[^}]-}"
        ) do

            if gdep_list[macro] then

                gdep_list[key].been_here = true

                new_parent_nodes[#new_parent_nodes + 1] = macro

                build_dep_for_file(macro, gdep_list, dep_cache)

                gdep_list[key].been_here = nil

            else
                tb_log("log",
                    "Skipping macro: because no tex file named "
                    .. macro
                    .. ".tex found"
                )
            end

        end

        if dep_cache[key] then
            for parent in pairs(dep_cache[key].parent_nodes) do
                dep_cache[parent].child_nodes[key] = nil
            end
            dep_cache[key].lmodt = gdep_list[key].lmodt
        else
            dep_cache[key] = {
                parent_dir = gdep_list[key].parent_dir,
                lmodt = gdep_list[key].lmodt
            }
        end

        for _, parent in pairs(new_parent_nodes) do
            if not dep_cache[parent] then
                assert(gdep_list[parent],
                    "build_dep_for_file: couldn't find "
                    .. parent
                )
                dep_cache[parent] = {
                    parent_dir = gdep_list[parent].parent_dir,
                    lmodt = nil
                }
            end
            dep_cache[key].parent_nodes[parent] = true
            dep_cache[parent].child_nodes[key] = true
        end

    else

        local parent_need_to_build

        for parent in pairs(dep_cache[key].parent_nodes) do
            parent_need_to_build = build_dep_for_file(
                parent, gdep_list, dep_cache
            )
            need_to_build = need_to_build or parent_need_to_build
        end

    end

    gdep_list[key].dep_added = true

    return need_to_build

end

---@Param: pics_list
local function build_dep_tree(root_dir, pics_list, gdep_list)

    local dep_cache = read_dep_cache(root_dir)

    local pdf_fd

    -- if dep_cache then return dep_cache end

    for key, file in pairs(pics_list) do

        if not gdep_list[key] then
            pics_list[key] = nil
            tb_log(
                "warn",
                "tex file doesn't exist: "
                .. key
                .. ".tex"
            )
            goto continue
        end

        pdf_fd = io.open(
            pics_list[key].parent_dir
            .. "/"
            .. key
            .. ".pdf",
            "r"
        )

        if pdf_fd then
            pdf_fd:close()
        else
            pics_list[key].need_to_build = true
        end

        if build_dep_for_file(key, gdep_list, dep_cache) then
            pics_list[key].need_to_build = true
        end

        ::continue::
    end

    return dep_cache

end

-- local pics_list = get_end_pics_list({
--     {parent_dir = "test_dir", file_name = "lol.tex"},
-- })
--
-- local root_dir, root_file = get_root_dir("test_dir/dir/another.tex")
-- --
-- local gdep_list = get_gdep_list(root_dir, { pics_list })
--
-- local dep_cache = build_dep_tree(root_dir, pics_list, gdep_list)
--
-- for k, i in pairs(pics_list) do
--     print(k, i.parent_dir)
-- end
