$ErrorActionPreference = "Stop"
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$parent = Split-Path -Parent $here
if (Test-Path (Join-Path $parent "CMakeLists.txt")) {
    $root = $parent
} elseif (Test-Path "C:\Projects\SynAxeOS\CMakeLists.txt") {
    $root = "C:\Projects\SynAxeOS"
} else {
    $root = "C:\Projects\SynAxe OS"
}
$axe = Join-Path $root "main\http_server\axe-os"

if (-not (Test-Path (Join-Path $axe "package.json"))) {
    Write-Host "Could not find $axe"
    Write-Host "This patch has to sit inside a clone of https://github.com/bitaxeorg/ESP-Miner"
    Write-Host "Do not patch the old folder. Run fresh.ps1 from this folder:"
    Write-Host "  powershell -ExecutionPolicy Bypass -File .\fresh.ps1"
    Write-Host "That clones a clean tree at C:\Projects\SynAxeOS and installs into it."
    exit 1
}

New-Item -ItemType Directory -Force -Path (Join-Path $axe "synaxe-www") | Out-Null
Copy-Item -Force (Join-Path $here "build-synaxe.js") (Join-Path $axe "build-synaxe.js")
Copy-Item -Force (Join-Path $here "synaxe-www\*") (Join-Path $axe "synaxe-www")
$bgB64 = Join-Path $here "synaxe-www\city-bg.b64"
if (Test-Path $bgB64) {
    $jpg = Join-Path $axe "synaxe-www\city-bg.jpg"
    [System.IO.File]::WriteAllBytes($jpg, [Convert]::FromBase64String([System.IO.File]::ReadAllText($bgB64)))
}

$pkgPath = Join-Path $axe "package.json"
$pkg = [System.IO.File]::ReadAllText($pkgPath)
$pkg2 = [regex]::Replace($pkg, '"build:no-api-gen"\s*:\s*"[^"]*"', '"build:no-api-gen": "node build-synaxe.js"')
if ($pkg2 -notmatch 'node build-synaxe.js') {
    Write-Host "package.json does not have a build:no-api-gen script."
    exit 1
}
$utf8 = New-Object System.Text.UTF8Encoding $false
[System.IO.File]::WriteAllText($pkgPath, $pkg2, $utf8)

$cmakePath = Join-Path $root "main\CMakeLists.txt"
$cmake = [System.IO.File]::ReadAllText($cmakePath)
$srcGlob = '"${WEB_SRC_DIR}/src/*.*"'
$wwwGlob = "`r`n        `"`${WEB_SRC_DIR}/synaxe-www/*`""
if ($cmake -notlike "*synaxe-www*") {
    if (-not $cmake.Contains($srcGlob)) {
        Write-Host "CMakeLists.txt did not contain the web source list. Continuing anyway."
    } else {
        $cmake = $cmake.Replace($srcGlob, $srcGlob + $wwwGlob)
    }
}
$tsconfig = '"${WEB_SRC_DIR}/tsconfig.app.json"'
$builder = "`r`n        `"`${WEB_SRC_DIR}/build-synaxe.js`""
if ($cmake -notlike "*build-synaxe.js*") {
    if ($cmake.Contains($tsconfig)) {
        $cmake = $cmake.Replace($tsconfig, $tsconfig + $builder)
    }
}
[System.IO.File]::WriteAllText($cmakePath, $cmake, $utf8)

$dist = Join-Path $axe "dist"
if (Test-Path $dist) { Remove-Item -Recurse -Force $dist }
$stamp = Join-Path $root "build\web_ui_build.stamp"
if (Test-Path $stamp) { Remove-Item -Force $stamp }

function Replace-Once($path, $old, $new) {
    $text = [System.IO.File]::ReadAllText($path)
    if ($text.Contains($new)) { return }
    if (-not $text.Contains($old)) {
        Write-Host "Skipped a firmware edit. Pattern not found in $path"
        return
    }
    $text = $text.Replace($old, $new)
    [System.IO.File]::WriteAllText($path, $text, $utf8)
    Write-Host "Updated $path"
}

$powerH = Join-Path $root "main\tasks\power_management_task.h"
Replace-Once $powerH "    float power;`r`n    float current;" "    float power;`r`n    float asic_power;`r`n    float current;"
Replace-Once $powerH "    float power;`n    float current;" "    float power;`n    float asic_power;`n    float current;"

$powerC = Join-Path $root "main\power\power.c"
Replace-Once $powerC "        pow_val   = vout * iout;`r`n        pow_val  += GLOBAL_STATE->DEVICE_CONFIG.family.power_offset;" "        pow_val   = vout * iout;`r`n        GLOBAL_STATE->POWER_MANAGEMENT_MODULE.asic_power = vout * iout;`r`n        pow_val  += GLOBAL_STATE->DEVICE_CONFIG.family.power_offset;"
Replace-Once $powerC "        pow_val   = vout * iout;`n        pow_val  += GLOBAL_STATE->DEVICE_CONFIG.family.power_offset;" "        pow_val   = vout * iout;`n        GLOBAL_STATE->POWER_MANAGEMENT_MODULE.asic_power = vout * iout;`n        pow_val  += GLOBAL_STATE->DEVICE_CONFIG.family.power_offset;"

$api = Join-Path $root "main\http_server\system_api_json.c"
Replace-Once $api 'cJSON_AddFloatToObject(root, "power", g->POWER_MANAGEMENT_MODULE.power);' "cJSON_AddFloatToObject(root, `"power`", g->POWER_MANAGEMENT_MODULE.power);`r`ncJSON_AddFloatToObject(root, `"asicPower`", g->POWER_MANAGEMENT_MODULE.asic_power);"
Replace-Once $api 'cJSON_AddFloatToObject(root, "hashRate_10m", g->SYSTEM_MODULE.hashrate_10m);' "cJSON_AddFloatToObject(root, `"hashRate_10m`", g->SYSTEM_MODULE.hashrate_10m);`r`ncJSON_AddFloatToObject(root, `"hashRate_15m`", g->SYSTEM_MODULE.hashrate_15m);"
Replace-Once $api 'yyjson_mut_obj_add_float(doc, root, "power", g->POWER_MANAGEMENT_MODULE.power);' "yyjson_mut_obj_add_float(doc, root, `"power`", g->POWER_MANAGEMENT_MODULE.power);`r`nyyjson_mut_obj_add_float(doc, root, `"asicPower`", g->POWER_MANAGEMENT_MODULE.asic_power);"
Replace-Once $api 'yyjson_mut_obj_add_float(doc, root, "hashRate_10m", g->SYSTEM_MODULE.hashrate_10m);' "yyjson_mut_obj_add_float(doc, root, `"hashRate_10m`", g->SYSTEM_MODULE.hashrate_10m);`r`nyyjson_mut_obj_add_float(doc, root, `"hashRate_15m`", g->SYSTEM_MODULE.hashrate_15m);"

$stateH = Join-Path $root "main\global_state.h"
Replace-Once $stateH "    float hashrate_10m;`r`n    float hashrate_1h;" "    float hashrate_10m;`r`n    float hashrate_15m;`r`n    float hashrate_1h;"
Replace-Once $stateH "    float hashrate_10m;`n    float hashrate_1h;" "    float hashrate_10m;`n    float hashrate_15m;`n    float hashrate_1h;"

