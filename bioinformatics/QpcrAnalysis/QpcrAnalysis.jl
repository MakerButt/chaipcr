#===============================================================================

    Module QpcrAnalysis.jl

===============================================================================#


#===============================================================================
    start of module definition >>
===============================================================================#

__precompile__()


# using Base

"""
Bioinformatics module for Chai's open-source Real-Time PCR instrument.
[https://www.chaibio.com](https://www.chaibio.com)
"""
module QpcrAnalysis
    const MODULE_NAME = "QpcrAnalysis"

    # using Clustering, Combinatorics, DataFrames, DataStructures, Dierckx, Ipopt, JLD, JSON,
    # JuMP, MySQL, NamedTuples, DataArrays
    ## `NLopt` needed on BBB but not on PC ("ERROR: LoadError: Declaring __precompile__(false)
    ## is not allowed in files that are being precompiled".
    ## "ERROR: Failed to precompile NLopt to /root/.julia/lib/v0.6/NLopt.ji")
    ## In addition, `HttpServer` for "juliaserver.jl"

    ## Other functions than `include` read files from `pwd()` only instead of also `LOAD_PATH`.
    ## `pwd()` shows the present working directory in module `Main`, instead of the directory
    ## where "QpcrAnalysis.jl" is located. Therefore `LOAD_FROM_DIR` needs to be defined
    ## for those functions to find files in the directory where "QpcrAnalysis.jl" is located.
    const LOAD_FROM_DIR = LOAD_PATH[find(LOAD_PATH) do path_
        isfile("$path_/$MODULE_NAME.jl")
    end][1] ## slice by boolean vector returned a one-element vector. Assumption: LOAD_PATH is global

    ## default data width in production mode:  32 bits (BBB)
    ## default data width in development mode: 64 bits
    const DEVELOPMENT_MODE = "development"
    const PRODUCTION_MODE  = "production"
    const production_env   = (get(ENV, "JULIA_ENV", nothing) == PRODUCTION_MODE)
    const Float_T = production_env ? Float32 : Float64



#===============================================================================
    include each script, generally in the order of workflow
===============================================================================#

    ## define constants & macros
    include("defines/enums.jl")
    include("defines/macros.jl")
    include("defines/keystring_constants.jl")

    ## shared functions
    include("shared_functions.jl")

    ## define structs
    include("defines/Field.jl")
    ## calibration
    include("defines/NumberOfChannels.jl")
    include("defines/RawData.jl")
    include("defines/CalibrationData.jl")
    include("defines/CalibrationParameters.jl")
    include("defines/CalibrationInput.jl")
    include("defines/K4Deconv.jl")
    ## allelic discrimination
    include("defines/ClusterAnalysisResult.jl")
    include("defines/UniqCombinCenters.jl")
    include("defines/AssignGenosResult.jl")
    ## amplification models
    include("amp_models/defines/AmpModel.jl")
    include("amp_models/defines/AmpModelFit.jl")
    include("amp_models/defines/SFC_model_definitions.jl")
    include("amp_models/defines/SFCModelDef.jl")

    ## generate amplification model definitions
    include("amp_models/generate_SFC_models.jl")
    include("amp_models/MAKx.jl")
    include("amp_models/MAKERGAULx.jl")
    include("amp_models/defines/AmpModelResults.jl")

    ## generate input structs
    include("defines/Input.jl")
    include("amp_models/defines/AmpInput.jl")
    include("defines/McInput.jl")

    ## define structs
    include("amp_models/defines/AmpOutput.jl")
    ## melting curve
    include("defines/PeakIndices.jl")
    include("defines/Peak.jl")
    include("defines/McPeakOutput.jl")
    include("defines/McOutput.jl")
    ## standard curve
    include("defines/StandardCurveResult.jl")
    ## thermal consistency
    include("defines/TmCheck1w.jl")
    include("defines/ThermalConsistencyOutput.jl")

    ## this code is hidden from the parser on the BeagleBone
    @static if !production_env
        ## development & testing
        import Base.Test
        using FactCheck
        include("../test/test_functions.jl")
        ## data format verification
        include("../test/verify_request.jl")
        include("../test/verify_response.jl")
    end

    ## function definitions for:
    ## dispatch
    include("dispatch.jl")
    ## calibration
    include("calibration.jl")
    ## amplification
    include("amplification.jl")
    include("fit_amplification_model.jl")
    ## melting curve
    include("melting_curve.jl")
    include("mc_peak_analysis.jl")
    include("supsmu.jl")
    ## standard curve
    include("standard_curve.jl")
    ## custom analyses
    include("custom_analyses/optical_calibration.jl")
    include("custom_analyses/optical_test_single_channel.jl")
    include("custom_analyses/optical_test_dual_channel.jl")
    include("custom_analyses/thermal_consistency.jl")
    include("custom_analyses/thermal_performance_diagnostic.jl")
    # include("custom_analyses/your_own_analysis.jl")



#===============================================================================
    create logger >>
===============================================================================#

    ## create module level logger
    ## this can be precompiled
    using Memento
    import FactCheck.clear_results
    logger = getlogger(current_module())



#===============================================================================
    runtime initialization >>
===============================================================================#

    ## This function contains stuff that needs to happen
    ## at runtime when the module is loaded
    function __init__()
        ## Changes to the default logger must happen at runtime
        ## otherwise segfaults are liable to occur
        push!(logger,
            DefaultHandler(
                FileRoller("julia.log", production_env ? "/var/log" : "/tmp"), ## default max size ~5MB
                DefaultFormatter("[ {date} | {level} ]: {msg}")))
        !production_env && setlevel!(logger, "debug")
        ## Register the module level logger at runtime
        ## so it is accessible via `get_logger(QpcrAnalysis)`
        Memento.register(logger)
        #
        ## clear Fact Checks
        !production_env && FactCheck.clear_results()
    end ## __init__()

end ## module QpcrAnalysis

#===============================================================================
    << end of module definition
===============================================================================#
