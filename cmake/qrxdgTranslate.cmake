#  funtion qtxdg_translate_ts(qm_files 
#                           SOURCES sources ... 
#                           [TRANSLATION_DIR] translation_directory
#                           [INSTALLATION_DIR] qm_install_directory
#                          )
#     out: qm_files 
#     generates commands to create .ts.src and .qm files from sources. 
#     The generated filenames can be found in qm_files.
#
#     in: sources 
#     List of the h, cpp and ui files
#
#     in: translation_directory
#     A relative path to the directory with .ts files, it is relative 
#     to the CMakeList.txt. By default is "translations"
#
#     in: qm_install_directory
#     A full path to the directory n which will be installed .qm files.
#     By default is "${CMAKE_INSTALL_PREFIX}/share/qtxdg/${PROJECT_NAME}" 


if(NOT TARGET UpdateTsFiles)
  add_custom_target(UpdateTsFiles DEPENDS)
endif()

if(NOT TARGET UpdateTxFile)
  add_custom_target(UpdateTxFile  
    COMMAND echo "[main]"                            > ${CMAKE_SOURCE_DIR}/.tx/config2
    COMMAND echo "host = https://www.transifex.net" >> ${CMAKE_SOURCE_DIR}/.tx/config2
    COMMAND echo ""                                 >> ${CMAKE_SOURCE_DIR}/.tx/config2
    COMMAND cat ${CMAKE_BINARY_DIR}/tx/*.tx_config  >> ${CMAKE_SOURCE_DIR}/.tx/config2
  )
endif()


function(qtxdg_translate_ts _qmFiles)
    set(_translationDir "translations")
    set(_installDir "${CMAKE_INSTALL_PREFIX}/share/libqtxdg/")
    
    # Parse arguments ***************************************
    set(_state "")
    foreach (_arg ${ARGN})  
        if (
            (${_arg} STREQUAL "SOURCES") OR
            (${_arg} STREQUAL "TRANSLATION_DIR") OR
            (${_arg} STREQUAL "INSTALLATION_DIR") OR
            (${_arg} STREQUAL "TS_SRC_FILE")        
           )        

            set(_state ${_arg})
      
        else()
            if("${_state}" STREQUAL "SOURCES")
                get_filename_component (__file ${_arg} ABSOLUTE)
                set(_sources  ${_sources} ${__file})
                #set(_sources  ${_sources} ${_arg})
 
            elseif("${_state}" STREQUAL "TRANSLATION_DIR")
                set(_translationDir ${_arg})       
                set(_state "")

            elseif("${_state}" STREQUAL "INSTALLATION_DIR")
                set(_installDir ${_arg})       
                set(_state "")

            elseif("${_state}" STREQUAL "TS_SRC_FILE")
                set(_tsSrcFile ${_arg})       
                set(_state "")
        
            else()  
                MESSAGE(FATAL_ERROR 
                  "Unknown argument '${_arg}'.\n"
                  "See ${CMAKE_CURRENT_LIST_FILE} for more information.\n"
                )
            endif()  
        endif()
    endforeach(_arg)

    get_filename_component (_translationDir ${_translationDir} ABSOLUTE)
    if ("${_tsSrcFile}" STREQUAL "") 
        set(_tsSrcFile  "${_translationDir}/${PROJECT_NAME}.ts.src")
    endif()
    
    get_filename_component (_tsSrcFile  ${_tsSrcFile} ABSOLUTE)
    get_filename_component (_tsSrcFileName  ${_tsSrcFile} NAME)
    get_filename_component (_tsSrcFileNameWE  ${_tsSrcFile} NAME_WE)


    # TS.SRC file *******************************************    
    add_custom_target(Update_${_tsSrcFileName}
        COMMAND ${QT_LUPDATE_EXECUTABLE} -target-language en_US ${_sources} -ts ${_tsSrcFile}.ts
        COMMAND mv ${_tsSrcFile}.ts ${_tsSrcFile}
        DEPENDS ${_sources}
        WORKING_DIRECTORY ${_translationDir}
    )
  
    add_dependencies(UpdateTsFiles Update_${_tsSrcFileName})
    
    # TX file ***********************************************
    set(_txFile "${CMAKE_BINARY_DIR}/tx/razor-qt.${_tsSrcFileName}.tx_config")  
    string(REPLACE "${CMAKE_SOURCE_DIR}/" "" _tx_translationDir ${_translationDir})
    string(REPLACE "${CMAKE_SOURCE_DIR}/" "" _tx_tsSrcFile ${_tsSrcFile})
    
    file(WRITE ${_txFile}
        "[razor-qt.${_tsSrcFileNameWE}]\n"
        "type = QT\n"
        "source_lang = en\n"
        "source_file = ${_tx_tsSrcFile}\n"
        "file_filter = ${_tx_translationDir}/${_tsSrcFileNameWE}_<lang>.ts\n"
        "\n"
    )

    # QM files **********************************************    
    file(GLOB _tsFiles ${_translationDir}/${_tsSrcFileNameWE}_*.ts)    
    qt4_add_translation(_qmFilesLocal ${_tsFiles})
    install(FILES ${_qmFilesLocal} DESTINATION ${_installDir})
    set(${_qmFiles} ${_qmFilesLocal} PARENT_SCOPE)
endfunction(qtxdg_translate_ts)