$hashC = Join-Path $root "main\tasks\hashrate_monitor_task.c"
Replace-Once $hashC "#define HASHRATE_10M_SIZE 10" "#define HASHRATE_10M_SIZE 10`r`n#define HASHRATE_15M_SIZE 15"
Replace-Once $hashC "static float hashrate_10m[HASHRATE_10M_SIZE];" "static float hashrate_10m[HASHRATE_10M_SIZE];`r`nstatic float hashrate_15m[HASHRATE_15M_SIZE];`r`nstatic int hashrate_15m_count = 0;"
Replace-Once $hashC "    for (int i = 0; i < HASHRATE_10M_SIZE; i++) hashrate_10m[i] = nan_val;" "    for (int i = 0; i < HASHRATE_10M_SIZE; i++) hashrate_10m[i] = nan_val;`r`n    for (int i = 0; i < HASHRATE_15M_SIZE; i++) hashrate_15m[i] = nan_val;`r`n    hashrate_15m_count = 0;"
$avg15 = @'
    if (poll_count > 0 && (poll_count % HASHRATE_1M_SIZE) == 0) {
        hashrate_15m[hashrate_15m_count % HASHRATE_15M_SIZE] = SYSTEM_MODULE->hashrate_1m;
        hashrate_15m_count++;
    }
    SYSTEM_MODULE->hashrate_15m = hashrate_15m_count == 0
        ? SYSTEM_MODULE->hashrate_1m
        : calculate_avg_nan_safe(hashrate_15m, HASHRATE_15M_SIZE);

    poll_count++;
'@
Replace-Once $hashC "    poll_count++;" $avg15.TrimEnd()

function Add-AfterLine($path, $marker, $needle, $insert) {
    $text = [System.IO.File]::ReadAllText($path)
    if ($text.Contains($needle)) {
        Write-Host "Already in $path"
        return
    }
    $idx = $text.IndexOf($marker)
    if ($idx -lt 0) {
        Write-Host "Could not patch $path. Marker not found."
        return
    }
    $end = $text.IndexOf("`n", $idx)
    if ($end -lt 0) { $end = $text.Length - 1 }
    $text = $text.Insert($end + 1, $insert + "`r`n")
    [System.IO.File]::WriteAllText($path, $text, $utf8)
    Write-Host "Tuner patched $path"
}

function Add-Before($path, $marker, $needle, $insert) {
    $text = [System.IO.File]::ReadAllText($path)
    if ($text.Contains($needle)) {
        Write-Host "Already in $path"
        return
    }
    $idx = $text.IndexOf($marker)
    if ($idx -lt 0) {
        Write-Host "Could not patch $path. Marker not found."
        return
    }
    $text = $text.Insert($idx, $insert + "`r`n")
    [System.IO.File]::WriteAllText($path, $text, $utf8)
    Write-Host "Tuner patched $path"
}

$nvsH = Join-Path $root "main\nvs_config.h"
Add-AfterLine $nvsH "NVS_CONFIG_SELF_TEST_TEMP_MAX," "NVS_CONFIG_SYN_TUNE" @"
    NVS_CONFIG_SYN_TUNE,
    NVS_CONFIG_SYN_ASIC,
    NVS_CONFIG_SYN_VR,
    NVS_CONFIG_SYN_ERR,
"@

$nvsC = Join-Path $root "main\nvs_config.c"
Add-AfterLine $nvsC '[NVS_CONFIG_SELF_TEST_TEMP_MAX]' "syn_tune" @"
    [NVS_CONFIG_SYN_TUNE] = {.nvs_key_name = "syn_tune", .type = TYPE_BOOL, .default_value = {.b = false}, .rest_name = "synTune", .min = 0, .max = 1},
    [NVS_CONFIG_SYN_ASIC] = {.nvs_key_name = "syn_asic", .type = TYPE_U16, .default_value = {.u16 = 65}, .rest_name = "synAsic", .min = 45, .max = 75},
    [NVS_CONFIG_SYN_VR]   = {.nvs_key_name = "syn_vr",   .type = TYPE_U16, .default_value = {.u16 = 85}, .rest_name = "synVr",   .min = 55, .max = 105},
    [NVS_CONFIG_SYN_ERR]  = {.nvs_key_name = "syn_err",  .type = TYPE_U16, .default_value = {.u16 = 10}, .rest_name = "synErr",  .min = 1,  .max = 20},
"@

Add-AfterLine $api 'cJSON_AddNumberToObject(root, "temptarget"' '"synTune"' @"
    cJSON_AddNumberToObject(root, "synTune", nvs_config_get_bool(NVS_CONFIG_SYN_TUNE) ? 1 : 0);
    cJSON_AddNumberToObject(root, "synAsic", nvs_config_get_u16(NVS_CONFIG_SYN_ASIC));
    cJSON_AddNumberToObject(root, "synVr", nvs_config_get_u16(NVS_CONFIG_SYN_VR));
    cJSON_AddNumberToObject(root, "synErr", nvs_config_get_u16(NVS_CONFIG_SYN_ERR));
"@
Add-AfterLine $api 'yyjson_mut_obj_add_uint(doc, root, "temptarget"' '"synTune"' @"
    yyjson_mut_obj_add_uint(doc, root, "synTune", nvs_config_get_bool(NVS_CONFIG_SYN_TUNE) ? 1 : 0);
    yyjson_mut_obj_add_uint(doc, root, "synAsic", nvs_config_get_u16(NVS_CONFIG_SYN_ASIC));
    yyjson_mut_obj_add_uint(doc, root, "synVr", nvs_config_get_u16(NVS_CONFIG_SYN_VR));
    yyjson_mut_obj_add_uint(doc, root, "synErr", nvs_config_get_u16(NVS_CONFIG_SYN_ERR));
"@

$task = Join-Path $root "main\tasks\power_management_task.c"
Add-AfterLine $task "bool is_paused = false;" "TickType_t last_tune" "    TickType_t last_tune = 0;"
$tune = @'
        /* Auto tune removed. */
        nvs_config_set_bool(NVS_CONFIG_SYN_TUNE, false);

'@
$pmNow = [System.IO.File]::ReadAllText($task)
$pmNow = [regex]::Replace($pmNow, '(?s)[ \t]*else if \(nvs_config_get_bool\(NVS_CONFIG_SYN_TUNE\)\) \{.*?(?=[ \t]*uint16_t core_voltage)', '')
$pmNow = [regex]::Replace($pmNow, '(?s)[ \t]*if \(nvs_config_get_bool\(NVS_CONFIG_SYN_TUNE\)\) \{.*?(?=[ \t]*uint16_t core_voltage)', '')
$pmNow = $pmNow.Replace("    TickType_t last_tune = 0;`r`n", "")
$pmNow = $pmNow.Replace("    TickType_t last_tune = 0;`n", "")
$pmNow = $pmNow.Replace("    TickType_t last_tune = xTaskGetTickCount();`r`n", "")
$pmNow = $pmNow.Replace("    TickType_t last_tune = xTaskGetTickCount();`n", "")
[System.IO.File]::WriteAllText($task, $pmNow, $utf8)
Add-Before $task "uint16_t core_voltage = GLOBAL_STATE->SELF_TEST_MODULE.is_active" "Auto tune removed" $tune.TrimEnd()
Write-Host "Auto tune removed from the firmware. The clock only changes when you apply it."

$screenPath = Join-Path $root "main\screen.c"
$screen = [System.IO.File]::ReadAllText($screenPath)
$boot = @'
static lv_obj_t * create_scr_bitaxe_logo(const char * name, const char * board_version) {
    (void)name;
    (void)board_version;

    lv_obj_t * scr = lv_obj_create(NULL);

    lv_obj_t * title = lv_label_create(scr);
    lv_label_set_text(title, "SynAxe");
    lv_obj_set_style_text_letter_space(title, 0, 0);
    lv_obj_align(title, LV_ALIGN_CENTER, 0, 0);
    lv_obj_set_style_transform_pivot_x(title, LV_PCT(50), 0);
    lv_obj_set_style_transform_pivot_y(title, LV_PCT(50), 0);
    lv_obj_set_style_transform_scale_x(title, 512, 0);
    lv_obj_set_style_transform_scale_y(title, 512, 0);

    return scr;
}

