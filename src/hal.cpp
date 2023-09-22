#include "Arduino.h"
#include <WiFi.h>
#include <time.h>
#include <sys/time.h>

// For Zig to call into our HAL, our functions must conform with the C ABI
extern "C" {
    #include "hal.h"

    int WiFi_status(void) {
        return WiFi.status();
    }

    int WiFi_begin(const char *ssid, const char *passphrase) {
        return WiFi.begin(ssid, passphrase);
    }

    void setTimezone(const char *tz) {
        setenv("TZ", tz, 1);
        tzset();
    }

    void NTP_begin(const char *s1, const char *s2) {
        NTP.begin(s1, s2);
    }

    unsigned short NTP_waitSet() {
        return NTP.waitSet();
    }

    TimeInfo getTimeInfo() {
        time_t now = time(nullptr);
        struct tm _tm;
        localtime_r(&now, &_tm);
        return {
            .tm_sec = _tm.tm_sec,
            .tm_min = _tm.tm_min,
            .tm_hour = _tm.tm_hour,
            .tm_mday = _tm.tm_mday,
            .tm_mon = _tm.tm_mon,
            .tm_year = _tm.tm_year,
        };
    }

    void _delay(unsigned long ms) {
        delay(ms);
    }

    // NOTE: Unlike the standard Arduion tone, this one is blocking
    void _tone(unsigned short _pin, unsigned int frequency, unsigned long duration) {
        // Flash led for extra feedback
        digitalWrite(PIN_LED, HIGH);
        tone(_pin, frequency);
        delay(duration);
        digitalWrite(PIN_LED, LOW);
        noTone(_pin);
    }
}
