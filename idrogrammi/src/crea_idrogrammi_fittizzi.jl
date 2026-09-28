using Plots, Plots.Measures, CSV, DataFrames, Dates, Infiltrator, Printf, OrderedCollections


const OutputFolderIdrogrammi = "idrogrammi_fittizzi"
const OutputFolderImmagini = "images"
const DoSaves = true

gumbel(t, μ, β) = (1/β) * exp( -(t - μ)/β - exp(-(t - μ)/β) )

function plot_df(df::DataFrame, filename::AbstractString)
    # Vaiaini = DateTime("2018-10-28 00:00:00", dateformat"yyyy-mm-dd HH:MM:SS")
    # Vaiaend = DateTime("2018-11-02 19:00:00", dateformat"yyyy-mm-dd HH:MM:SS")
    # ticks = collect(Vaiaini:Day(1):Vaiaend)
    # ticks = push!(ticks, Vaiaend)
    # ticklabels = Dates.format.(ticks, "dd-mm HH:MM")

	# ticks = collect(1.0:1.0:10.0)
	# tickslabels = string.(ticks)

    j = findlast(==('.'), filename)
    name = filename[1:j-1]

    plt = plot(df.Time_s ./ 3600, df.Discharge_m3_s;
        legend=false, 
        xlabel="tempo [h]", 
		# xticks=(ticks, tickslabels),
        ylabel="Portata [m³/s]", 
        title=name,
        bottom_margin=5mm
    )
    display(plt)
    return plt, name
end

function buildandplotdf(NomeFile, discharge, SecondsArray)
	df = DataFrame(
		Time_s=SecondsArray,
		Discharge_m3_s=discharge,
	)
	NomeFileIC = "IC_"*NomeFile

	plt, Nome = plot_df(df, NomeFile)

	NomeImmagine = Nome *  "_fittizio.pdf"

	if DoSaves
		CSV.write(joinpath(OutputFolderIdrogrammi, NomeFile), df, header=false)
		
		open(joinpath(OutputFolderIdrogrammi, NomeFileIC), "w") do file
			println(file, SecondsArray[begin], ",", discharge[begin])
			println(file, SecondsArray[end], ",", discharge[end])
		end

		savefig(plt, joinpath(OutputFolderImmagini, NomeImmagine))
	end

	return nothing
end