static lv_obj_t * create_scr_osmu_logo(void) {
    lv_obj_t * scr = lv_obj_create(NULL);

    lv_obj_t * title = lv_label_create(scr);
    lv_label_set_text(title, "TDMC");
    lv_obj_set_style_text_letter_space(title, 0, 0);
    lv_obj_align(title, LV_ALIGN_CENTER, 0, 0);
    lv_obj_set_style_transform_pivot_x(title, LV_PCT(50), 0);
    lv_obj_set_style_transform_pivot_y(title, LV_PCT(50), 0);
    lv_obj_set_style_transform_scale_x(title, 512, 0);
    lv_obj_set_style_transform_scale_y(title, 512, 0);

    return scr;
}

'@
$screen2 = [regex]::Replace($screen, '(?s)static lv_obj_t \* create_scr_bitaxe_logo\(const char \* name, const char \* board_version\) \{.*?\r?\n\}\r?\n\r?\nstatic lv_obj_t \* create_scr_osmu_logo\([^)]*\) \{.*?\r?\n\}', $boot.TrimEnd())
if ($screen2 -eq $screen) {
    Write-Host "Could not patch the boot screens in screen.c"
} else {
    Write-Host "Boot screens patched"
}
if ($screen2 -notlike "*SCR_BY_LINE*") {
    $screen2 = $screen2.Replace("SCR_OSMU_LOGO,`r`n    SCR_URLS,", "SCR_OSMU_LOGO,`r`n    SCR_BY_LINE,`r`n    SCR_URLS,")
    $screen2 = $screen2.Replace("SCR_OSMU_LOGO,`n    SCR_URLS,", "SCR_OSMU_LOGO,`n    SCR_BY_LINE,`n    SCR_URLS,")
    $screen2 = $screen2.Replace("{0, 0, 0, 0, 0, 1000, 3000, 3000, 10000, 10000, 10000, 10000}", "{0, 0, 0, 0, 0, 1000, 3000, 3000, 3000, 10000, 10000, 10000, 10000}")
    $screen2 = $screen2.Replace("current_screen == SCR_OSMU_LOGO;", "current_screen == SCR_OSMU_LOGO || current_screen == SCR_BY_LINE;")
    $screen2 = $screen2.Replace("screens[SCR_OSMU_LOGO] = create_scr_osmu_logo();", "screens[SCR_OSMU_LOGO] = create_scr_osmu_logo();`r`n            screens[SCR_BY_LINE] = create_scr_by_line();")
}
if (-not $screen2.Contains("static lv_obj_t * create_scr_by_line")) {
    $by = @'
static lv_obj_t * create_scr_by_line(void) {
    lv_obj_t * scr = lv_obj_create(NULL);

    lv_obj_t * by = lv_label_create(scr);
    lv_label_set_text(by, "By");
    lv_obj_align(by, LV_ALIGN_CENTER, 0, -8);

    lv_obj_t * name = lv_label_create(scr);
    lv_label_set_text(name, "SyntheticDivision");
    lv_obj_align(name, LV_ALIGN_CENTER, 0, 6);

    return scr;
}

'@
    $placed = $false
    foreach ($anchor in @("esp_err_t screen_start", "static lv_obj_t * create_scr_urls()", "static lv_obj_t * create_scr_urls(void)")) {
        if ($screen2.Contains($anchor)) {
            $screen2 = $screen2.Replace($anchor, $by + $anchor)
            $placed = $true
            break
        }
    }
    if (-not $placed) {
        Write-Host "Could not add create_scr_by_line. No place to insert it was found."
    } else {
        Write-Host "Added the SyntheticDivision boot screen"
    }
}
if (-not $screen2.Contains("static lv_obj_t * create_scr_by_line")) {
    Write-Host "screen.c still has no create_scr_by_line function. Build will fail."
    exit 1
}
$welcomeOld = "Welcome to your new Bitaxe! Connect to the configuration Wi-Fi and connect the Bitaxe to your network."
$welcomeNew = "Welcome to your new SynAxe! Connect to the configuration Wi-Fi and connect the SynAxe to your network."
if ($screen2.Contains($welcomeOld)) {
    $screen2 = $screen2.Replace($welcomeOld, $welcomeNew)
    Write-Host "Wi-Fi setup screen says SynAxe"
} elseif ($screen2.Contains($welcomeNew)) {
    Write-Host "Wi-Fi setup screen already says SynAxe"
} else {
    Write-Host "Could not find the Bitaxe welcome line in screen.c"
    exit 1
}
[System.IO.File]::WriteAllText($screenPath, $screen2, $utf8)
Write-Host "screen.c contains create_scr_by_line"

$connectPath = Join-Path $root "components\connect\connect.c"
$connect = [System.IO.File]::ReadAllText($connectPath)
$apOld = 'snprintf(GLOBAL_STATE->SYSTEM_MODULE.ap_ssid, sizeof(GLOBAL_STATE->SYSTEM_MODULE.ap_ssid), "Bitaxe_%02X%02X", mac[4], mac[5]);'
$apNew = 'snprintf(GLOBAL_STATE->SYSTEM_MODULE.ap_ssid, sizeof(GLOBAL_STATE->SYSTEM_MODULE.ap_ssid), "synaxe_%02X%02X", mac[4], mac[5]);'
if ($connect.Contains($apOld)) {
    $connect = $connect.Replace($apOld, $apNew)
    [System.IO.File]::WriteAllText($connectPath, $connect, $utf8)
    Write-Host "Configuration Wi-Fi name is synaxe_ plus the last of the MAC"
} elseif ($connect.Contains($apNew)) {
    Write-Host "Configuration Wi-Fi name is already synaxe_"
} else {
    Write-Host "Could not find the Bitaxe_ configuration Wi-Fi name in connect.c"
    exit 1
}

$idfYml = Join-Path $root "main\idf_component.yml"
if (Test-Path $idfYml) {
    $yml = [System.IO.File]::ReadAllText($idfYml)
    if ($yml -match '>=\s*6\.0') {
        Write-Host "This ESP-Miner wants ESP-IDF 6. Switching the tree to v2.14.2 for ESP-IDF 5.5.6."
        & git -C $root checkout v2.14.2
        if ($LASTEXITCODE -ne 0) {
            Write-Host "git checkout v2.14.2 failed. Run it from C:\Projects\SynAxe OS and then run this installer again."
            exit 1
        }
        & git -C $root submodule update --init --recursive
        if ($LASTEXITCODE -ne 0) {
            Write-Host "git submodule update failed."
            exit 1
        }
        $buildDir = Join-Path $root "build"
        if (Test-Path $buildDir) { Remove-Item -Recurse -Force $buildDir }
        Write-Host "Now on ESP-Miner v2.14.2."
    }
}

