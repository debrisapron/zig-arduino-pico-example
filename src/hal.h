// This header is used by both hal.cpp & core.zig,
// so it can only use built-in C types

typedef struct {
  int tm_sec;
  int tm_min;
  int tm_hour;
  int tm_mday;
  int tm_mon;
  int tm_year;
} TimeInfo;

int WiFi_status(void);
int WiFi_begin(const char *ssid, const char *passphrase);
void setTimezone(const char *tz);
void NTP_begin(const char *s1, const char *s2);
unsigned short NTP_waitSet(void);
TimeInfo getTimeInfo();
void _delay(unsigned long ms);
void _tone(unsigned short _pin, unsigned int frequency, unsigned long duration);