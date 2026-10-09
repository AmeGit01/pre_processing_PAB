"""
estrai_idrogrammi.jl

Legge lo storico delle portate orarie per sottobacino (brentaVaia.csv) e
costruisce 9 idrogrammi, ciascuno ottenuto sommando le portate di un
sottoinsieme di colonne BASIN_ID_*.

Ogni idrogramma viene salvato in un file CSV separato (nome scelto
dall'utente), con due sole colonne:
    Tempo_s   -> tempo trascorso in secondi dall'inizio della serie
    Portata   -> somma delle portate dei sottobacini del gruppo

Pacchetti richiesti (da installare una tantum):
    using Pkg
    Pkg.add(["CSV", "DataFrames", "Dates", "OrderedCollections"])
"""

using CSV
using DataFrames
using Dates
using OrderedCollections   # per OrderedDict: mantiene l'ordine di inserimento dei gruppi

# ---------------------------------------------------------------------
# 1) CONFIGURAZIONE: percorso file e definizione dei 9 gruppi di bacini
# ---------------------------------------------------------------------

const INPUT_FILE = "brentaVaia.csv"     # modifica se serve il path completo
const OUTPUT_DIR = "idrogrammi_parziali"  # cartella dove salvare i file

#= La CHIAVE è il nome file (senza estensione) con cui vuoi salvare quell'idrogramma.
# Il VALORE è la lista degli ID (numero dopo "BASIN_ID_") da sommare.
const GRUPPI = OrderedDict(
    "lago_caldonazzo" => [1703],
    "lago_levico" => [1704],
    "centa" => [1455,1541,1569],
    "brenta_1" => [1481, 1439, 1341, 1413],
    "brenta_2" => [1505, 1323, 1304],
    "brenta_3" => [1127, 1054, 1010],
    "brenta_vecchio_1" => [843],
    "brenta_vecchio_2" => [742,796],
    "brenta_vecchio_3" => [765],
    "brenta_nuovo" => [812,783],
) # =#

# NUOVA VERSIONE (Ame). i sottobacini segnati come commento andranno sottratti a quelli del dizionario
const GRUPPI = OrderedDict(
    "lago_caldonazzo" => [1703],
    "lago_levico" => [1704],
    "centa" => [1455], # - 1703
    "brenta_1" => [1341], # - 1455 - 1704
    "brenta_2" => [1323], # - 1341
    "brenta_3" => [1010], # - 1323
    "brenta_vecchio_1" => [843],
    "brenta_vecchio_2" => [742], 
    "brenta_vecchio_3" => [796], # - 843 - 742
    "brenta_vecchio_4" => [765], # - 796
    "brenta_nuovo" => [783], # - 765 - 1010
    "valle_brenta_1" => [803], # - 783
    "valle_brenta_2" => [838], # - 803
    "valle_brenta_3" => [898], # - 838
    "valle_brenta_4" => [894], # - 898
    "valle_brenta_5" => [889], # - 894
    "valle_brenta_6" => [1056], # - 889
    "valle_brenta_7" => [1176], # - 1056
    "valle_brenta_8" => [1301], # - 1176
    "valle_brenta_9" => [1319], # 1 1301
)

# ---------------------------------------------------------------------
# 2) LETTURA DATI
# ---------------------------------------------------------------------

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

# ---------------------------------------------------------------------
# 3) COSTRUZIONE IDROGRAMMI (somma colonne dei bacini di ciascun gruppo)
# ---------------------------------------------------------------------

nome_colonna(id::Integer) = "BASIN_ID_$(id)"

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

# ---------------------------------------------------------------------
# 4) MAIN
# ---------------------------------------------------------------------

function main()
    df = carica_dati(joinpath("inputs", INPUT_FILE))
    println("Righe lette: ", nrow(df))
    println("Periodo: ", first(df.DATE), " -> ", last(df.DATE))

    idro = costruisci_idrogrammi(df, GRUPPI)

    # tempo in secondi trascorsi dall'inizio della serie
    t0 = first(idro.DATE)
    tempo_s = [Dates.value(Millisecond(d - t0)) ÷ 1000 for d in idro.DATE]

    # --- salvataggio: un file CSV separato per ciascun idrogramma ---
    isdir(OUTPUT_DIR) || mkpath(OUTPUT_DIR)

    for nome_gruppo in keys(GRUPPI)
        out_i = DataFrame(Tempo_s = tempo_s, Portata = idro[!, nome_gruppo])
        filepath = joinpath(OUTPUT_DIR, "$(nome_gruppo).csv")
        CSV.write(filepath, out_i)
        println("Salvato: ", filepath)
    end

    return idro
end

main()