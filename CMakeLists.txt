cmake_minimum_required(VERSION 3.20)

project(dusk LANGUAGES CXX OBJCXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

add_executable(dusk
    main.mm
)

target_link_libraries(dusk
    "-framework Cocoa"
    "-framework QuartzCore"
    "-framework ServiceManagement"
)

set_target_properties(dusk PROPERTIES
    MACOSX_BUNDLE TRUE
    MACOSX_BUNDLE_GUI_IDENTIFIER "com.na.dusk"
    MACOSX_BUNDLE_BUNDLE_NAME "dusk"
    MACOSX_BUNDLE_INFO_PLIST
        "${CMAKE_CURRENT_SOURCE_DIR}/Info.plist"
)

set(DUSK_ICON
    "${CMAKE_CURRENT_SOURCE_DIR}/dusk.icns"
)

add_custom_command(TARGET dusk POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E copy
        "${DUSK_ICON}"
        "$<TARGET_BUNDLE_DIR:dusk>/Contents/Resources/dusk.icns"
)
