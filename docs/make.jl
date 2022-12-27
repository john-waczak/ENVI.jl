using ENVI
using Documenter

DocMeta.setdocmeta!(ENVI, :DocTestSetup, :(using ENVI); recursive=true)

makedocs(;
    modules=[ENVI],
    authors="John Waczak <john.louis.waczak@gmail.com>",
    repo="https://github.com/john-waczak/ENVI.jl/blob/{commit}{path}#{line}",
    sitename="ENVI.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://john-waczak.github.io/ENVI.jl",
        edit_link="main",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/john-waczak/ENVI.jl",
    devbranch="main",
)
