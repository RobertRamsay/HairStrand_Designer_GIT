/// @remap(value,low1,high1,low2,high2)
// -----------------------------------------------------------------------------
// remap  -  rescale a value from one range to another (straight line)
//
// value=low1 gives low2, value=high1 gives high2, halfway gives halfway.
// e.g. remap(270, 180, 360, 0, 1) = 0.5
//
// Used in one place: doMainStep, when drawing the Flow map in Hue mode
// (dirHue==1). The strand's direction, 180-360 degrees, is turned into 0-1 and
// used as the hue of that strand segment.
//
// No clamping: a value outside low1-high1 gives a result outside low2-high2.
// low1 == high1 divides by zero.
// -----------------------------------------------------------------------------
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
