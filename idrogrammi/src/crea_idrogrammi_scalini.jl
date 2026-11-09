"""
crea_idrogrammi_scalini.jl

Crea un idrogramma a scalini per ogni affluente del Brenta, partendo dagli idrogrammi
della piena Vaia in basement_input/originali/.

La portata totale segue gli stessi livelli per tutti gli affluenti, e ogni affluente ne
riceve una quota fissa pari al suo massimo Vaia diviso la somma dei massimi:

    Q_j(livello) = Qmax_j / sum(Qmax) * QTotaleMax * frazione(livello)

Così ogni affluente arriva allo stesso multiplo del proprio massimo Vaia.

Ogni scalino dura 10 ore. Il salvataggio di BASEMENT ogni 36000 s cade 9 ore dopo la fine
della rampa e 30 minuti prima della rampa successiva.

Salva anche i grafici in immagini/scalini/: uno per affluente, uno per ognuno dei 4 tratti
con la portata cumulata a fine tratto, e uno che confronta i 4 tratti.

Uso (dalla cartella idrogrammi/, con il Project.toml di questa cartella):
    julia --project=. src/crea_idrogrammi_scalini.jl [cartella_output]
Senza argomenti scrive gli idrogrammi in basement_input/scalini/.
"""

ENV["GKSwstype"] = "100"    # GR senza finestra: i grafici vengono solo salvati

using Printf, Plots, Plots.Measures

const InputFolder  = normpath(joinpath(@__DIR__, "..", "basement_input", "originali"))
const OutputFolder = isempty(ARGS) ? normpath(joinpath(@__DIR__, "..", "basement_input", "scalini")) : ARGS[1]
const ImmaginiFolder = normpath(joinpath(@__DIR__, "..", "immagini", "scalini"))

# Tratti da monte verso valle, con gli affluenti che entrano in ognuno. L'ordine è quello
# dell'annidamento dei sottobacini in estrai_idrogrammi.jl. La portata di un tratto è cumulata:
# comprende anche tutti i tratti a monte
const Tratti = [
    "Tratto 1: laghi - Brenta3" => ["Caldonazzo", "Levico", "Centa", "Brenta1", "Brenta2", "Brenta3"],
    "Tratto 2: fino al Ceggio" => ["BrentaVecchio1", "BrentaVecchio2", "BrentaVecchio3", "BrentaVecchio4",
                                   "BrentaNuovo", "Moggio", "Ceggio"],
    "Tratto 3: fino al Chieppena" => ["Maso", "Chieppena"],
    "Tratto 4: fino al Grigno" => ["Brenta4", "Brenta5", "Brenta6", "Grigno"],
]

const ColoreLinea = "#2a78d6"
const ColoriTratti = ["#86b6ef", "#5598e7", "#2a78d6", "#144a8a"]   # da monte a valle, chiaro -> scuro
const StileGrafico = (; xlabel="tempo [h]", ylabel="Portata [m³/s]", linewidth=2, gridalpha=0.15,
                      size=(1000, 560), dpi=150, left_margin=6mm, bottom_margin=6mm,
                      xticks=0:24:216, framestyle=:axes, titlefontsize=11, top_margin=3mm)

const QTotaleMax = 700.0                # m³/s, somma degli affluenti all'ultimo scalino
const Livelli    = [1; 5:5:100] ./ 100  # frazioni di QTotaleMax, una per scalino
const DurataScalino = 36000             # s, uguale all'intervallo di output di BASEMENT
const Rampa         = 1800              # s, durata del passaggio tra due scalini
const PrimaRampa    = 37800             # s, inizio della prima rampa

# Nomi degli affluenti, nello stesso ordine del file delle condizioni iniziali Vaia
function leggi_nomi()
    righe = readlines(joinpath(InputFolder, "IC_Vaia.txt"))
    return [m.captures[1] for m in match.(r"^(\S+)\.csv:", righe) if m !== nothing]
end

# Portata massima dell'idrogramma originale (file senza intestazione: tempo,portata)
function leggi_qmax(nome)
    righe = readlines(joinpath(InputFolder, nome * ".csv"))
    return maximum(parse(Float64, split(r, ',')[2]) for r in righe if !isempty(r))
end

