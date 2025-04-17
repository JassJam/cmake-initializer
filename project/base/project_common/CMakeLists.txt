add_library(${THIS_PROJECT_NAME}_common INTERFACE)
add_library(${THIS_PROJECT_NAMESPACE}::common ALIAS ${THIS_PROJECT_NAME}_common)

# link dependencies 'options' and 'config'
target_link_libraries(${THIS_PROJECT_NAME}_common INTERFACE
	${THIS_PROJECT_NAMESPACE}::options
	${THIS_PROJECT_NAMESPACE}::config
)

# install the component
install_component(
	${THIS_PROJECT_NAME}_common
	INCLUDE_SUBDIR ${THIS_PROJECT_NAME}_common
)