function main()
    #= Vaia: 
    2018-10-28 00:00:00
    2018-11-02 19:00:00
    # =#
	    #= valori per Vaia
		μCenta = 1.e5
    	β1 = 1.e4
    	IdroCenta = [gumbel(t, μCenta, β1) for t in SecondsArray]

    	display(plot(SecondsArray, IdroCenta;
    	    legend=false,
    	    xlabel="Data",
    	    ylabel="Portata (m³/s)", 
    	    title="Centa"   
    	)) 
	# =#

	#= # Originale

		# simulo una piena di 18 ore
	    BeginDate   = DateTime("2018-10-28 00:00:00", dateformat"yyyy-mm-dd HH:MM:SS")
	    EndDate     = DateTime("2018-10-28 18:00:00", dateformat"yyyy-mm-dd HH:MM:SS")

	    DatesArray = collect(BeginDate:Minute(10):EndDate)
	    SecondsArray = [Dates.value(Millisecond(d - BeginDate)) / 1000 for d in DatesArray]
	    LArray = length(SecondsArray)
		@assert (LArray ≤ 140) "troppi dati, riduci l'intervallo di tempo." 
		println("numero di dati: ", LArray)
		discharge = Array{Float64, 1}(undef, LArray)

		# Caldonazzo
		NomeFile = "Caldonazzo.csv"
		baseflow = 1.0
		highflow = 7.0
		fivehours = 3600.0*3
		growthrate = (highflow - baseflow)/fivehours
		discharge .= [SecondsArray[i] .≥ fivehours ? highflow : growthrate*SecondsArray[i]+baseflow for i ∈ 1:LArray]
		buildandplotdf(NomeFile, discharge, SecondsArray)

		# Levico
		NomeFile = "Levico.csv"
		baseflow = 1.0
		highflow = 5.0
		fivehours = 3600.0*3
		growthrate = (highflow - baseflow)/fivehours
		discharge .= [SecondsArray[i] .≥ fivehours ? highflow : growthrate*SecondsArray[i]+baseflow for i ∈ 1:LArray]
		buildandplotdf(NomeFile, discharge, SecondsArray)

		# Approssimo l'idrogramma con una distribuzione di Gumbel

		# Centa
		NomeFile = "Centa.csv"
		μCenta = 3600*4
	   	β1 = 3500
		scalefactor1 = 5.e5
		baseflow = 4.0
	   	discharge .= scalefactor1 .* [gumbel(t, μCenta, β1) for t in SecondsArray] .+ baseflow
		buildandplotdf(NomeFile, discharge, SecondsArray)

		# Brenta 1
		NomeFile = "Brenta1.csv"
		μCenta = 3600*4.05
	   	# β1 = 2500
		scalefactor1 = 8e4
		baseflow = 1.5
	   	discharge .= scalefactor1 .* [gumbel(t, μCenta, β1) for t in SecondsArray] .+ baseflow
		buildandplotdf(NomeFile, discharge, SecondsArray)

		# Brenta 2
		NomeFile = "Brenta2.csv"
		μCenta = 3600*4.1
	   	# β1 = 2500
		scalefactor1 = 5e4
		baseflow = 0.5
	   	discharge .= scalefactor1 .* [gumbel(t, μCenta, β1) for t in SecondsArray] .+ baseflow
		buildandplotdf(NomeFile, discharge, SecondsArray)

		# Brenta 3
		NomeFile = "Brenta3.csv"
		μCenta = 3600*4.1
	   	# β1 = 2500
		scalefactor1 = 9e4/3
		baseflow = 0.3
	   	discharge .= scalefactor1 .* [gumbel(t, μCenta, β1) for t in SecondsArray] .+ baseflow
		buildandplotdf(NomeFile, discharge, SecondsArray)

		# Brenta vecchio 1
		NomeFile = "BrentaVecchio1.csv"
		μCenta = 3600*4.3
	   	# β1 = 2500
		scalefactor1 = 6e4
		baseflow = 1.5
	   	discharge .= scalefactor1 .* [gumbel(t, μCenta, β1) for t in SecondsArray] .+ baseflow
		buildandplotdf(NomeFile, discharge, SecondsArray)

		# Brenta vecchio 2
		NomeFile = "BrentaVecchio2.csv"
		μCenta = 3600*4.35
	   	# β1 = 2500
		scalefactor1 = 6e4
		baseflow = 1.0
	   	discharge .= scalefactor1 .* [gumbel(t, μCenta, β1) for t in SecondsArray] .+ baseflow
		buildandplotdf(NomeFile, discharge, SecondsArray)

		# Brenta vecchio 3
		NomeFile = "BrentaVecchio3.csv"
		μCenta = 3600*4.40
	   	# β1 = 2500
		scalefactor1 = 3.5e4
		baseflow = 0.5
	   	discharge .= scalefactor1 .* [gumbel(t, μCenta, β1) for t in SecondsArray] .+ baseflow
		buildandplotdf(NomeFile, discharge, SecondsArray)

		# Brenta nuovo
		NomeFile = "BrentaNuovo.csv"
		μCenta = 3600*4.5
	   	# β1 = 2500
		scalefactor1 = 2e4
		baseflow = 0.5
	   	discharge .= scalefactor1 .* [gumbel(t, μCenta, β1) for t in SecondsArray] .+ baseflow
		buildandplotdf(NomeFile, discharge, SecondsArray)

	# =#

	# simulo una piena di 24 ore
    BeginDate   = DateTime("2018-10-28 00:00:00", dateformat"yyyy-mm-dd HH:MM:SS")
    EndDate     = DateTime("2018-10-29 00:00:00", dateformat"yyyy-mm-dd HH:MM:SS")

    DatesArray = collect(BeginDate:Minute(15):EndDate)
    SecondsArray = [Dates.value(Millisecond(d - BeginDate)) / 1000 for d in DatesArray]
    LArray = length(SecondsArray)
	@assert (LArray ≤ 140) "troppi dati, riduci l'intervallo di tempo." 
	println("numero di dati: ", LArray)
	discharge = Array{Float64, 1}(undef, LArray)
	
	# Caldonazzo
	NomeFile = "Caldonazzo.csv"
	baseflow = 1.0
	highflow = 7.0
	fivehours = 3600.0*3
	growthrate = (highflow - baseflow)/fivehours
	discharge .= [SecondsArray[i] .≥ fivehours ? highflow : growthrate*SecondsArray[i]+baseflow for i ∈ 1:LArray]
	buildandplotdf(NomeFile, discharge, SecondsArray)

	# Levico
	NomeFile = "Levico.csv"
	baseflow = 1.0
	highflow = 5.0
	fivehours = 3600.0*3
	growthrate = (highflow - baseflow)/fivehours
	discharge .= [SecondsArray[i] .≥ fivehours ? highflow : growthrate*SecondsArray[i]+baseflow for i ∈ 1:LArray]
	buildandplotdf(NomeFile, discharge, SecondsArray)

	# Approssimo l'idrogramma con una distribuzione di Gumbel

	# Centa
	NomeFile = "Centa.csv"
	
	μ1 = 3600*4
   	β1 = 1500
	scalefactor1 = 2.e5
	
	μ2 = 3600*6.5
   	β2 = 2500
	scalefactor2 = 3.e5
	
	baseflow = 4.0
   	discharge .= baseflow .+ scalefactor1 .* [gumbel(t, μ1, β1) for t in SecondsArray] .+ scalefactor2 .* [gumbel(t, μ2, β2) for t in SecondsArray]
	
	buildandplotdf(NomeFile, discharge, SecondsArray)

	# Brenta 1
	NomeFile = "Brenta1.csv"
	μ1 = 3600*4.05
   	# β1 = 2500
	scalefactor1 = 3e4

	μ2 = 3600*6.55
   	β2 = 2500
	scalefactor2 = 5.e4

	baseflow = 1.5
   	discharge .= baseflow .+ scalefactor1 .* [gumbel(t, μ1, β1) for t in SecondsArray] .+ scalefactor2 .* [gumbel(t, μ2, β2) for t in SecondsArray]
	buildandplotdf(NomeFile, discharge, SecondsArray)

	# Brenta 2
	NomeFile = "Brenta2.csv"
	μ1 = 3600*4.1
   	# β1 = 2500
	scalefactor1 = 2e4

	μ2 = 3600*6.51
   	β2 = 2500
	scalefactor2 = 3.5e4

	baseflow = 0.5
   	discharge .= baseflow .+ scalefactor1 .* [gumbel(t, μ1, β1) for t in SecondsArray] .+ scalefactor2 .* [gumbel(t, μ2, β2) for t in SecondsArray]
	buildandplotdf(NomeFile, discharge, SecondsArray)

	# Brenta 3
	NomeFile = "Brenta3.csv"
	μ1 = 3600*4.1
   	# β1 = 2500
	scalefactor1 = 2.e4/3

	μ2 = 3600*6.51
   	β2 = 2500
	scalefactor2 = 3.5e4/3

	baseflow = 0.3
   	discharge .= baseflow .+ scalefactor1 .* [gumbel(t, μ1, β1) for t in SecondsArray] .+ scalefactor2 .* [gumbel(t, μ2, β2) for t in SecondsArray]
	buildandplotdf(NomeFile, discharge, SecondsArray)

	# Brenta vecchio 1
	NomeFile = "BrentaVecchio1.csv"
	μ1 = 3600*4.3
   	# β1 = 2500
	scalefactor1 = 2e4

	μ2 = 3600*6.8
   	β2 = 2500
	scalefactor2 = 3e4

	baseflow = 1.5
   	discharge .= baseflow .+ scalefactor1 .* [gumbel(t, μ1, β1) for t in SecondsArray] .+ scalefactor2 .* [gumbel(t, μ2, β2) for t in SecondsArray]
	buildandplotdf(NomeFile, discharge, SecondsArray)

	# Brenta vecchio 2
	NomeFile = "BrentaVecchio2.csv"
	μ1 = 3600*4.35
   	# β1 = 2500
	scalefactor1 = 2e4

	μ2 = 3600*6.85
   	β2 = 2500
	scalefactor2 = 3e4

	baseflow = 1.0
   	discharge .= baseflow .+ scalefactor1 .* [gumbel(t, μ1, β1) for t in SecondsArray] .+ scalefactor2 .* [gumbel(t, μ2, β2) for t in SecondsArray]
	buildandplotdf(NomeFile, discharge, SecondsArray)

	# Brenta vecchio 3
	NomeFile = "BrentaVecchio3.csv"
	μ1 = 3600*4.4
   	# β1 = 2500
	scalefactor1 = 2.e4

	μ2 = 3600*6.9
   	β2 = 2500
	scalefactor2 = 3e4

	baseflow = 0.5
   	discharge .= baseflow .+ scalefactor1 .* [gumbel(t, μ1, β1) for t in SecondsArray] .+ scalefactor2 .* [gumbel(t, μ2, β2) for t in SecondsArray]
	buildandplotdf(NomeFile, discharge, SecondsArray)

	# Brenta nuovo
	NomeFile = "BrentaNuovo.csv"
	μ1 = 3600*4.5
   	# β1 = 2500
	scalefactor1 = 2e4
	baseflow = 0.5
   	discharge .= scalefactor1 .* [gumbel(t, μ1, β1) for t in SecondsArray] .+ baseflow
	buildandplotdf(NomeFile, discharge, SecondsArray)


    return nothing
end

main()