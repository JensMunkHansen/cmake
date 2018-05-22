include (CMakeParseArguments)

# validate_headers()
#
# Usage:
#   validate_headers(
#     ReturnValue
#     TARGET MyGreatProject
#     CXX_FLAGS
#     CFLAGS
#     INCLUDE_PATH
#   )
# where TARGET is used for getting compile options (if any)
#
# You can specify resource strings in arguments:
#   TARGET             - name of target from which to extract compile options
#   CXX_FLAGS          - needed to validate C++ headers
#   CFLAGS             - needed to validate C headers
#   INCLUDE_PATH       - needed to resolve any includes
#   HEADERS            - for testing
function(validate_headers)
  set (options)
  set (oneValueArgs
    TARGET)
  set (multiValueArgs
    CXX_FLAGS
    CFLAGS
    INCLUDE_PATH
    HEADERS)
  cmake_parse_arguments(PRODUCT "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

  # TODO: Use actual flags and figure out if C or C++
  if (NOT PRODUCT_CXX_FLAGS OR "${PRODUCT_CXX_FLAGS}" STREQUAL "")
    set(PRODUCT_CXX_FLAGS "-std=c++14")
  endif()

  set(include_arguments)
  foreach( dir ${PRODUCT_INCLUDE_PATH} )
    set( include_arguments "${include_arguments} -I${dir}" )
  endforeach(dir)

  separate_arguments(include_arguments UNIX_COMMAND "${include_arguments}")

  separate_arguments(PRODUCT_CXX_FLAGS UNIX_COMMAND "${PRODUCT_CXX_FLAGS}")

  # Includes empty string
  set(cpp_ext .hpp "")
  set(c_ext .h)

  if (MSVC)
    set(disable_all_warnings -w)
    set(syntax_only -Zs)
  else()
    set(disable_all_warnings -w)
    set(syntax_only -fsyntax-only)
  endif()

  foreach(header ${PRODUCT_HEADERS})
    # Determine C or C++ from extension
    set(ext)
    get_filename_component(ext "${t}" EXT)
    if (";${cpp_ext};" MATCHES ";${ext};")
      set(compiler_name "${CMAKE_CXX_COMPILER}")
      set(flags ${PRODUCT_CXX_FLAGS})
    else()
      set(compiler_name "${CMAKE_C_COMPILER}")
      set(flags ${PRODUCT_CFLAGS})
    endif()

    # TODO: Figure this out to support C headers
    set(compiler_name "${CMAKE_CXX_COMPILER}")

    set(headerpath)
    if(IS_ABSOLUTE ${header})
      set(headerpath "${header}")
    else()
      set(headerpath "${CMAKE_CURRENT_SOURCE_DIR}/${header}")
    endif()
    add_custom_command(TARGET ${PRODUCT_TARGET}
      PRE_BUILD
      COMMAND ${compiler_name}
      ${disable_all_warnings}
      ${flags}
      ${include_arguments}
      ${syntax_only} "${headerpath}")
  endforeach()
endfunction()
