// sentry_handler Clean Up. NOT USED (the object is never created; see Create).
// Frees every map and list made in Create. Skipped when "created" is false,
// i.e. for a duplicate instance that destroyed itself before making them.
// The device/os/runtime/app/browser maps are not listed because they were
// attached to precomputeContexts with ds_map_add_map and go with it.
if (created) {
	ds_map_destroy(precomputeSdk);
	ds_map_destroy(precomputeTags);
	ds_map_destroy(precomputeContexts);
	ds_map_destroy(precomputeExtra);
	ds_map_destroy(precomputeUser);

	ds_map_destroy(requestMap);
	ds_map_destroy(resultMap);
	ds_map_destroy(errorMap);

	ds_list_destroy(breadcrumbsList);

	ds_map_destroy(options);
}