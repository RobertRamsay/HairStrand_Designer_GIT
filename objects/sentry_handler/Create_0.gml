// =============================================================================
// OBJECT sentry_handler  -  crash/error reporting (GMSentry library).
// NOT USED, and incomplete in this project.
//
// Checked: it is in no room and nothing creates or mentions it.
// It is the handler object of GMSentry 1.0.12, a third-party library that
// sends error reports to a sentry.io account over HTTP. The library's
// scripts are NOT in this project: sentry_system_string, sentry_os_string,
// sentry_os_version_string, sentry_datetime_string, sentry_browser_string and
// sentry_set_option, all called below, do not exist anywhere else (checked).
// So this event would stop with an error on its first sentry_ call if the
// object were ever created.
//
// Hair Strand Designer therefore sends no crash reports and makes no network
// requests through this object. endpoint and the dsn keys below are never
// given a value.
//
// What the three events were for:
//   Create      one-time set-up: the maps used to track requests, plus
//               facts about the machine, OS and build that would be attached
//               to every report ("precompute..."), and default options.
//   Async HTTP  (Other_62) handles the server's reply to a sent report.
//   Clean Up    frees the maps and lists made here.
// "created" records that set-up finished, so Clean Up does not try to free
// things that were never made (the singleton exit below leaves it false).
// =============================================================================
created = false; // tracks creation for cleanup

// Singleton pattern
if (instance_number(object_index) > 1) {
	instance_destroy();
	exit;
}

endpoint = undefined;
dsnPublicKey = undefined;
dsnSecretKey = undefined;

gmSentryVersion = "1.0.12";
gmSentryLogFilePrefix = "gmsentry_";

// map for storing async requests
requestMap = ds_map_create();
resultMap = ds_map_create();
errorMap = ds_map_create();

// for last uuid4
lastUuid4 = undefined;

// precompute
precomputeSdk = ds_map_create();
ds_map_add(precomputeSdk, "name", "GMSentry");
ds_map_add(precomputeSdk, "version", gmSentryVersion);
	
precomputeTags = ds_map_create();
ds_map_add(precomputeTags, "device_string", sentry_system_string());
ds_map_add(precomputeTags, "os_get_config", os_get_config()); 
ds_map_add(precomputeTags, "GM_version", GM_version);

precomputeContexts = ds_map_create();
var device = ds_map_create();
ds_map_add(device, "os_device", os_device);
ds_map_add_map(precomputeContexts, "device", device);

var os = ds_map_create();
ds_map_add(os, "name", sentry_os_string());
ds_map_add(os, "version", sentry_os_version_string());
ds_map_add(os, "os_type", os_type); 
ds_map_add(os, "os_version", os_version);
ds_map_add(os, "os_is_paused", os_is_paused()); 
ds_map_add(os, "os_is_network_connected", os_is_network_connected()); 
ds_map_add(os, "os_get_language", os_get_language()); 
ds_map_add(os, "os_get_region", os_get_region()); 
// disabled for privacy :)
//ds_map_add_map(app, "os_get_info", os_get_info());
ds_map_add_map(precomputeContexts, "os", os);

var runtime = ds_map_create();
ds_map_add(runtime, "name", "GameMaker Studio");
ds_map_add(runtime, "version", GM_runtime_version);
ds_map_add_map(precomputeContexts, "runtime", runtime);

var app = ds_map_create();
ds_map_add(app, "app_start_time", sentry_datetime_string());
ds_map_add(app, "build_type", os_get_config());
ds_map_add(app, "code_is_compiled", code_is_compiled());
ds_map_add(app, "app_name", game_display_name);
ds_map_add(app, "app_version", GM_version);
ds_map_add(app, "debug_mode", debug_mode);
ds_map_add(app, "app_build", sentry_datetime_string(GM_build_date));
// disabled for privacy :)
//var params = ds_list_create();
//for (var i=0; i< parameter_count(); i++) {
//	ds_list_add(params, parameter_string(i));

//ds_map_add_list(app, "parameter", params);
ds_map_add_map(precomputeContexts, "app", app);

var browser = ds_map_create();
ds_map_add(browser, "name", sentry_browser_string());
ds_map_add(browser, "os_browser", os_browser);
ds_map_add_map(precomputeContexts, "browser", browser);

precomputeExtra = ds_map_create();
precomputeUser = ds_map_create();

// breadcrumbs
breadcrumbsList = ds_list_create();

// options and some defaulst
options = ds_map_create();
sentry_set_option("backup_before_send", true);
sentry_set_option("backup_autoclean", true);
sentry_set_option("breadcrumbs_max", 100);

created = true;