// sentry_handler Async HTTP (Other_62). NOT USED (the object is never created;
// see Create). Runs when any HTTP request gets a response. async_load is
// GameMaker's map describing that response.
// requestMap links GameMaker's request id to the report's uuid, so replies to
// requests this object did not send are ignored. Outcomes:
//   HTTP 200      -> store the reply in resultMap; delete the local backup
//                    file ("gmsentry_" + uuid) if backup_autoclean is on
//   status 1      -> still downloading, wait
//   anything else -> store "<http status> - <reply text>" in errorMap
//   no status     -> print the raw response to the debug console
var asyncId = ds_map_find_value(async_load,"id")
var requestUuid = ds_map_find_value(requestMap, string(asyncId));

if (not is_undefined(requestUuid)) {
	var asyncStatus = ds_map_find_value(async_load,"status")
	var asyncHttpStatus = ds_map_find_value(async_load, "http_status")
	var asyncResult = ds_map_find_value(async_load, "result")
	
	// check status
	if (asyncHttpStatus == 200) { // success
		ds_map_add(resultMap, requestUuid, asyncResult);
		ds_map_delete(requestMap, string(asyncId));
		
		if (ds_map_find_value(options, "backup_autoclean") == true) {
			var filename = gmSentryLogFilePrefix + requestUuid;
			if (file_exists(filename)) {
				file_delete(filename);
			}
		}
	}
	else if (asyncStatus == 1) { // downloading
		// don't need to do anything
	}
	else if (asyncStatus == 0 or not is_undefined(asyncHttpStatus)) { // completed, but returned non-200 status
		var resText = ""
		if (not is_undefined(asyncHttpStatus)) {
			resText += string_format(asyncHttpStatus, 0, 0) + " - ";
		}
		if (not is_undefined(asyncResult)) {
			resText += asyncResult;
		}
		ds_map_add(errorMap, requestUuid, resText);
		ds_map_delete(requestMap, string(asyncId));
	}
	else { // falure
		show_debug_message("Async event returned failure:")
		show_debug_message(json_encode(async_load))
	}

}