$vcore = Join-Path $root "main\power\vcore.c"
$vcoreText = [System.IO.File]::ReadAllText($vcore)
$oldTree = $vcoreText.Contains("default: // MAX, ULTRA, SUPRA, GAMMA")
if ($oldTree) {
    Write-Host "ESP-Miner v2.14.2 voltage table found. Applying the 601a 12V profile."
    $dev = Join-Path $root "main\device_config.h"
    $devText = [System.IO.File]::ReadAllText($dev)
    if (-not $devText.Contains("GAMMA_12V")) {
        $devText = $devText.Replace("    GAMMA_TURBO,`r`n} Family;", "    GAMMA_TURBO,`r`n    GAMMA_12V,`r`n} Family;")
        $devText = $devText.Replace("    GAMMA_TURBO,`n} Family;", "    GAMMA_TURBO,`n    GAMMA_12V,`n} Family;")
        $family = 'static const FamilyConfig FAMILY_GAMMA_12V  = { .id = GAMMA_12V,  .name = "Gamma12V", .asic = ASIC_BM1370,   .asic_count = 1, .max_power =  40, .power_offset = 5,  .nominal_voltage = 12, .voltage_domains = 1, .swarm_color = "green",    };'
        $devText = $devText.Replace("static const FamilyConfig FAMILY_GAMMA_TURBO", $family + "`r`n" + "static const FamilyConfig FAMILY_GAMMA_TURBO")
        $devText = $devText.Replace("    FAMILY_GAMMA_TURBO,", "    FAMILY_GAMMA_TURBO,`r`n    FAMILY_GAMMA_12V,")
        $board = '    { .board_version = "601a", .family = FAMILY_GAMMA_12V, .EMC2101 = true, .emc_ideality_factor = 0x24, .emc_beta_compensation = 0x00, .TPS546 = true, .power_consumption_target = 19, },'
        $devText = $devText.Replace('{ .board_version = "601",', $board + "`r`n    { .board_version = `"601`",")
        [System.IO.File]::WriteAllText($dev, $devText, $utf8)
    }
    if (-not $vcoreText.Contains("case GAMMA_12V:")) {
        $case = @'
    case GAMMA_12V:
        /* 601a is a 12V Gamma. Commands stop at 1.225V. */
        config.TPS546_INIT_PHASE = TPS546_INIT_PHASE_SINGLE;
        config.TPS546_INIT_VIN_ON = 11.0f;
        config.TPS546_INIT_VIN_OFF = 10.5f;
        config.TPS546_INIT_VIN_UV_WARN_LIMIT = 11.0f;
        config.TPS546_INIT_VIN_OV_FAULT_LIMIT = 14.0f;
        config.TPS546_INIT_SCALE_LOOP = 0.25f;
        config.TPS546_INIT_VOUT_MIN = 0.70f;
        config.TPS546_INIT_VOUT_MAX = 1.60f;
        config.TPS546_INIT_VOUT_COMMAND = 1.15f;
        config.TPS546_INIT_IOUT_OC_WARN_LIMIT = 25.00;
        config.TPS546_INIT_IOUT_OC_FAULT_LIMIT = 30.00;
        config.TPS546_INIT_STACK_CONFIG = 0x0000;
        config.TPS546_INIT_SYNC_CONFIG = 0x10;
        break;

'@
        $vcoreText = $vcoreText.Replace("    default: // MAX, ULTRA, SUPRA, GAMMA", $case + "    default: // MAX, ULTRA, SUPRA, GAMMA")
    }
    if (-not $vcoreText.Contains("601a core clamped")) {
        $vcoreText = $vcoreText.Replace("ESP_RETURN_ON_ERROR(TPS546_set_vout(core_voltage * voltage_domains), TAG, `"TPS546 set voltage failed!`");", @'
float volts = core_voltage;
        if (volts != 0.0f && GLOBAL_STATE->DEVICE_CONFIG.family.id == GAMMA_12V) {
            if (volts < 1.10f) volts = 1.10f;
            if (volts > 1.225f) volts = 1.225f;
            if (volts != core_voltage) ESP_LOGW(TAG, "601a core clamped from %.3fV to %.3fV", core_voltage, volts);
        }
        ESP_RETURN_ON_ERROR(TPS546_set_vout(volts * voltage_domains), TAG, "TPS546 set voltage failed!");
'@)
    }
    if (-not $vcoreText.Contains("case GAMMA_12V:") -or -not $vcoreText.Contains("601a core clamped")) {
        Write-Host "Could not add the 601a 12V voltage table."
        exit 1
    }
    [System.IO.File]::WriteAllText($vcore, $vcoreText, $utf8)
    $tps = Join-Path $root "main\power\TPS546.c"
    $tpsText = [System.IO.File]::ReadAllText($tps)
    if (-not $tpsText.Contains("601a absolute vout limits")) {
        $tpsText = $tpsText.Replace("smb_write_word(PMBUS_VOUT_OV_FAULT_LIMIT, float_2_ulinear16(TPS546_INIT_VOUT_OV_FAULT_LIMIT));", "smb_write_word(PMBUS_VOUT_OV_FAULT_LIMIT, float_2_ulinear16(tps546_config.TPS546_INIT_VOUT_MAX)); /* 601a absolute vout limits */")
        $tpsText = $tpsText.Replace("smb_write_word(PMBUS_VOUT_OV_WARN_LIMIT, float_2_ulinear16(TPS546_INIT_VOUT_OV_WARN_LIMIT));", "smb_write_word(PMBUS_VOUT_OV_WARN_LIMIT, float_2_ulinear16(tps546_config.TPS546_INIT_VOUT_MAX));")
    }
    if (-not $tpsText.Contains("601a absolute vout limits")) {
        Write-Host "Could not raise the core overvoltage trip off 1.25V."
        exit 1
    }
    [System.IO.File]::WriteAllText($tps, $tpsText, $utf8)
    Write-Host "601a core command stops at 1225 mV and 650 MHz. Input is 11.0V on, 10.5V off, 14.0V overvoltage."
}

