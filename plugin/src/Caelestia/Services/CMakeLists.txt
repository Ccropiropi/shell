option(BUILD_HYPRLAND "Build Hyprland C++ plugin services" OFF)

set(HYPR_SOURCES)
if(BUILD_HYPRLAND)
    list(APPEND HYPR_SOURCES
        hyprdevices.cpp
        hyprextras.cpp
    )
endif()

qml_module(caelestia-services
    URI Caelestia.Services
    SOURCES
        service.cpp
        serviceref.cpp
        beattracker.cpp
        audiocollector.cpp
        audioprovider.cpp
        cavaprovider.cpp
        tickingservice.cpp
        sensorslib.cpp
        cpu.cpp
        gpu.cpp
        memory.cpp
        diskinfo.cpp
        storage.cpp
        lyriccandidate.cpp
        lyrics.cpp
        sessionmanager.cpp
        networkusage.cpp
        ${HYPR_SOURCES}
    LIBRARIES
        Qt::Concurrent
        Qt::DBus
        Qt::Network
        PkgConfig::Pipewire
        PkgConfig::Aubio
        PkgConfig::Cava
        Sensors::Sensors
        caelestia-util
        caelestia-core
        caelestia-config
    DEPENDENCIES
        Caelestia
        Caelestia.Config
)
