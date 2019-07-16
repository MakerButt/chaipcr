#==============================================================================================

    test_functions.jl

    Author: Tom Price
    Date: Dec 2018

    automated test script for Julia API
    this code should be run at startup in fresh julia REPL

==============================================================================================#


const BBB = match(r"beaglebone", readlines(`uname -a`)[1]) != nothing
const RUN_THIS_CODE_INTERACTIVELY_NOT_ON_INCLUDE = false

import DataFrames.DataFrame
import DataStructures.OrderedDict
import JSON: json, parse, parsefile

@static if !BBB
    import FactCheck: clear_results
    import BSON: bson
end
    
const td = readdlm("$LOAD_FROM_DIR/../test/data/test_data.csv", ',', header=true)
const TEST_DATA = DataFrame([
    slicedim(td[1], 2, i) for i in 1:size(td[1],2)],
    map(Symbol, td[2][:]))


#==============================================================================================
    interactive code (development environment) >>
==============================================================================================#


## example code to generate, run, and save tests
## BSON preferred to JLD because it can save functions and closures
if (RUN_THIS_CODE_INTERACTIVELY_NOT_ON_INCLUDE & !BBB)
    cd("/home/vagrant/chaipcr/bioinformatics/QpcrAnalysis")
    push!(LOAD_PATH, pwd())
    using QpcrAnalysis

    test_functions = QpcrAnalysis.generate_tests(debug=false)
    check = QpcrAnalysis.test_dispatch(test_functions)

    if all(values(check))
        BSON.bson("$(QpcrAnalysis.LOAD_FROM_DIR)/../test/data/dispatch_tests.bson", test_functions)
        println("All test functions checked and saved")
        ## time functions second time around (after compilation)
        timing = QpcrAnalysis.time_dispatch(test_functions)
    else
        println("Test functions failed check:")
        println(check)
    end
end


## alternative test functions
# QpcrAnalysis.generate_test_script("revised_exec_testfns.jl")
# run(`mv exec_testfns.jl ../build`)



## Amplification timings 12 July 2019

# amp1 = test_functions["amplification single channel"]()
# # open("/tmp/amp1-test.json","w") do f
# #     JSON.print(f, amp1[2]["cq"])
# # end
# amp1_local = amp1[2]["cq"]
# amp1_saved = JSON.parsefile("/tmp/amp1-test.json")
# amp1_local == amp1_saved ## should be true
# using Memento
# setlevel!(QpcrAnalysis.logger, "error")
# @timev for i in 1:100; test_functions["amplification single channel"](); end;
# ## NB trailing semicolon suppresses output to REPL

## tweaks
# 27.564401 seconds (25.59 M allocations: 1.598 GiB, 1.62% gc time)
# elapsed time (ns): 27564401000
# gc time (ns):      446231000
# bytes allocated:   1715774576
# pool allocs:       25519126
# non-pool GC allocs:61100
# malloc() calls:    9600
# realloc() calls:   900
# GC pauses:         75

# first attempt using static arrays
# 35.524490 seconds (27.04 M allocations: 9.616 GiB, 3.94% gc time)
# elapsed time (ns): 35524490000
# gc time (ns):      1399246000
# bytes allocated:   10325273296
# pool allocs:       25401356
# non-pool GC allocs:1629005
# malloc() calls:    9700
# realloc() calls:   1200
# GC pauses:         450
# full collections:  1

# 27.231486 seconds (27.77 M allocations: 1.724 GiB, 1.75% gc time)
# elapsed time (ns): 27231486000
# gc time (ns):      476178000
# bytes allocated:   1851260240
# pool allocs:       27699785
# non-pool GC allocs:62205
# malloc() calls:    9600
# realloc() calls:   1100
# GC pauses:         80

# commit 803d603cf6663601a97b22c1937d8b682110b4d2
# 29.464264 seconds (27.88 M allocations: 1.674 GiB, 1.66% gc time)
# elapsed time (ns): 29464264000
# gc time (ns):      487881000
# bytes allocated:   1797779888
# pool allocs:       27815683
# non-pool GC allocs:57505
# malloc() calls:    9600
# realloc() calls:   1100
# GC pauses:         78

