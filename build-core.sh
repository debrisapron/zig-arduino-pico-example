zig build-lib \
  src/core.zig \
  -target thumb-freestanding-eabi \
  -mcpu cortex_m0plus \
  -isystem ./src \
  && mv libcore.* bin