if (-not $oldTree) {
$dev = Join-Path $root "main\device_config.h"
$devText = [System.IO.File]::ReadAllText($dev)
if (-not $devText.Contains("TPS546_CONFIG_GAMMA_12V")) {
    $devText = $devText.Replace("extern const TPS546_CONFIG TPS546_CONFIG_GAMMA_HEX;", "extern const TPS546_CONFIG TPS546_CONFIG_GAMMA_HEX;`r`nextern const TPS546_CONFIG TPS546_CONFIG_GAMMA_12V;")
    $devText = $devText.Replace("    NAJA_DUO,`r`n} Family;", "    NAJA_DUO,`r`n    GAMMA_12V,`r`n} Family;")
    $devText = $devText.Replace("    NAJA_DUO,`n} Family;", "    NAJA_DUO,`n    GAMMA_12V,`n} Family;")
    $family = @'
static const FamilyConfig FAMILY_GAMMA_12V  = { .id = GAMMA_12V,  .name = "Gamma12V", .asic = ASIC_BM1370,   .asic_count = 1, .max_power =  40, .power_offset = 5,  .nominal_voltage = 12, .voltage_domains = 1, .swarm_color = "green",    .tps546_config = &TPS546_CONFIG_GAMMA_12V, };
'@
    $devText = $devText.Replace("static const FamilyConfig FAMILY_GAMMA_HEX", $family + "static const FamilyConfig FAMILY_GAMMA_HEX")
    $devText = $devText.Replace("    FAMILY_NAJA_DUO,", "    FAMILY_NAJA_DUO,`r`n    FAMILY_GAMMA_12V,")
    $board = '    { .board_version = "601a", .family = FAMILY_GAMMA_12V, .pins = BITAXE_ORIGINAL_PINS, .EMC2101 = true, .emc_ideality_factor = 0x24, .emc_beta_compensation = 0x00, .TPS546 = true, .power_consumption_target = 19, },'
    $devText = $devText.Replace('{ .board_version = "601",', $board + "`r`n    { .board_version = `"601`",")
}
if (-not $devText.Contains('board_version = "601a"')) {
    Write-Host "Could not add the 601a 12V board. Official ESP-Miner has no 601a, and a 5V Gamma profile would trip the input at 6.5V."
    exit 1
}
[System.IO.File]::WriteAllText($dev, $devText, $utf8)
Write-Host "Board 601a is a 12V Gamma. Board 601 stays the official 5V profile."

$tpsH = Join-Path $root "main\power\TPS546.h"
$tpsHText = [System.IO.File]::ReadAllText($tpsH)
if (-not $tpsHText.Contains("TPS546_CONFIG_GAMMA_12V")) {
    $tpsHText = $tpsHText.Replace("extern const TPS546_CONFIG TPS546_CONFIG_GAMMA_HEX;", "extern const TPS546_CONFIG TPS546_CONFIG_GAMMA_HEX;`r`nextern const TPS546_CONFIG TPS546_CONFIG_GAMMA_12V;")
    [System.IO.File]::WriteAllText($tpsH, $tpsHText, $utf8)
}

$tps = Join-Path $root "main\power\TPS546.c"
$tpsText = [System.IO.File]::ReadAllText($tps)
if (-not $tpsText.Contains("TPS546_CONFIG_GAMMA_12V")) {
    $cfg = @'
const TPS546_CONFIG TPS546_CONFIG_GAMMA_12V = {
    .TPS546_INIT_PHASE = TPS546_INIT_PHASE_SINGLE,
    .TPS546_INIT_VIN_ON = 11.0,
    .TPS546_INIT_VIN_OFF = 10.5,
    .TPS546_INIT_VIN_UV_WARN_LIMIT = 11.0,
    .TPS546_INIT_VIN_OV_FAULT_LIMIT = 14.0,
    .TPS546_INIT_SCALE_LOOP = 0.25,
    .TPS546_INIT_VOUT_MIN = 0.70,
    .TPS546_INIT_VOUT_MAX = 1.60,
    .TPS546_INIT_VOUT_COMMAND = 1.15,
    .TPS546_INIT_IOUT_OC_WARN_LIMIT = 25.00,
    .TPS546_INIT_IOUT_OC_FAULT_LIMIT = 30.00,
    .TPS546_INIT_STACK_CONFIG = TPS546_SINGLE_PHASE_STACK_CONFIG,
    .TPS546_INIT_SYNC_CONFIG = 0x10,
    .TPS546_INIT_FREQUENCY = TPS546_DEFAULT_FREQUENCY,
    .TPS546_INIT_COMPENSATION_CONFIG = {0},
};

'@
    $tpsText = $tpsText.Replace("const TPS546_CONFIG TPS546_CONFIG_HEX = {", $cfg + "const TPS546_CONFIG TPS546_CONFIG_HEX = {")
}
if (-not $tpsText.Contains("601a absolute vout limits")) {
    $limit = @'
static float TPS546_absolute_limit(float vout_command, float ratio)
{
    /* The register is volts, not a multiplier. Writing 1.25 trips at 1.25V. */
    float volts = vout_command * ratio;
    float ceiling = tps546_config.TPS546_INIT_VOUT_MAX;
    if (ceiling > 0.0f && volts > ceiling) volts = ceiling;
    if (volts < vout_command) volts = vout_command;
    return volts;
}

static esp_err_t TPS546_write_vout_limit_ratios(float vout_command)
{
    /* 601a absolute vout limits */
    float ov_fault = TPS546_absolute_limit(vout_command, TPS546_INIT_VOUT_OV_FAULT_LIMIT);
    float ov_warn = TPS546_absolute_limit(vout_command, TPS546_INIT_VOUT_OV_WARN_LIMIT);
    float margin_high = TPS546_absolute_limit(vout_command, TPS546_INIT_VOUT_MARGIN_HIGH);
    float margin_low = vout_command * TPS546_INIT_VOUT_MARGIN_LOW;
    float uv_warn = vout_command * TPS546_INIT_VOUT_UV_WARN_LIMIT;
    float uv_fault = vout_command * TPS546_INIT_VOUT_UV_FAULT_LIMIT;

    ESP_LOGI(TAG, "Setting VOUT_OV_FAULT_LIMIT: %.2fV", ov_fault);
    ESP_RETURN_ON_ERROR(smb_write_word(PMBUS_VOUT_OV_FAULT_LIMIT, float_2_ulinear16(ov_fault)),
                        TAG, "Failed to write VOUT_OV_FAULT_LIMIT");
    ESP_LOGI(TAG, "Setting VOUT_OV_WARN_LIMIT: %.2fV", ov_warn);
    ESP_RETURN_ON_ERROR(smb_write_word(PMBUS_VOUT_OV_WARN_LIMIT, float_2_ulinear16(ov_warn)),
                        TAG, "Failed to write VOUT_OV_WARN_LIMIT");
    ESP_LOGI(TAG, "Setting VOUT_MARGIN_HIGH: %.2fV", margin_high);
    ESP_RETURN_ON_ERROR(smb_write_word(PMBUS_VOUT_MARGIN_HIGH, float_2_ulinear16(margin_high)),
                        TAG, "Failed to write VOUT_MARGIN_HIGH");
    ESP_LOGI(TAG, "Setting VOUT_MARGIN_LOW: %.2fV", margin_low);
    ESP_RETURN_ON_ERROR(smb_write_word(PMBUS_VOUT_MARGIN_LOW, float_2_ulinear16(margin_low)),
                        TAG, "Failed to write VOUT_MARGIN_LOW");
    ESP_LOGI(TAG, "Setting VOUT_UV_WARN_LIMIT: %.2fV", uv_warn);
    ESP_RETURN_ON_ERROR(smb_write_word(PMBUS_VOUT_UV_WARN_LIMIT, float_2_ulinear16(uv_warn)),
                        TAG, "Failed to write VOUT_UV_WARN_LIMIT");
    ESP_LOGI(TAG, "Setting VOUT_UV_FAULT_LIMIT: %.2fV", uv_fault);
    ESP_RETURN_ON_ERROR(smb_write_word(PMBUS_VOUT_UV_FAULT_LIMIT, float_2_ulinear16(uv_fault)),
                        TAG, "Failed to write VOUT_UV_FAULT_LIMIT");
    return ESP_OK;
}
'@
    $tpsText = [regex]::Replace($tpsText, '(?s)static esp_err_t TPS546_write_vout_limit_ratios\(float vout_command\).*?\n\}', $limit.TrimEnd(), 1)
}
if (-not $tpsText.Contains("TPS546_CONFIG_GAMMA_12V") -or -not $tpsText.Contains("601a absolute vout limits")) {
    Write-Host "Could not add the 12V TPS profile or the absolute overvoltage limit."
    exit 1
}
[System.IO.File]::WriteAllText($tps, $tpsText, $utf8)
Write-Host "601a input is 11.0V on, 10.5V off, 14.0V overvoltage. Core command is 1100 to 1225 mV. Clock is 400 to 650 MHz."

$vcore = Join-Path $root "main\power\vcore.c"
$vcoreText = [System.IO.File]::ReadAllText($vcore)
if (-not $vcoreText.Contains("601a is a 12V Gamma")) {
    $force = @'
    if (family->id == GAMMA_12V) {
        /* 601a is a 12V Gamma. Do not let a saved 5V profile arm a 6.5V input fault. */
        config.TPS546_INIT_VIN_ON = 11.0f;
        config.TPS546_INIT_VIN_OFF = 10.5f;
        config.TPS546_INIT_VIN_UV_WARN_LIMIT = 11.0f;
        config.TPS546_INIT_VIN_OV_FAULT_LIMIT = 14.0f;
        config.TPS546_INIT_SCALE_LOOP = 0.25f;
        config.TPS546_INIT_VOUT_MIN = 0.70f;
        config.TPS546_INIT_VOUT_MAX = 1.60f;
        if (config.TPS546_INIT_VOUT_COMMAND > 1.40f || config.TPS546_INIT_VOUT_COMMAND < 1.00f) {
            config.TPS546_INIT_VOUT_COMMAND = 1.15f;
        }
    }

'@
    $vcoreText = $vcoreText.Replace("    log_tps546_config(family, &config);", $force + "    log_tps546_config(family, &config);")
}
if (-not $vcoreText.Contains("601a core clamped")) {
    $vcoreText = $vcoreText.Replace("ESP_RETURN_ON_ERROR(TPS546_set_vout(core_voltage * voltage_domains), TAG, `"TPS546 set voltage failed!`");", @'
float volts = core_voltage;
        if (volts != 0.0f && GLOBAL_STATE->DEVICE_CONFIG.family.id == GAMMA_12V) {
            if (volts < 1.10f) volts = 1.10f;
            if (volts > 1.225f) volts = 1.225f;
            if (volts != core_voltage) ESP_LOGW(TAG, "601a core clamped from %.3fV to %.3fV", core_voltage, volts);
        }
        ESP_RETURN_ON_ERROR(TPS546_set_vout(volts * voltage_domains), TAG, "TPS546 set voltage failed!");
'@)
}
if (-not $vcoreText.Contains("601a is a 12V Gamma") -or -not $vcoreText.Contains("601a core clamped")) {
    Write-Host "Could not lock the 601a input to 12V."
    exit 1
}
[System.IO.File]::WriteAllText($vcore, $vcoreText, $utf8)
}

