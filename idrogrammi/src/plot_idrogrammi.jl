using Plots, Plots.Measures, CSV, DataFrames, Dates, Infiltrator, Printf, OrderedCollections

# uso direttamente gli idrogrammi in output generati dal file già fatto

const INPUT_FOLDER = "idrogrammi_parziali/"
const OUTPUT_FOLDER_BM = "basement_input/"
const OUTPUT_FOLDER_DATE = "idrogrammi_con_date/"

#
function carica_dati(path::AbstractString)
    df = CSV.read(path, DataFrame)

    # La prima colonna (senza nome, indice riga) viene scartata se presente
    if names(df)[1] in ("", "Column1")
        select!(df, Not(1))
    end

    # Parsing della colonna DATE: nel file compaiono sia date pure
    # ("2018-01-01") sia date con ora ("2018-01-01 01:00:00")
    # df.Tempo_s = map(s -> begin
    #     s = String(s)
    #     if occursin(' ', s)
    #         DateTime(s, dateformat"yyyy-mm-dd HH:MM:SS")
    #     else
    #         DateTime(s, dateformat"yyyy-mm-dd")
    #     end
    # end, df.Tempo_s)

    sort!(df, :Tempo_s)
    return df
end # =#

function plot_df(df::DataFrame, filename::AbstractString)
    Vaiaini = DateTime("2018-10-28 00:00:00", dateformat"yyyy-mm-dd HH:MM:SS")
    Vaiaend = DateTime("2018-11-02 19:00:00", dateformat"yyyy-mm-dd HH:MM:SS")
    ticks = collect(Vaiaini:Day(1):Vaiaend)
    ticks = push!(ticks, Vaiaend)
    ticklabels = Dates.format.(ticks, "dd-mm HH:MM")

    j = findlast(==('.'), filename)
    name = filename[1:j-1]

    plt = plot(df.Tempo_data, df.Portata;
        legend=false, 
        xlabel="Data", 
        xticks=(ticks, ticklabels),
        xrotation=30,
        ylabel="Portata (m³/s)", 
        title=name,
        bottom_margin=5mm
    )
    display(plt)
    return plt, name
end

function main()
    INPUT_FILE = INPUT_FOLDER * "lago_caldonazzo.csv"
    df = carica_dati(INPUT_FILE)
    # println("Righe lette: ", nrow(df))
    date0 = DateTime("2018-01-01 00:00:00", dateformat"yyyy-mm-dd HH:MM:SS")
    dates = date0 .+ Second.(df.Tempo_s)
    println("Periodo dataframes in input: 2018-01-01 00:00:00 (", first(df.Tempo_s), " s) -> ", last(dates), " (", last(df.Tempo_s), " s)")

    # Definisci le date di Vaia
    Vaiaini = DateTime("2018-10-28 00:00:00", dateformat"yyyy-mm-dd HH:MM:SS")
    Vaiaend = DateTime("2018-11-02 19:00:00", dateformat"yyyy-mm-dd HH:MM:SS")
    datevaia = collect(Vaiaini:Hour(1):Vaiaend)
    n_datevaia = length(datevaia)

    Vaiaini_s = Dates.value(Millisecond(Vaiaini - date0))/1000
    ini = findfirst(==(Vaiaini_s), df.Tempo_s)
    Tempo_s_Vaia = Int64.(df.Tempo_s[ini:ini+n_datevaia-1] .- Vaiaini_s)
    
    println("Vaia invece va da ", Vaiaini, " (0 s) -> ", Vaiaend, " (", last(Tempo_s_Vaia), " s)")    
    println("Che a intervalli orari sono: ", n_datevaia, " dati")

    # Prepara i vari idrogrammi correttamente (solo il tempo necessario)
    INPUT_FILE_NAMES = [
        "lago_caldonazzo.csv", 
        "lago_levico.csv", 
        "centa.csv", 
        "brenta_1.csv", 
        "brenta_2.csv",
        "brenta_3.csv",
        "brenta_vecchio_1.csv", 
        "brenta_vecchio_2.csv",
        "brenta_vecchio_3.csv",
        "brenta_vecchio_4.csv",
        "brenta_nuovo.csv"
    ]

    portate     = Array{Float64,2}(undef, n_datevaia, length(INPUT_FILE_NAMES))
    i = 1
    for interbacino ∈ INPUT_FILE_NAMES
        path            = joinpath(INPUT_FOLDER, interbacino)
        df              = carica_dati(path)
        portate[:, i]   = df.Portata[ini:ini+n_datevaia-1]
        i += 1
    end

    portate_out = Array{Float64,2}(undef, n_datevaia, length(INPUT_FILE_NAMES))
    portate_out[:, 1]  .= portate[:, 1]                                         # caldonazzo
    portate_out[:, 2]  .= portate[:, 2]                     # levico    
    portate_out[:, 3]  .= portate[:, 3] .- portate[:, 1]                        # centa
    portate_out[:, 4]  .= portate[:, 4] .- portate[:, 3] .- portate[:, 2]       # brenta1
    portate_out[:, 5]  .= portate[:, 5] .- portate[:, 4]                        # brenta2
    portate_out[:, 6]  .= (portate[:, 6] .- portate[:, 5]) / 3.0                # brenta3
    portate_out[:, 7]  .= portate[:, 7]                                         # brentavecchio1
    portate_out[:, 8]  .= portate[:, 8]                                         # brentavecchio2
    portate_out[:, 9]  .= portate[:, 9] .- portate[:, 8] .- portate[:, 7]       # brentavecchio3
    portate_out[:,10]  .= portate[:, 10] .- portate[:, 9]                       # brentavecchio4
    portate_out[:, 11] .= portate[:, 11] .- portate[:, 10] .- portate[:, 6]     # brentanuovo

    # Safety filter: avoid negative inlet discharge
    for i ∈ eachindex(portate_out)
        portate_out[i] = portate_out[i] < 0.0 ? 0.0 : portate_out[i]
    end 

    # Prepara i nomi degli idrogrammi correttamente
    OUTPUT_FILE_NAMES = [
        "Caldonazzo.csv", 
        "Levico.csv", 
        "Centa.csv", 
        "Brenta1.csv", 
        "Brenta2.csv",
        "Brenta3.csv",
        "BrentaVecchio1.csv", 
        "BrentaVecchio2.csv",
        "BrentaVecchio3.csv",
        "BrentaVecchio4.csv",
        "BrentaNuovo.csv"
    ]

    i = 1
	open(joinpath(OUTPUT_FOLDER_BM, "IC_Vaia.txt"), "w") do io
		println(io, "IC da impostare per sottobacino [m3/s]: ")
    	for interbacino ∈ OUTPUT_FILE_NAMES

    	    dfout_basement =    DataFrame(Tempo_s = Tempo_s_Vaia, Portata = portate_out[:, i])
    	    dfout_date =        DataFrame(Tempo_data = datevaia, Portata = portate_out[:, i])
    	    plt, name = plot_df(dfout_date, interbacino)
    	    savefig(plt, joinpath("immagini/", name * ".pdf"))
		
    	    filepath = joinpath(OUTPUT_FOLDER_BM, "$(interbacino)")
    	    CSV.write(filepath, dfout_basement, header=false)
    	    println("Salvato: ", filepath)

			# Salva un file con tutte le IC da impostare
			println(io, "$(interbacino): ", round(dfout_basement[1, "Portata"], digits=3))
    	    i += 1
    	end    
	end
    
    @infiltrate false

    return 
