/// @remap(value,low1,high1,low2,high2)
function remap(argument0, argument1, argument2, argument3, argument4) {
	// @param value
	// @param Low1
	// @param High1
	// @param OutLow
	// @Param OutHigh

	var value=argument0
	var low1=argument1
	var high1=argument2
	var low2=argument3
	var high2=argument4

	return low2+(value-low1)*(high2-low2) / (high1-low1)


}