$pm = Join-Path $root "main\tasks\power_management_task.c"
$pmText = [System.IO.File]::ReadAllText($pm)
if (-not $pmText.Contains("601a voltage and clock clamp")) {
    $inserted = $false
    foreach ($needle in @(
        "float asic_frequency = nvs_config_get_float(NVS_CONFIG_ASIC_FREQUENCY);",
        ": nvs_config_get_float(NVS_CONFIG_ASIC_FREQUENCY);"
    )) {
        if ($pmText.Contains($needle)) {
            $pmText = $pmText.Replace($needle, $needle + @'

        /* 601a voltage and clock clamp */
        /* 601a 25 MHz steps */
        if (GLOBAL_STATE->DEVICE_CONFIG.family.id == GAMMA_12V) {
            uint16_t saved_voltage = core_voltage;
            float saved_frequency = asic_frequency;
            if (core_voltage > 1225) core_voltage = 1225;
            if (core_voltage < 1100) core_voltage = 1100;
            core_voltage = (uint16_t)(((core_voltage + 12) / 25) * 25);
            if (asic_frequency > 650.0f) asic_frequency = 650.0f;
            if (asic_frequency < 400.0f) asic_frequency = 400.0f;
            asic_frequency = (float)(((int)(asic_frequency + 12.5f) / 25) * 25);
            if (core_voltage != saved_voltage) {
                nvs_config_set_u16(NVS_CONFIG_ASIC_VOLTAGE, core_voltage);
                ESP_LOGW(TAG, "601a voltage held at %u mV", core_voltage);
            }
            if (asic_frequency != saved_frequency) {
                nvs_config_set_float(NVS_CONFIG_ASIC_FREQUENCY, asic_frequency);
                ESP_LOGW(TAG, "601a frequency held at %.0f MHz", asic_frequency);
            }
        }
'@)
            $inserted = $true
            break
        }
    }
    if (-not $inserted -or -not $pmText.Contains("601a voltage and clock clamp")) {
        Write-Host "Could not add the 601a runtime clamp."
        exit 1
    }
    [System.IO.File]::WriteAllText($pm, $pmText, $utf8)
}

$nvs = Join-Path $root "main\nvs_config.c"
$nvsText = [System.IO.File]::ReadAllText($nvs)
$nvsText = $nvsText.Replace('.rest_name = "frequency",                          .min = 400,  .max = 690}', '.rest_name = "frequency",                          .min = 400,  .max = 650}')
$nvsText = $nvsText.Replace('.rest_name = "frequency",                          .min = 1,  .max = UINT16_MAX}', '.rest_name = "frequency",                          .min = 400,  .max = 650}')
$nvsText = $nvsText.Replace('.rest_name = "frequency",                          .min = 400,  .max = 600}', '.rest_name = "frequency",                          .min = 400,  .max = 650}')
$nvsText = $nvsText.Replace('.rest_name = "frequency",                          .min = 400,  .max = 1100}', '.rest_name = "frequency",                          .min = 400,  .max = 650}')
$nvsText = $nvsText.Replace('.rest_name = "coreVoltage",                        .min = 1000,  .max = 1225}', '.rest_name = "coreVoltage",                        .min = 1100,  .max = 1225}')
$nvsText = $nvsText.Replace('.rest_name = "coreVoltage",                        .min = 1,  .max = UINT16_MAX}', '.rest_name = "coreVoltage",                        .min = 1100,  .max = 1225}')
$nvsText = $nvsText.Replace('.rest_name = "coreVoltage",                        .min = 1000,  .max = 1150}', '.rest_name = "coreVoltage",                        .min = 1100,  .max = 1225}')
$nvsText = $nvsText.Replace('.rest_name = "coreVoltage",                        .min = 1000,  .max = 1300}', '.rest_name = "coreVoltage",                        .min = 1100,  .max = 1225}')
$nvsText = $nvsText.Replace('.rest_name = "coreVoltage",                        .min = 1000,  .max = 1325}', '.rest_name = "coreVoltage",                        .min = 1100,  .max = 1225}')
$nvsText = $nvsText.Replace('.rest_name = "coreVoltage",                        .min = 1000,  .max = 1400}', '.rest_name = "coreVoltage",                        .min = 1100,  .max = 1225}')
[System.IO.File]::WriteAllText($nvs, $nvsText, $utf8)
$vcoreNow = [System.IO.File]::ReadAllText($vcore)
$vcoreRaised = $vcoreNow.Replace("config.TPS546_INIT_VOUT_MAX = 1.325f;", "config.TPS546_INIT_VOUT_MAX = 1.60f;")
$vcoreRaised = $vcoreRaised.Replace("config.TPS546_INIT_VOUT_MAX = 1.45f;", "config.TPS546_INIT_VOUT_MAX = 1.60f;")
$vcoreRaised = $vcoreRaised.Replace("config.TPS546_INIT_VOUT_MIN = 1.00f;", "config.TPS546_INIT_VOUT_MIN = 0.70f;")
$vcoreRaised = $vcoreRaised.Replace("if (volts < 1.00f) volts = 1.00f;", "if (volts < 1.10f) volts = 1.10f;")
$vcoreRaised = $vcoreRaised.Replace("if (volts > 1.30f) volts = 1.30f;", "if (volts > 1.225f) volts = 1.225f;")
$vcoreRaised = $vcoreRaised.Replace("if (volts > 1.150f) volts = 1.150f;", "if (volts > 1.225f) volts = 1.225f;")
$vcoreRaised = $vcoreRaised.Replace("if (volts > 1.325f) volts = 1.325f;", "if (volts > 1.225f) volts = 1.225f;")
if ($vcoreRaised -ne $vcoreNow) {
    [System.IO.File]::WriteAllText($vcore, $vcoreRaised, $utf8)
    Write-Host "601a core command stops at 1225 mV."
}
$pmNow = [System.IO.File]::ReadAllText($pm)
$pmRaised = $pmNow.Replace("if (core_voltage > 1300) core_voltage = 1300;", "if (core_voltage > 1225) core_voltage = 1225;")
$pmRaised = $pmRaised.Replace("if (core_voltage > 1150) core_voltage = 1150;", "if (core_voltage > 1225) core_voltage = 1225;")
$pmRaised = $pmRaised.Replace("if (core_voltage > 1325) core_voltage = 1325;", "if (core_voltage > 1225) core_voltage = 1225;")
$pmRaised = $pmRaised.Replace("if (core_voltage > 1400) core_voltage = 1400;", "if (core_voltage > 1225) core_voltage = 1225;")
$pmRaised = $pmRaised.Replace("if (asic_frequency > 600.0f) asic_frequency = 600.0f;", "if (asic_frequency > 650.0f) asic_frequency = 650.0f;")
$pmRaised = $pmRaised.Replace("if (asic_frequency > 690.0f) asic_frequency = 690.0f;", "if (asic_frequency > 650.0f) asic_frequency = 650.0f;")
$pmRaised = $pmRaised.Replace("if (asic_frequency > 1100.0f) asic_frequency = 1100.0f;", "if (asic_frequency > 650.0f) asic_frequency = 650.0f;")
$pmRaised = $pmRaised.Replace("if (core_voltage < 1000) core_voltage = 1000;", "if (core_voltage < 1100) core_voltage = 1100;")
if ($pmRaised -ne $pmNow) {
    [System.IO.File]::WriteAllText($pm, $pmRaised, $utf8)
    $pmNow = $pmRaised
}
if (-not $pmNow.Contains("601a 25 MHz steps")) {
    $held = @'
        /* 601a voltage and clock clamp */
        /* 601a 25 MHz steps */
        if (GLOBAL_STATE->DEVICE_CONFIG.family.id == GAMMA_12V) {
            uint16_t saved_voltage = core_voltage;
            float saved_frequency = asic_frequency;
            if (core_voltage > 1225) core_voltage = 1225;
            if (core_voltage < 1100) core_voltage = 1100;
            core_voltage = (uint16_t)(((core_voltage + 12) / 25) * 25);
            if (asic_frequency > 650.0f) asic_frequency = 650.0f;
            if (asic_frequency < 400.0f) asic_frequency = 400.0f;
            asic_frequency = (float)(((int)(asic_frequency + 12.5f) / 25) * 25);
            if (core_voltage != saved_voltage) {
                nvs_config_set_u16(NVS_CONFIG_ASIC_VOLTAGE, core_voltage);
                ESP_LOGW(TAG, "601a voltage held at %u mV", core_voltage);
            }
            if (asic_frequency != saved_frequency) {
                nvs_config_set_float(NVS_CONFIG_ASIC_FREQUENCY, asic_frequency);
                ESP_LOGW(TAG, "601a frequency held at %.0f MHz", asic_frequency);
            }
        }
'@
    $pmHeld = [regex]::Replace($pmNow, '(?s)/\* 601a voltage and clock clamp \*/\s*if \(GLOBAL_STATE->DEVICE_CONFIG\.family\.id == GAMMA_12V\) \{.*?\n        \}', $held.Trim(), 1)
    if ($pmHeld -eq $pmNow) {
        Write-Host "Could not hold a saved clock on the 25 MHz and 25 mV steps."
        exit 1
    }
    [System.IO.File]::WriteAllText($pm, $pmHeld, $utf8)
    Write-Host "A saved clock is pulled onto 400 to 650 MHz and 1100 to 1225 mV, in steps of 25."
}

$http = Join-Path $root "main\http_server\http_server.c"
$httpText = [System.IO.File]::ReadAllText($http)
if (-not $httpText.Contains("SynAxe OS updates are disabled")) {
    $otaRx = [regex]'esp_err_t POST_OTA_update\(httpd_req_t \* req\)\s*\{'
    $wwwRx = [regex]'esp_err_t POST_WWW_update\(httpd_req_t \* req\)\s*\{'
    $otaNew = "esp_err_t POST_OTA_update(httpd_req_t * req)`r`n{`r`n    httpd_resp_send_err(req, HTTPD_403_FORBIDDEN, `"SynAxe OS updates are disabled`");`r`n    return ESP_OK;"
    $wwwNew = "esp_err_t POST_WWW_update(httpd_req_t * req)`r`n{`r`n    httpd_resp_send_err(req, HTTPD_403_FORBIDDEN, `"SynAxe OS updates are disabled`");`r`n    return ESP_OK;"
    $httpNext = $otaRx.Replace($httpText, $otaNew, 1)
    $httpNext = $wwwRx.Replace($httpNext, $wwwNew, 1)
    if ($httpNext -eq $httpText) {
        Write-Host "Could not disable the firmware update endpoints."
        exit 1
    }
    [System.IO.File]::WriteAllText($http, $httpNext, $utf8)
    Write-Host "Firmware and web updates are refused."
}

