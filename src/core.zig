const Hal = @cImport({
    @cInclude("hal.h");
});

// Timezone string from
// https://github.com/nayarsystems/posix_tz_db/blob/master/zones.csv
const TIMEZONE = "PST8PDT,M3.2.0,M11.1.0";

// TODO: Move these to a separate secrets module
const SSID = "SO PASSE"; //"**YOUR SSID HERE**";
const PASSPHRASE = "ble$$ings"; //"**YOUR PASSPHRASE HERE**";

const NTP_SERVER_1 = "pool.ntp.org";
const NTP_SERVER_2 = "time.nist.gov";
const AUDIO_PIN = 0;
const WL_CONNECTED = 3;
const STRIKE_FREQS = [4]u16{ 262, 330, 392, 523 };
const QUIET_TIME = [2]u8{ 23, 7 };

var _ntp_running: bool = false;
var _prev_strike: u8 = 99;
var _prev_sync_attempt: Hal.TimeInfo = Hal.TimeInfo{
    .tm_sec = 0,
    .tm_min = 0,
    .tm_hour = 0,
    .tm_mday = 0,
    .tm_mon = 0,
    .tm_year = 0,
};

fn beep(freq: u16, len: u16) void {
    Hal._tone(AUDIO_PIN, freq, len);
}

fn strikeHour(hr: u8) void {
    // Covert 0-23 to 1-12
    var hr12: u8 = hr % 12;
    if (hr12 == 0) {
        hr12 = 12;
    }

    for (0..hr12) |i| {
        const freq: u16 = STRIKE_FREQS[i % 4];
        beep(freq, 300);
        Hal._delay(100);
    }
}

fn playStartupTone() void {
    beep(440, 200);
    beep(523, 200);
    beep(880, 400);
    Hal._delay(1000);
}

fn playErrorTone() void {
    for (0..4) |_| {
        beep(220, 900);
        Hal._delay(100);
    }
}

// Returns true if successful
fn syncToNTP() bool {
    // Connect to WiFi if disconnected
    if (Hal.WiFi_status() != WL_CONNECTED) {
        const conn_status = Hal.WiFi_begin(SSID, PASSPHRASE);
        if (conn_status != WL_CONNECTED) {
            return false;
        }
    }

    // Start NTP service if not running
    if (!_ntp_running) {
        Hal.setTimezone(TIMEZONE);
        Hal.NTP_begin(NTP_SERVER_1, NTP_SERVER_2);
        _ntp_running = true;
    }

    // Attempt sync
    const success = Hal.NTP_waitSet() == 0;
    return success;
}

pub export fn core_loop() callconv(.C) void {
    const time_info: Hal.TimeInfo = Hal.getTimeInfo();

    // Calculate if strike is due
    const min: u8 = @intCast(time_info.tm_min);
    const hr: u8 = @intCast(time_info.tm_hour);
    const is_strike_due: bool = min == 0 and _prev_strike != hr;

    // If strike isn't due, sleep until close to next strike
    if (!is_strike_due) {
        if (min < 59) {
            const mins_to_next_strike: u32 = 59 - min;
            Hal._delay(mins_to_next_strike * 60_000);
        }
        return;
    }

    // If strike is due and it's not quiet time, strike the hour
    _prev_strike = hr;
    if (hr < QUIET_TIME[0] and hr >= QUIET_TIME[1]) {
        strikeHour(hr);
    }

    // Calculate if sync is due (24 hours since last sync)
    const curr_day: u8 = @intCast(time_info.tm_mday);
    const prev_day: u8 = @intCast(_prev_sync_attempt.tm_mday);
    const is_sync_due = curr_day != prev_day;

    // If it's due then sync, but don't play any notification tones
    if (is_sync_due) {
        // TODO If it fails to sync for like, a week,
        // it should probably switch to the error mode?
        _ = syncToNTP();
        _prev_sync_attempt = time_info;
    }
}

pub export fn core_setup() callconv(.C) void {
    // Try initial NTP sync three times
    var sync_attempts: u8 = 0;
    var sync_success: bool = false;
    while (sync_attempts < 3 and !sync_success) {
        sync_success = syncToNTP();
        sync_attempts += 1;
    }

    // If sync failed just bleep at them until power off
    if (!sync_success) {
        while (true) {
            playErrorTone();
            Hal._delay(1000);
        }
    }

    // Success!
    _prev_sync_attempt = Hal.getTimeInfo();
    playStartupTone();
}