# commit a01b3b50a6e753f3ce92d4a33c1cc9adbb6256b7:
# 27.899778 seconds (27.90 M allocations: 1.675 GiB, 1.99% gc time)
# elapsed time (ns): 27899778000
# gc time (ns):      554854000
# bytes allocated:   1798466880
# pool allocs:       27832990
# non-pool GC allocs:57504
# malloc() calls:    9600
# realloc() calls:   1100
# GC pauses:         78

# commit 24b9b1128a41d1c1b7cfd504f147a8f9713c5ce1:
# 27.199742 seconds (30.54 M allocations: 1.727 GiB, 1.81% gc time)
# elapsed time (ns): 27199742000
# gc time (ns):      492167000
# bytes allocated:   1854066288
# pool allocs:       30471464
# non-pool GC allocs:58100
# malloc() calls:    9600
# realloc() calls:   400
# GC pauses:         80


## Meltcurve timings 12 July 2019

# mc3 = test_functions["meltcurve single channel"]()
# # open("/tmp/mc3-test.json","w") do f
# #     JSON.print(f, mc3[2]["melt_curve_analysis"])
# # end
# mc3_local = mc3[2]["melt_curve_analysis"]
# mc3_saved = JSON.parsefile("/tmp/mc3-test.json")
# mc3_local == mc3_saved ## should be true
# using Memento
# setlevel!(QpcrAnalysis.logger, "warn")
# @timev for i in 1:100; test_functions["meltcurve single channel"](); end;
# ## NB trailing semicolon suppresses output to REPL

# commit a01b3b50a6e753f3ce92d4a33c1cc9adbb6256b7:
# 12.023655 seconds (52.23 M allocations: 8.743 GiB, 11.55% gc time)
# elapsed time (ns): 12023655000
# gc time (ns):      1388750000
# bytes allocated:   9387864768
# pool allocs:       52151308
# non-pool GC allocs:71200
# malloc() calls:    8700
# realloc() calls:   1200
# GC pauses:         410
# full collections:  1

# commit 73883fd51b000e8c01da05814b0e06b89b153653:
# 13.969750 seconds (52.23 M allocations: 8.743 GiB, 11.36% gc time)
# elapsed time (ns): 13969750000
# gc time (ns):      1586836000
# bytes allocated:   9387864768
# pool allocs:       52151308
# non-pool GC allocs:71200
# malloc() calls:    8700
# realloc() calls:   1200
# GC pauses:         410
# full collections:  1

# commit 24b9b1128a41d1c1b7cfd504f147a8f9713c5ce1:
# 15.593274 seconds (169.50 M allocations: 16.070 GiB, 15.57% gc time)
# elapsed time (ns): 15593274000
# gc time (ns):      2428248000
# bytes allocated:   17254517088
# pool allocs:       169416202
# non-pool GC allocs:64902
# malloc() calls:    13700
# realloc() calls:   600
# GC pauses:         745
# full collections:  3


# mc4 = test_functions["meltcurve dual channel"]()
# # open("/tmp/mc4-test.json","w") do f
# #     JSON.print(f, mc4[2]["melt_curve_analysis"])
# # end
# mc4_local = mc4[2]["melt_curve_analysis"]
# mc4_saved = JSON.parsefile("/tmp/mc4-test.json")
# mc4_local == mc4_saved ## should be true
# using Memento
# setlevel!(QpcrAnalysis.logger, "warn")
# @timev for i in 1:100; test_functions["meltcurve dual channel"](); end;
# ## NB trailing semicolon suppresses output to REPL

# commit 30d20ce41a26d7ad304cf7db57a76e8974f6d055:
# 25.629426 seconds (114.48 M allocations: 16.327 GiB, 11.84% gc time)
# elapsed time (ns): 25629426000
# gc time (ns):      3035671000
# bytes allocated:   17531359168
# pool allocs:       114343408
# non-pool GC allocs:118300
# malloc() calls:    20900
# realloc() calls:   1400
# GC pauses:         764
# full collections:  6