$tps = Join-Path $root "main\power\TPS546.c"
$tpsText = [System.IO.File]::ReadAllText($tps)
$windowFn = @'
static float TPS546_fault_ratio(float command)
{
    /* (40h) is a percent of VOUT_COMMAND. Hardware is 105% to 140% in 2.5% steps.
     * 1.55V / command, rounded up to the next legal step. Above 140% clamps to 140%.
     */
    int milli;
    int up;
    if (command < 0.50f) {
        return 1.25f;
    }
    milli = (int)((1.55f / command) * 1000.0f + 0.5f);
    if (milli < 1050) {
        milli = 1050;
    }
    if (milli > 1400) {
        milli = 1400;
    }
    up = ((milli - 1050 + 24) / 25) * 25 + 1050;
    if (up > 1400) {
        up = 1400;
    }
    return (float)up / 1000.0f;
}

static void TPS546_write_vout_window(float command)
{
    /* VOUT_COMMAND and VOUT_MAX are absolute volts.
     * OV/UV fault, OV/UV warn, and the margins are relative to the command.
     * Hardware max is 140% for the fault and 116% for the warning.
     */
    const float vmax = 1.60f;
    const float vmin = 0.70f;
    const float ov_fault = TPS546_fault_ratio(command);
    const float ov_warn = 1.16f;
    const float margin_high = 1.10f;
    const float margin_low = 0.90f;
    const float uv_warn = 0.90f;
    const float uv_fault = 0.75f;
    if (smb_write_word(PMBUS_VOUT_MAX, float_2_ulinear16(vmax)) != ESP_OK) ESP_LOGE(TAG, "TPS546 rejected VOUT_MAX %.3fV", vmax);
    if (smb_write_word(PMBUS_VOUT_OV_FAULT_LIMIT, float_2_ulinear16(ov_fault)) != ESP_OK) ESP_LOGE(TAG, "TPS546 rejected ov_fault %.3f", ov_fault);
    if (smb_write_word(PMBUS_VOUT_OV_WARN_LIMIT, float_2_ulinear16(ov_warn)) != ESP_OK) ESP_LOGE(TAG, "TPS546 rejected ov_warn %.3f", ov_warn);
    if (smb_write_word(PMBUS_VOUT_MARGIN_HIGH, float_2_ulinear16(margin_high)) != ESP_OK) ESP_LOGE(TAG, "TPS546 rejected margin_high %.3f", margin_high);
    if (smb_write_word(PMBUS_VOUT_MIN, float_2_ulinear16(vmin)) != ESP_OK) ESP_LOGE(TAG, "TPS546 rejected VOUT_MIN %.3fV", vmin);
    if (smb_write_word(PMBUS_VOUT_UV_FAULT_LIMIT, float_2_ulinear16(uv_fault)) != ESP_OK) ESP_LOGE(TAG, "TPS546 rejected uv_fault %.3f", uv_fault);
    if (smb_write_word(PMBUS_VOUT_UV_WARN_LIMIT, float_2_ulinear16(uv_warn)) != ESP_OK) ESP_LOGE(TAG, "TPS546 rejected uv_warn %.3f", uv_warn);
    if (smb_write_word(PMBUS_VOUT_MARGIN_LOW, float_2_ulinear16(margin_low)) != ESP_OK) ESP_LOGE(TAG, "TPS546 rejected margin_low %.3f", margin_low);
    TPS546_clear_faults();
    ESP_LOGI(TAG, "TPS546 fixed window ov_fault %.1f%% = %.3fV at %.3fV", ov_fault * 100.0f, command * ov_fault, command);
}

