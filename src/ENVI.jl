# modeled after code found in spectral (SPy)
# https://github.com/spectralpython/spectral/blob/master/spectral/io/envi.py


module ENVI
using HDF5


export FileNotAnEnviHeader
export read_envi_header
export get_envi_params
export read_envi_file
export envi_to_hdf5

envi_to_dtype = Dict(
    "1" => UInt8,
    "2" => Int16,
    "3" => Int32,
    "4" => Float32,
    "5" => Float64,
    "6" => ComplexF32,
    "9" => ComplexF64,
    "12" => UInt16,
    "13" => UInt32,
    "14" => Int64,
    "15" => UInt64,
)

dtype_to_envi = Dict(val => key for (key,val) ∈ envi_to_dtype)


# create custom error message for bad header files
struct FileNotAnEnviHeader <: Exception
    file::AbstractString
end

struct EnviHeaderParsingError <: Exception
end

Base.showerror(io::IO, e::FileNotAnEnviHeader) = print(io, e.file, " does not appear to be an ENVI header.")
Base.showerror(io::IO, e::FileNotAnEnviHeader) = print(io, "Failed to parse ENVI header file.")



"""
    read_envi_header(file::String)

Reads and ENVI `.hdr` file header and returns the parameters in a dictionary as strings.
"""
function read_envi_header(file::String)

    f = open(file, "r")
    # make sure we have a header file by checking first line
    starts_with_ENVI = startswith(readline(f), "ENVI")
    if !(starts_with_ENVI)
        throw(FileNotAnEnviHeader(file))
    end

    lines = readlines(f)
    close(f)

    res = Dict()

    try
        for line ∈ lines
            if occursin("=", line) && line[1] != ';'
                splitline = split(line, "=")
                key = strip(splitline[1])
                val = strip(splitline[2])

                res[key] = val

                # check for array information
                if val[1] == '{'
                    if key == "description"
                        res[key] = strip(val[2:end-1])
                    else
                        vals = [strip(v) for v ∈ split(val[2:end-1], ",")]
                        res[key] = vals
                    end
                else
                    res[key] = val
                end

            end
        end
        return res
    catch e
        throw(EnviHeaderParsingError)
    end


    # make sure we have mandatory parameters
    mandatory_params = ["lines", "samples", "bands", "data type", "interleave", "byte order"]
    if any([!(mp ∈ keys(res)) for mp ∈ mandatory_params])
        throw(EnviHeaderParsingError, "Missing at least one mandatory parameter")
    end

    return res
end




"""
    get_envi_params(h::Dict)

Parse dict returned by `read_envi_Header` and return parameters needed for reading binary file.
"""
function get_envi_params(h::Dict)
    params = Dict()
    params["nbands"] = parse(Int, h["bands"])
    params["nrows"] = parse(Int, h["lines"])
    params["ncols"] = parse(Int, h["samples"])
    params["offset"] = "header offset" ∈ keys(h) ? parse(Int, h["header offset"]) : 0
    params["byte_order"] = parse(Int, h["byte order"])
    params["dtype"] = envi_to_dtype[h["data type"]]

    return params
end



"""
    read_envi_file(fpath::String, hdrpath::String)

Read an ENVI formatted HSI file located at `fpath` with it's associated metatdata in `hdrpath`. Returns an image array `img`, the parsed header dictionary and the parameter dictionary.
"""
function read_envi_file(fpath::String, hdrpath::String)
    # read header file
    h = read_envi_header(hdrpath)
    p = get_envi_params(h)
    inter = h["interleave"]

    # change to bip for all as it will be most memory efficient when looping
    if inter == "bil" || inter == "BIL"
        img = Array{p["dtype"]}(undef, p["ncols"], p["nbands"], p["nrows"])
        read!(fpath, img)
        # img = PermutedDimsArray(img, (2,1,3))
        img = permutedims(img, (2,1,3))
    elseif inter == "bip" || inter == "BIP"
        img = Array{p["dtype"]}(undef, p["nbands"], p["ncols"], p["nrows"])
        read!(fpath, img)
    else
        img = Array{p["dtype"]}(undef, p["ncols"], p["nrows"], p["nbands"])
        # img = PermutedDimsArray(img, (3,1,2))
        img = permutedims(img, (3,1,2))
    end

    h["interleave"] = "bip"
    h["shape"] = "(band,col,row)"
    return img, h, p
end




"""
    envi_to_hdf5(fpath::String, hdrpath::String, outpath::String)

Read ENVI formatted HSI file from `fpath` and its associated metadata file `hdrpath`. Save the array to an hdf5 file at `outapth`.
"""
function envi_to_hdf5(fpath::String, hdrpath::String, outpath::String)
    img, h, p = read_envi_file(fpath, hdrpath)

    h5open(outpath, "cw") do fid
        g = create_group(fid, "raw")
        g["radiance", chunk=(p["nbands"],1,1)] = img
        for (key, value) ∈ h
            attributes(g)[key] = value
        end
    end
end


end