# commit 24b9b1128a41d1c1b7cfd504f147a8f9713c5ce1:
# 30.701926 seconds (330.17 M allocations: 29.970 GiB, 14.68% gc time)
# elapsed time (ns): 30701926000
# gc time (ns):      4506477000
# bytes allocated:   32179894688
# pool allocs:       330025002
# non-pool GC allocs:121402
# malloc() calls:    27300
# realloc() calls:   700
# GC pauses:         1360
# full collections:  5


# mc4 = test_functions["meltcurve dual channel"]()
# @timev for i in 1:100; test_functions["meltcurve dual channel"](); end;
#
# mc11 = test_functions["thermal consistency dual channel"]()
# # open("/tmp/mc11-master.json","w") do f
# #     JSON.print(f, mc11[2])
# # end
# master11 = JSON.parsefile("/tmp/mc11-master.json")
# mc11[2] == master11 ## should be true
# @timev for i in 1:100; test_functions["thermal consistency dual channel"](); end;


#==============================================================================================
    interactive code (BBB) >>
==============================================================================================#


## timing tests on BBB
if (RUN_THIS_CODE_INTERACTIVELY_NOT_ON_INCLUDE & BBB)
    ENV["JULIA_ENV"]="production"
    cd("/root/chaipcr/bioinformatics/QpcrAnalysis")
    push!(LOAD_PATH, pwd())
    using QpcrAnalysis
    include("$(QpcrAnalysis.LOAD_FROM_DIR)/../test/test_functions.jl") ## this file
    test_functions = generate_tests()
    check = test_dispatch(test_functions)
    if all(values(check))
        println("All test functions passed check")
        ## time functions second time around (after compilation)
        timing = time_dispatch(test_functions)
    else
        println("Test functions failed check:")
        println(check)
    end
end


#==============================================================================================
    test functions >>
==============================================================================================#


function generate_tests(;
    debug     ::Bool =false,
    verbose   ::Bool =false
)
    test_functions = OrderedDict()
    strip = [" single"," dual"," channel"]
    for i in 1:size(TEST_DATA)[1]
        for channel_num in [:single_channel, :dual_channel]
            datafile = TEST_DATA[i, channel_num]
            if (datafile != "")
                action_key = Symbol(TEST_DATA[i, :action])
                # action = Val{QpcrAnalysis.ACT[action_key]}()
                request = JSON.parsefile("$(QpcrAnalysis.LOAD_FROM_DIR)/../test/data/$datafile.json",
                    dicttype=OrderedDict)
                body = String(JSON.json(request))

                function test_function()
                    QpcrAnalysis.print_v(println, verbose, "Testing $testname")
                    @static BBB || FactCheck.clear_results()
                    if (debug) ## errors fail out
                        # QpcrAnalysis.verify_request(action,request)
                        response = QpcrAnalysis.act(action, request)
                        response_body = string(JSON.json(response))
                        response_parsed = JSON.parse(response_body, dicttype=OrderedDict)
                        # QpcrAnalysis.verify_response(action,response_parsed)
                        ok = true
                    else ## continue tests after errors reported
                        (ok, response_body) = QpcrAnalysis.dispatch(
                            action_key, body; verify=false)
                        println("response_body:")
                        println(response_body)
                        response_parsed = JSON.parse(response_body, dicttype=OrderedDict)
                    end ## if debug
                    if (ok && response_parsed["valid"] )
                        QpcrAnalysis.print_v(println, verbose, "Passed $testname\n")
                    else
                        QpcrAnalysis.print_v(println, verbose, "Failed $testname\n")
                    end
                    return (ok, response_parsed)
                end

                testname = replace(TEST_DATA[i, :action], r"_"=>" ")
                for str in strip
                    testname = replace(testname, str=>"")
                end
                testname = replace("$testname "*string(channel_num), r"_"=>" ")
                test_functions[testname] = test_function
            end ## if datafile
        end ## single/dual channel (channel_num)
    end ## next action (i)
    return test_functions
end


#=============================================================================================#