'@
if (-not $tpsText.Contains("static void TPS546_write_vout_window")) {
    $initAnchor = "esp_err_t TPS546_init(TPS546_CONFIG config)"
    if (-not $tpsText.Contains($initAnchor)) {
        Write-Host "Could not find TPS546_init."
        exit 1
    }
    $tpsText = $tpsText.Replace($initAnchor, $windowFn + $initAnchor)
}
if ($tpsText.Contains("static void TPS546_write_vout_window") -and -not $tpsText.Contains("TPS546_fault_ratio")) {
    $tpsNew = [regex]::Replace($tpsText, '(?s)static void TPS546_write_vout_window\(float command\).*?\r?\n\}', $windowFn.Trim(), 1)
    if ($tpsNew -eq $tpsText) {
        Write-Host "Could not replace the TPS546 window."
        exit 1
    }
    $tpsText = $tpsNew
    Write-Host "Core shutdown is now 1.55V. The maximum is 1.60V so the chip accepts the fault."
}
if (-not $tpsText.Contains("TPS546 fixed window")) {
    $tpsNew = [regex]::Replace($tpsText, '(?s)static void TPS546_write_vout_window\(float command\).*?\r?\n\}', $windowFn.Trim(), 1)
    if ($tpsNew -eq $tpsText) {
        Write-Host "Could not replace the TPS546 window."
        exit 1
    }
    $tpsText = $tpsNew
    Write-Host "Installed a fixed TPS546 window. The moving limits were being rejected."
}
if (-not $tpsText.Contains("TPS546_write_vout_window(volts)")) {
    $setLine = "value = float_2_ulinear16(volts);"
    if (-not $tpsText.Contains($setLine)) {
        Write-Host "Could not find the VOUT_COMMAND write in TPS546_set_vout."
        exit 1
    }
    $tpsText = $tpsText.Replace($setLine, "TPS546_write_vout_window(volts);`r`n            value = float_2_ulinear16(volts);")
}
if (-not $tpsText.Contains("TPS546_write_vout_window(tps546_config.TPS546_INIT_VOUT_COMMAND)")) {
    $tpsNew = [regex]::Replace(
        $tpsText,
        '(?s)ESP_LOGI\(TAG, "Setting VOUT_OV_FAULT_LIMIT:.*?smb_write_word\(PMBUS_VOUT_UV_FAULT_LIMIT,.*?\);',
        'TPS546_write_vout_window(tps546_config.TPS546_INIT_VOUT_COMMAND);',
        1)
    if ($tpsNew -eq $tpsText) {
        Write-Host "Could not retarget the TPS546 limit writes."
        exit 1
    }
    $tpsText = $tpsNew
}
$tpsText = $tpsText.Replace("f_value * tps546_config.TPS546_INIT_VOUT_COMMAND", "f_value")
if ($tpsText.Contains("VOUT window command")) {
    Write-Host "The old rejected window is still in TPS546.c. This is not a clean tree."
    exit 1
}
if (-not $tpsText.Contains("TPS546 fixed window") -or -not $tpsText.Contains("TPS546_write_vout_window(volts)")) {
    Write-Host "The TPS546 window is still the one the chip rejects."
    exit 1
}
[System.IO.File]::WriteAllText($tps, $tpsText, $utf8)
Write-Host "TPS546 OV fault is a percent of the command, 105% to 140% in 2.5% steps. The window targets a 1.55V trip. The warning stays at 116%, the hardware maximum."

$http = Join-Path $root "main\http_server\http_server.c"
Replace-Once $http '    } else if (CHECK_FILE_EXTENSION(filepath, ".png")) {' "    } else if (CHECK_FILE_EXTENSION(filepath, `".jpg`") || CHECK_FILE_EXTENSION(filepath, `".jpeg`")) {`r`n        type = `"image/jpeg`";`r`n    } else if (CHECK_FILE_EXTENSION(filepath, `".png`")) {"

$logH = Join-Path $root "main\log_buffer.h"
Replace-Once $logH "void log_buffer_init(void);" "void log_buffer_init(void);`r`nvoid log_buffer_clear(void);"

$logC = Join-Path $root "main\log_buffer.c"
$clearFn = @'
void log_buffer_clear(void)
{
    if (s_log_mutex == NULL) {
        return;
    }
    if (xSemaphoreTakeRecursive(s_log_mutex, portMAX_DELAY) != pdTRUE) {
        return;
    }
    memset(s_buffer, 0, LOG_BUFFER_SIZE);
    esp_cache_msync(s_buffer, LOG_BUFFER_SIZE, ESP_CACHE_MSYNC_FLAG_DIR_C2M | ESP_CACHE_MSYNC_FLAG_UNALIGNED);
    s_header.total_written = 0;
    s_header.magic = LOG_BUFFER_MAGIC;
    s_header.checksum = calculate_header_checksum(&s_header);
    esp_cache_msync(&s_header, sizeof(s_header), ESP_CACHE_MSYNC_FLAG_DIR_C2M | ESP_CACHE_MSYNC_FLAG_UNALIGNED);
    xSemaphoreGiveRecursive(s_log_mutex);
    ESP_LOGI(TAG, "Logs cleared");
}

'@
Replace-Once $logC "uint64_t log_buffer_get_total_written(void)" ($clearFn + "uint64_t log_buffer_get_total_written(void)")

$clearFnHttp = @'
static esp_err_t POST_system_logs_clear(httpd_req_t *req)
{
    if (is_network_allowed(req) != ESP_OK) {
        return httpd_resp_send_err(req, HTTPD_401_UNAUTHORIZED, "Unauthorized");
    }
    log_buffer_clear();
    httpd_resp_set_type(req, "application/json");
    return httpd_resp_sendstr(req, "{\"ok\":true}");
}

'@
$httpText = [System.IO.File]::ReadAllText($http)
if (-not $httpText.Contains("static esp_err_t POST_system_logs_clear")) {
    $anchor = $null
    foreach ($candidate in @(
        "static GlobalState * GLOBAL_STATE;",
        "esp_err_t HTTP_send_json(httpd_req_t * req, const cJSON * item, int * prebuffer_len)"
    )) {
        if ($httpText.Contains($candidate)) { $anchor = $candidate; break }
    }
    if (-not $anchor) {
        Write-Host "Could not find a place to add the clear-logs function."
        exit 1
    }
    $httpText = $httpText.Replace($anchor, $clearFnHttp + $anchor)
    [System.IO.File]::WriteAllText($http, $httpText, $utf8)
    Write-Host "Added POST_system_logs_clear"
}
Replace-Once $http "    httpd_register_uri_handler(server, &system_logs_get_uri);" @'
    httpd_register_uri_handler(server, &system_logs_get_uri);

    httpd_uri_t system_logs_clear_uri = {
        .uri = "/api/system/logs/clear",
        .method = HTTP_POST,
        .handler = POST_system_logs_clear,
        .user_ctx = rest_context
    };
    httpd_register_uri_handler(server, &system_logs_clear_uri);
'@
Replace-Once $http '{ .uri = "/api/system/logs",               .method = HTTP_GET,     .handler = GET_system_logs },' @'
{ .uri = "/api/system/logs",               .method = HTTP_GET,     .handler = GET_system_logs },
        { .uri = "/api/system/logs/clear",         .method = HTTP_POST,    .handler = POST_system_logs_clear },
'@

$httpText = [System.IO.File]::ReadAllText($http)
$logText = [System.IO.File]::ReadAllText($logC)
if (-not $logText.Contains("void log_buffer_clear(void)") -or -not $httpText.Contains("static esp_err_t POST_system_logs_clear") -or -not $httpText.Contains("/api/system/logs/clear")) {
    Write-Host "Could not add the clear-logs button endpoint."
    exit 1
}
$tpsText = [System.IO.File]::ReadAllText($tps)
$tpsFixed = [regex]::Replace($tpsText, '(TPS546_STATUS_VOUT_OVW\) \{\r?\n\s*ESP_LOGE\(TAG, "VOUT )Undervoltage( Warning"\);)', '${1}Overvoltage${2}', 1)
if ($tpsFixed -eq $tpsText) {
    Write-Host "Could not relabel the core overvoltage warning."
} else {
    [System.IO.File]::WriteAllText($tps, $tpsFixed, $utf8)
    Write-Host "Core overvoltage warning is no longer labeled as undervoltage."
}

Write-Host ""
Write-Host "SynAxe OS v-0.0.1-beta is installed."
Write-Host "Auto tune is removed. The clock changes only when you press Apply."
Write-Host "Next, from C:\Projects\SynAxe OS run:"
Write-Host "  idf.py build"
Write-Host "  idf.py -p COM9 flash"
Write-Host "The build log must say: SynAxe OS web UI"
Write-Host "Install steps are in INSTALL.md."
Write-Host ""
