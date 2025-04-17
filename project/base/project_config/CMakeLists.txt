add_library(${THIS_PROJECT_NAME}_config INTERFACE)
add_library(${THIS_PROJECT_NAMESPACE}::config ALIAS ${THIS_PROJECT_NAME}_config)

include(./CreateConfigFile.cmake)

# create the config file of the project
_create_config_file(${PROJECT_VERSION})

# install the component
install_component(
	${THIS_PROJECT_NAME}_config
	INCLUDE_SUBDIR ${THIS_PROJECT_NAME}_config
)