## generate script to call test functions
## to precompile julia routines for BBB
function generate_test_script(outfile ::String)
    open(outfile, "w") do f
        write(f, """
        println("Starting precompile template !!!")
        push!(LOAD_PATH, "/root/chaipcr/bioinformatics/QpcrAnalysis/")

        println("Using time: ")
        @time using QpcrAnalysis
        println("Done Using!")
        for \$iteration in ["First", "Second"]
            println("\\nAbout to test dispatch. \$iteration time dispatch time:")
        """)
        write_dispatch_calls(f)
        write(f, """
            println("\\nDone dispatch time test")
        end # next iteration
        println("\\nDone with test functions!")
        """)
    end ## close file
end ## generate_test_script()


#=============================================================================================#


## write dispatch calls for generate_test_script()
function write_dispatch_calls(f)
    strip = [" single", " dual", " channel"]
    for i in 1:size(TEST_DATA)[1]
        for channel_num in [:single_channel, :dual_channel]
            datafile = TEST_DATA[i, channel_num]
            if (datafile != "")
                action = TEST_DATA[i, :action]
                request = JSON.parsefile("$(QpcrAnalysis.LOAD_FROM_DIR)/../test/data/$datafile.json",
                    dicttype=OrderedDict)
                body = String(JSON.json(request))
                testname = replace(TEST_DATA[i,:action], r"_"=>" ")
                for str in strip
                    testname = replace(testname, str=>"")
                end
                testname = replace("$testname "*string(channel_num), r"_"=>" ")
                write(f, """
                    println("\\nTesting \$testname")
                    action=\"\"\"$action\"\"\"
                    body=\"\"\"$body\"\"\"
                    @time (ok, response_body) =
                        QpcrAnalysis.dispatch(action, body; verify=false)
                    println("OK? \$ok")
                """)
            end ## if datafile
        end ## single/dual channel (channel_num)
    end ## next action (i)
end ## write_dispatch_calls()


#=============================================================================================#


## run test functions
## returns true for every test that runs without errors
function test_dispatch(test_functions ::Associative)
    OrderedDict(map(keys(test_functions)) do testname
        println("Making dispatch call: $testname")
        result = test_functions[testname]()
        testname => result[1] && result[2]["valid"]
    end)
end

## time performance
function time_dispatch(test_functions ::Associative)
    OrderedDict(map(keys(test_functions)) do testname
        println("Making dispatch call: $testname")  
        @timev result = test_functions[testname]()
        testname => result[1] && result[2]["valid"]
    end)
end


#==============================================================================================
    results >>
==============================================================================================#


## Meltcurve timings
#
# meltcrv commit  932b24a9be5bb148074830b0fd812618234ccfc1 (don't round mc_denser)
#  10.571982 seconds (61.91 M allocations: 8.668 GiB, 11.33% gc time)
# elapsed time (ns): 10571982383
# gc time (ns):      1197314629
# bytes allocated:   9307300800
# pool allocs:       61839800
# non-pool GC allocs:58000
# malloc() calls:    10900
# realloc() calls:   600
# GC pauses:         405
# full collections:  2

# meltcrv commit  932b24a9be5bb148074830b0fd812618234ccfc1 (remove args from nested funcs)
#  14.142563 seconds (63.41 M allocations: 8.969 GiB, 7.87% gc time)
# elapsed time (ns): 14142562549
# gc time (ns):      1113163232
# bytes allocated:   9630603200
# pool allocs:       63321800
# non-pool GC allocs:79700
# malloc() calls:    12500
# realloc() calls:   600
# GC pauses:         419
# full collections:  2

# meltcrv commit f12f5bda9485e307481be0012fc9ec4555aed0a6 (slowest)
# 18.955378 seconds (49.29 M allocations: 8.766 GiB, 7.62% gc time)
# elapsed time (ns): 18955377866
# gc time (ns):      1443815331
# bytes allocated:   9412268800
# pool allocs:       49198400
# non-pool GC allocs:80300
# malloc() calls:    12500
# realloc() calls:   600
# GC pauses:         410
# full collections:  3

# master commit c39573826114c84d3a516d3ec447c83765871368
# 9.707145 seconds (66.11 M allocations: 8.753 GiB, 12.19% gc time)
# elapsed time (ns): 9707144763
# gc time (ns):      1182875365
# bytes allocated:   9398664064
# pool allocs:       66009104
# non-pool GC allocs:94900
# malloc() calls:    9600
# realloc() calls:   600
# GC pauses:         410
# full collections:  3