end

main()







#= ------------------------ inizio prova --------------------------
const GRUPPI = OrderedDict(
    "centa" => [1455],
    "centa_monte" => [1541, 1569, 1623, 1665, 1686, 1702, 1703],
)

function carica_dati(path::AbstractString)
    df = CSV.read(path, DataFrame)

    # La prima colonna (senza nome, indice riga) viene scartata se presente
    if names(df)[1] in ("", "Column1")
        select!(df, Not(1))
    end

    # Parsing della colonna DATE: nel file compaiono sia date pure
    # ("2018-01-01") sia date con ora ("2018-01-01 01:00:00")
    df.DATE = map(s -> begin
        s = String(s)
        if occursin(' ', s)
            DateTime(s, dateformat"yyyy-mm-dd HH:MM:SS")
        else
            DateTime(s, dateformat"yyyy-mm-dd")
        end
    end, df.DATE)

    sort!(df, :DATE)
    return df
end

function costruisci_idrogrammi(df::DataFrame, gruppi::OrderedDict{String,Vector{Int}})
    out = DataFrame(DATE = df.DATE)

    for (nome_gruppo, ids) in gruppi
        cols = nome_colonna.(ids)

        mancanti = setdiff(cols, names(df))
        if !isempty(mancanti)
            error("Colonne non trovate nel CSV per '$nome_gruppo': $mancanti")
        end

        # somma riga per riga delle colonne del gruppo
        out[!, nome_gruppo] = sum(Matrix(df[:, cols]), dims=2)[:, 1]
    end

    return out
end

nome_colonna(id::Integer) = "BASIN_ID_$(id)"

function prova()
    df = carica_dati("brentaVaia.csv")
    println("Periodo: ", first(df.DATE), " -> ", last(df.DATE))

    Vaiaini = DateTime("2018-10-28 00:00:00", dateformat"yyyy-mm-dd HH:MM:SS")
    Vaiaend = DateTime("2018-11-02 19:00:00", dateformat"yyyy-mm-dd HH:MM:SS")

    dfvaia = df[(df.DATE .>= Vaiaini) .& (df.DATE .<= Vaiaend), :]
    
    idro = costruisci_idrogrammi(dfvaia, GRUPPI)


    @infiltrate

    return nothing
end

prova()
# -------------------------- fine prova -------------------------- =#