# Tempi e frazioni dei vertici dell'idrogramma: inizio e fine di ogni scalino
function costruisci_scalini()
    tempi = Int[0, PrimaRampa]
    frazioni = [Livelli[1], Livelli[1]]
    for (i, f) in enumerate(Livelli[2:end])
        inizio = PrimaRampa + (i - 1) * DurataScalino + Rampa
        append!(tempi, [inizio, inizio + DurataScalino - Rampa])
        append!(frazioni, [f, f])
    end
    return tempi, frazioni
end

# Asse y da zero, con un margine sopra perché l'ultimo scalino non venga tagliato
limiti_y(q) = (0, 1.06 * maximum(q))

function salva_grafici(nomi, portate, tempi)
    cartella = ImmaginiFolder
    mkpath(cartella)
    ore = tempi ./ 3600

    for nome in nomi
        plt = plot(ore, portate[nome]; legend=false, title=nome, color=ColoreLinea,
                   ylims=limiti_y(portate[nome]), StileGrafico...)
        savefig(plt, joinpath(cartella, nome * ".png"))
    end

    # Portata cumulata a fine tratto: ogni tratto si somma a quelli a monte
    cumulata = zeros(length(tempi))
    cumulate = Vector{Vector{Float64}}()
    for (i, (titolo, affluenti)) in enumerate(Tratti)
        cumulata = cumulata .+ sum(portate[a] for a in affluenti)
        push!(cumulate, cumulata)
        plt = plot(ore, cumulata; legend=false, color=ColoreLinea, ylims=limiti_y(cumulata), StileGrafico...,
                   title=titolo * "\nEntrano: " * join(affluenti, ", "), titlefontsize=10)
        savefig(plt, joinpath(cartella, "cumulata_tratto_$(i).png"))
    end

    # Confronto: i tratti di valle stanno sopra, quindi le linee non si incrociano
    plt = plot(; legend=:topleft, title="Portata cumulata a fine tratto, da monte a valle",
               ylims=limiti_y(cumulate[end]), StileGrafico...)
    for (i, (titolo, _)) in enumerate(Tratti)
        plot!(plt, ore, cumulate[i]; label=titolo, color=ColoriTratti[i], linewidth=2)
        annotate!(plt, ore[end], cumulate[i][end],
                  text(@sprintf("%.0f ", cumulate[i][end]), 9, :right, :bottom, "#52514e"))
    end
    savefig(plt, joinpath(cartella, "cumulata_tratti.png"))
    return cumulate
end

function main()
    nomi = leggi_nomi()
    length(nomi) == 19 || error("Attesi 19 affluenti in IC_Vaia.txt, trovati $(length(nomi))")

    qmax = leggi_qmax.(nomi)
    quote_affluenti = qmax ./ sum(qmax)
    tempi, frazioni = costruisci_scalini()

    mkpath(OutputFolder)
    for (nome, quota) in zip(nomi, quote_affluenti)
        open(joinpath(OutputFolder, nome * ".csv"), "w") do io
            for (t, f) in zip(tempi, frazioni)
                @printf(io, "%d,%.6f\n", t, quota * QTotaleMax * f)
            end
        end
    end

    open(joinpath(OutputFolder, "IC_scalini.txt"), "w") do io
        println(io, "IC da impostare per sottobacino [m3/s]: ")
        for (nome, quota) in zip(nomi, quote_affluenti)
            @printf(io, "%s.csv: %.3f\n", nome, quota * QTotaleMax * Livelli[1])
        end
    end

    @printf("Scritti %d idrogrammi in %s (fattore sul massimo Vaia: %.3f)\n",
            length(nomi), OutputFolder, QTotaleMax / sum(qmax))

    sort(reduce(vcat, last.(Tratti))) == sort(nomi) || error("I tratti devono contenere ogni affluente una sola volta")
    portate = Dict(nome => quota * QTotaleMax .* frazioni for (nome, quota) in zip(nomi, quote_affluenti))
    cumulate = salva_grafici(nomi, portate, tempi)
    @printf("Grafici salvati in %s. Portata massima a fine tratto: %s m³/s\n", ImmaginiFolder,
            join((@sprintf("%.1f", maximum(c)) for c in cumulate), ", "))
    return nothing
end

main()