#=============================================================================================#


# BBB results 2019-01-07
# run by Tom Price as root@10.0.100.231

# Making dispatch call: amplification single channel
#   6.335094 seconds (315.82 k allocations: 13.261 MiB, 3.85% gc time)
# elapsed time (ns): 6335093972
# gc time (ns):      243881118
# bytes allocated:   13905496
# pool allocs:       314368
# non-pool GC allocs:412
# malloc() calls:    550
# realloc() calls:   493
# GC pauses:         2

# Making dispatch call: amplification dual channel
#  13.940308 seconds (690.34 k allocations: 29.719 MiB, 3.35% gc time)
# elapsed time (ns): 13940307816
# gc time (ns):      467057318
# bytes allocated:   31162632
# pool allocs:       687248
# non-pool GC allocs:997
# malloc() calls:    1114
# realloc() calls:   984
# GC pauses:         5

# Making dispatch call: meltcurve single channel
#   4.068145 seconds (700.27 k allocations: 88.775 MiB, 11.46% gc time)
# elapsed time (ns): 4068144765
# gc time (ns):      466131773
# bytes allocated:   93087712
# pool allocs:       699164
# non-pool GC allocs:644
# malloc() calls:    355
# realloc() calls:   105
# GC pauses:         14

# Making dispatch call: meltcurve dual channel
#  48.444924 seconds (8.27 M allocations: 393.947 MiB, 10.21% gc time)
# elapsed time (ns): 48444923803
# gc time (ns):      4946285937
# bytes allocated:   413083800
# pool allocs:       8271275
# non-pool GC allocs:1419
# malloc() calls:    702
# realloc() calls:   202
# GC pauses:         63
# full collections:  1

# Making dispatch call: standard curve single channel
#   0.084199 seconds (1.90 k allocations: 86.211 KiB)
# elapsed time (ns): 84198636
# bytes allocated:   88280
# pool allocs:       1900
# non-pool GC allocs:2

# Making dispatch call: optical cal single channel
#   0.008529 seconds (752 allocations: 28.359 KiB)
# elapsed time (ns): 8529347
# bytes allocated:   29040
# pool allocs:       752

# Making dispatch call: optical cal dual channel
#   0.023195 seconds (2.73 k allocations: 112.789 KiB)
# elapsed time (ns): 23195099
# bytes allocated:   115496
# pool allocs:       2734

# Making dispatch call: thermal performance diagnostic single channel
#   0.024872 seconds (6.20 k allocations: 206.281 KiB)
# elapsed time (ns): 24872069
# bytes allocated:   211232
# pool allocs:       6197
# non-pool GC allocs:3

# Making dispatch call: thermal performance diagnostic dual channel
#   0.020857 seconds (4.77 k allocations: 159.742 KiB)
# elapsed time (ns): 20857365
# bytes allocated:   163576
# pool allocs:       4767
# non-pool GC allocs:3

# Making dispatch call: thermal consistency single channel
#   1.408891 seconds (196.18 k allocations: 27.054 MiB, 16.47% gc time)
# elapsed time (ns): 1408891471
# gc time (ns):      232104860
# bytes allocated:   28368096
# pool allocs:       195557
# non-pool GC allocs:451
# malloc() calls:    90
# realloc() calls:   83
# GC pauses:         4

# Making dispatch call: thermal consistency dual channel
#  19.650871 seconds (3.35 M allocations: 168.469 MiB, 8.63% gc time)
# elapsed time (ns): 19650871467
# gc time (ns):      1696740250
# bytes allocated:   176652784
# pool allocs:       3345526
# non-pool GC allocs:986
# malloc() calls:    178
# realloc() calls:   163
# GC pauses:         27

# Making dispatch call: optical test single channel
#   0.002865 seconds (309 allocations: 12.695 KiB)
# elapsed time (ns): 2865254
# bytes allocated:   13000
# pool allocs:       309

# Making dispatch call: optical test dual channel
#   0.024774 seconds (4.14 k allocations: 175.016 KiB)
# elapsed time (ns): 24774074
# bytes allocated:   179216
# pool allocs:       4135
# non-pool GC allocs:1
# realloc() calls:   1
