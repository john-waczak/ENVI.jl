using ENVI
using Test
using HDF5
using BenchmarkTools


basepath = "./data"

test_bip = "./test.bip"
test_biphdr = "./test.bip.hdr"
test_bil = "./test.bil"
test_bilhdr = "./test.bil.hdr"
test_bsq = "./test.bsq"
test_bsqhdr = "./test.bsq.hdr"


# hsi_fname = "Scotty_1_Pika_XC2_1-radiance.bil"
# hsi_hdr = "Scotty_1_Pika_XC2_1-radiance.bil.hdr"
# lcf_fname = "Scotty_1_Pika_XC2_1.lcf"
# spec_fname = "Scotty_1_downwelling_1_pre.spec"
# spec_hdr = "Scotty_1_downwelling_1_pre.spec.hdr"
# times_fname = "Scotty_1_Pika_XC2_1.bil.times"


outpath = "./test.h5"
if isfile(outpath)
    rm(outpath)
end


@testset "header files" begin
    @test_throws FileNotAnEnviHeader read_envi_header(joinpath(basepath, test_bip))
    res = read_envi_header(joinpath(basepath, test_biphdr))
    @test "bands" ∈ keys(res)
    @test "lines" ∈ keys(res)
    @test "samples" ∈ keys(res)
end

@testset "file reading" begin
    img, h, p = read_envi_file(joinpath(basepath, test_bip), joinpath(basepath, test_biphdr))
    @test size(img) == (10, 10, 10)
    img, h, p = read_envi_file(joinpath(basepath, test_bil), joinpath(basepath, test_bilhdr))
    @test size(img) == (10, 10, 10)
    img, h, p = read_envi_file(joinpath(basepath, test_bsq), joinpath(basepath, test_bsqhdr))
    @test size(img) == (10, 10, 10)
end


@testset "hdf5 write" begin
    img, h, p = read_envi_file(joinpath(basepath, test_bip), joinpath(basepath, test_biphdr))

    envi_to_hdf5(joinpath(basepath, test_bip), joinpath(basepath, test_biphdr), outpath)
    fid = h5open(outpath, "r")
    g = fid["raw"]
    @test haskey(g, "radiance")
    for (key, val) ∈ h
        @test haskey(attributes(g), key)
    end
    close(fid)
    rm(outpath)
end



