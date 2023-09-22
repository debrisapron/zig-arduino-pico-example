#include "Arduino.h"

extern "C" {
    // Our core.zig entry points
    void core_loop(void);
    void core_setup(void);
}

void loop() {
    core_loop();
}

void setup() {
    core_setup();
}