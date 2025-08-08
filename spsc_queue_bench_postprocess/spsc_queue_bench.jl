#!/usr/bin/env julia

using JSON
using CairoMakie
using Printf

function fmt_bytes(x::Real)
    string(round(Int, x))
end

function load_benchmark(path::AbstractString)
    data = JSON.parsefile(path)
    benchmarks = data["benchmarks"]
    payload = Float64[]
    ops_ms = Float64[]

    for benchmark in benchmarks
        haskey(benchmark, "payload_bytes") || continue
        haskey(benchmark, "ops_per_ms") || continue
        push!(payload, benchmark["payload_bytes"])
        push!(ops_ms,  benchmark["ops_per_ms"])
    end

    perm = sortperm(payload)
    return payload[perm], ops_ms[perm], data
end

function main()
    if isempty(ARGS)
        println("Usage: julia plot_bench.jl INPUT.json [OUTPUT.(png|svg)]")
        exit(0)
    end 

    inpath  = ARGS[1]
    outpath = length(ARGS) >= 2 ? ARGS[2] : "throughput.png"

    payload, ops_ms, _ = load_benchmark(inpath)
    fig = Figure(size = (900, 520))

    yticks_vals = collect(25000:25000:250000)

    ax = Axis(fig[1, 1];
        title  = "SPSC Queue Throughput vs Payload Size",
        xlabel = "Payload size (bytes)",
        ylabel = "Throughput (ops/ms)",
        xscale = log10,
        xticks = (payload, fmt_bytes.(payload)),
        yticks = (yticks_vals, string.(yticks_vals))
    )

    scatter!(ax, payload, ops_ms)
    lines!(ax, payload, ops_ms, color=:blue, linewidth=2)

    save(outpath, fig)
    println("Saved plot to: $outpath")
end

main()
