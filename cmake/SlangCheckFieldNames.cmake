# Every host-visible struct field in the generated code must end in _0.
#
#     cmake -DGENERATED_DIR=<dir> -DFILES=A.cu|B.cu|C.cpp -P SlangCheckFieldNames.cmake
#
# ===========================================================================
# THE HAZARD THIS EXISTS FOR IS THE SHARPEST ONE IN THE PROJECT, AND IT HAS ALREADY
# HAPPENED TWICE.
#
# slangc disambiguates identifiers with an index assigned across the ENTIRE
# translation unit: the first `cellSize` it emits becomes `cellSize_0`, the second
# `cellSize_1`. Host code in src/ae/, src/cli/, src/kernel/ and tests/slang/ binds to
# those exact spellings.
#
# So a field can be RENAMED BY AN EDIT TO A DIFFERENT FILE. PROGRESS.md records it:
# TransportLib started including GeneratorLib, whose GeneratorInput has a `cellSize`,
# and MajorantGrid.cellSize_0 silently became cellSize_1. Nothing about MajorantGrid
# changed. The renderer's own Environment.radiance did the same thing when SkyLib
# joined the translation unit, moving from _0 to _2.
#
# A COMPILE ERROR IS THE LUCKY CASE AND IS NOT GUARANTEED. Both of those broke the
# build, which is how they were found. But two fields of the same TYPE that swap
# suffixes between two structs still compile: the host writes a.cellSize_0 and
# b.cellSize_1, both names still exist, and each now names the other struct's field.
# That reads the wrong memory, silently, in generated code nobody reads.
#
# THE MITIGATION IS UNIQUENESS, AND THIS IS THE CHECK THAT IT HOLDS. If every
# host-visible field name appears exactly once across the whole kernel -- and no
# local variable shadows one -- then every field is `_0` and no suffix can move. That
# is a property of the OUTPUT, so it can be checked mechanically instead of
# remembered.
#
# WHAT IS DELIBERATELY EXEMPT: EntryPointParams_N. slangc emits one of those per
# entry point and numbers them by definition, so the suffix is inherent rather than
# accidental -- the host binds them per entry point and cannot confuse two.
# ===========================================================================

if(NOT GENERATED_DIR OR NOT FILES)
    message(FATAL_ERROR "SlangCheckFieldNames.cmake needs -DGENERATED_DIR and -DFILES")
endif()

string(REPLACE "|" ";" _files "${FILES}")

set(_bad "")
set(_checked 0)

foreach(_f IN LISTS _files)
    set(_path "${GENERATED_DIR}/${_f}")
    if(NOT EXISTS "${_path}")
        # A MISSING FILE IS A FAILURE, NOT A SKIP -- the same rule the rest of
        # tests/ applies. A check that passes because its input was never produced
        # is worse than no check.
        list(APPEND _bad "${_f}: not generated")
        continue()
    endif()

    math(EXPR _checked "${_checked} + 1")
    file(READ "${_path}" _text)

    # ---------------------------------------------------------------------
    # THE SEMICOLONS HAVE TO GO FIRST, AND MISSING THAT MADE THIS CHECK PASS
    # WHILE TESTING NOTHING.
    #
    # `;` is CMake's list separator. string(REGEX MATCHALL) returns its matches as a
    # list joined by `;`, and a C struct body is nothing but semicolons -- so
    # `foreach(... IN LISTS ...)` split every struct at its first field and the loop
    # then examined fragments rather than structs. A deliberately corrupted field was
    # injected to check this script and it reported green.
    #
    # Replacing them before matching means no match can contain a separator. The
    # field regex looks for @SEMI@ where it would otherwise look for `;`.
    # ---------------------------------------------------------------------
    string(REPLACE ";" "@SEMI@" _text "${_text}")

    # Struct bodies, one at a time. `struct Name\n{\n ... \n};` is the only shape
    # slangc emits, and it emits them at column zero.
    string(REGEX MATCHALL "\nstruct [A-Za-z_0-9]+\n{[^}]*}" _structs "${_text}")

    foreach(_s IN LISTS _structs)
        string(REGEX MATCH "struct ([A-Za-z_0-9]+)" _m "${_s}")
        set(_name "${CMAKE_MATCH_1}")

        if(_name MATCHES "^EntryPointParams_")
            continue()
        endif()

        # A field line is "    <type> <name>_<n>;". The type may carry spaces,
        # angle brackets and stars, so the anchor is the trailing "_<digits>;" --
        # which is "_<digits>@SEMI@" here, for the reason above.
        string(REGEX MATCHALL "\n[^\n@]* ([A-Za-z_0-9]+)_([0-9]+)@SEMI@"
               _fields "${_s}")
        foreach(_field IN LISTS _fields)
            string(REGEX MATCH "([A-Za-z_0-9]+)_([0-9]+)@SEMI@" _fm "${_field}")
            if(NOT CMAKE_MATCH_2 STREQUAL "0")
                list(APPEND _bad
                     "${_f}: ${_name}.${CMAKE_MATCH_1}_${CMAKE_MATCH_2}")
            endif()
        endforeach()
    endforeach()
endforeach()

if(_bad)
    message("")
    message("  A GENERATED STRUCT FIELD IS NOT _0, WHICH MEANS ITS NAME COLLIDES")
    message("  WITH SOMETHING ELSE IN THE SAME TRANSLATION UNIT:")
    message("")
    foreach(_b IN LISTS _bad)
        message("      ${_b}")
    endforeach()
    message("")
    message("  WHY THIS IS A FAILURE AND NOT A WARNING. Host code binds to these")
    message("  exact spellings. A suffix is assigned across the whole translation")
    message("  unit, so an unrelated #include can move one -- and two fields of the")
    message("  same type swapping suffixes between two structs STILL COMPILES and")
    message("  reads the wrong memory.")
    message("")
    message("  THE FIX IS IN THE .slang, NOT HERE: rename the field so its name is")
    message("  unique across the whole kernel, including against local variables.")
    message("  MajorantGrid.cellSize became cellExtent for this reason, and")
    message("  Environment.radiance became uniformRadiance.")
    message("")
    message(FATAL_ERROR "generated field names are not unique")
endif()

message("  ${_checked} generated sources checked: every host-visible struct field is _0")
