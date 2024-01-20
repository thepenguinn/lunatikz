#!/data/data/com.termux/files/usr/bin/lua5.3



-- Param: root_dir string, path to the root dir
-- Return: a table
local function read_dep_cache(root_dir)

    local dep_file = io.open(root_dir .. "/tikzpics/dep_cache.lua", "r")

    if dep_file then
        dep_file:close()
        return require(root_dir .. "/tikzpics/dep_cache")
    else
        return {}
    end

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

                    end_pics_data.pics_list[file_basename] = {
                        parent_dir = io.popen(
                            "readlink -e "
                            .. rl_parent_dir
                        ):read("a"):gsub("\n", "")
                    }

                    -- we don't need to check the lmodt at this point
                    --  local tmp_fd = nil
                    --  local lmodt = nil

                    --  tmp_fd = io.open(
                    --      end_pics_data.pics_list[file_basename].parent_dir
                    --      .. "/"
                    --      .. file_basename
                    --      .. ".tex",
                    --      "r"
                    --  )

                    --  if tmp_fd then
                    --      lmodt = io.popen(
                    --          "stat --printf \"%Y\" "
                    --          .. end_pics_data.pics_list[file_basename].parent_dir
                    --          .. "/"
                    --          .. file_basename
                    --          .. ".tex"
                    --      ):read("a")
                    --      end_pics_data.pics_list[file_basename].lmodt = tonumber(lmodt)
                    --      tmp_fd:close()
                    --  else
                    --      -- print("file doesn't exist: "
                    --      --     .. end_pics_data.pics_list[file_basename].parent_dir
                    --      --     .. "/"
                    --      --     .. file_name
                    --      -- )
                    --  end


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

-- Param: pics_list
local function build_dep_tree(pics_list)
    local dep_cache = read_dep_cache()
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
                return ".", oafile_name
            else
                return oais_abs_path .. oaparent_dir, oafile_name
            end
        else
            if oaparent_dir == "" then
                return parent_dir, oafile_name
            else
                if oais_abs_path == "" then
                    return parent_dir .. "/" .. oaparent_dir, oafile_name
                else
                    return "/" .. oaparent_dir, oafile_name
                end
            end
        end

    else
        if parent_dir == "" then
            return ".", file_name
        else
            return parent_dir, file_name
        end
    end

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

local someting = get_end_pics_list({
    {parent_dir = "test_dir", file_name = "lol.tex"},
})

for k, i in pairs(someting) do
    print(k, i.lmodt, i.parent_dir)
end
