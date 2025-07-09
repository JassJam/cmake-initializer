add_library(${THIS_PROJECT_NAME}_config INTERFACE)
add_library(${THIS_PROJECT_NAMESPACE}::config ALIAS ${THIS_PROJECT_NAME}_config)

include(./CreateConfigFile.cmake)

# create the config file of the project
# Default usage (installs to ${THIS_PROJECT_NAMESPACE}/config/config.hpp):
_create_config_file(${THIS_PROJECT_VERSION})

# Alternative usage with custom install location:
# _create_config_file(${THIS_PROJECT_VERSION} INSTALL_SUBDIR "myproject/include")

# install the component using the subdirectory set by _create_config_file
install_component(
	${THIS_PROJECT_NAME}_config
	INCLUDE_SUBDIR ${CONFIG_INSTALL_SUBDIR}
)