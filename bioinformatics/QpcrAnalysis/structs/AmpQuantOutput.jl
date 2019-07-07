## Amp.jl
##
## main object in amplification.jl
##
## Author: Tom Price
## Date:   July 2019

import DataStructures.OrderedDict
import Ipopt.IpoptSolver


struct Amp
    ## input data
    raw_data                ::AbstractArray ## AmpRawData
    num_cycs                ::Int
    num_fluo_wells          ::Int
    num_channels            ::Int
    cyc_nums                ::Vector{Int}
    fluo_well_nums          ::Vector{Int}
    channels                ::Vector{Symbol}
    calibration_data        ::CalibrationData
    ## calibration parameters
    kwargs_cal              ::Dict{Symbol,Any}
    ## solver
    solver                  ::IpoptSolver
    ipopt_print2file_prefix ::String
    ## amplification model
    amp_model               ::AmpModel
    ## SFC model fitting parameters
    min_reliable_cyc        ::Int
    baseline_cyc_bounds     ::Vector{Int}
    cq_method               ::Symbol
    ctrl_well_dict          ::Dict{}
    ## arguments for report_cq!()
    max_bsf_lb              ::Int
    max_dr1_lb              ::Int
    max_dr2_lb              ::Int
    qt_prob_rc              ::Float_T
    before_128x             ::Bool
    scaled_max_dr1_lb       ::AbstractFloat
    scaled_max_dr2_lb       ::AbstractFloat
    scaled_max_bsf_lb       ::AbstractFloat
    ## results
    asrp_vec                ::Vector{AmpStepRampProperties}
    ## arguments for process_ad()
    kwargs_ad               ::Dict{Symbol,Any}
    ## output format
    out_sr_dict             ::Bool
    out_format              ::Symbol
    reporting               ::Function
end

## defaults for report_cq!()
DEFAULT_RCQ_QT_PROB             = 0.9
DEFAULT_RCQ_BEFORE_128X         = false
DEFAULT_RCQ_MAX_DR1_LB          = 472
DEFAULT_RCQ_MAX_DR2_LB          = 41
DEFAULT_RCQ_MAX_BSF_LB          = 4356
DEFAULT_RCQ_SCALED_MAX_DR1_LB   = 0.0089
DEFAULT_RCQ_SCALED_MAX_DR2_LB   = 0.000689
DEFAULT_RCQ_SCALED_MAX_BSF_LB   = 0.086