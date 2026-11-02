# SynAxe OS

**12V Gamma only.** Bitaxe Gamma 601a on 12V. Do not flash this on a 5V Gamma. A wrong board can burn the ASIC.

**Very early beta.** This is v-0.0.1-beta test firmware. Expect rough edges. Feedback is welcome.

SynAxe OS is a firmware interface and patch set for the **Bitaxe Gamma 601a 12V** (BM1370, ESP32-S3). It sits on top of [ESP-Miner](https://github.com/bitaxeorg/ESP-Miner). Official ESP-Miner treats a Gamma as a 5V board. This patch adds board `601a` and forces the 12V input limits: on at 11.0V, off at 10.5V, input overvoltage fault at 14.0V. The page and the firmware will not go above 650 MHz or outside 1100 to 1225 mV, and only in steps of 25. A saved clock off those steps is pulled back on boot. Firmware and web updates are refused, so this build cannot be replaced from the page. A saved 5V profile cannot change those input limits.

This is **not** a standalone firmware tree, and it is **not** a finished product. You clone ESP-Miner, then apply this repo on top of it.

## What it is

A cyberpunk dashboard for one 12V board:

- Tune tab only. Frequency is 400 to 650 MHz in 25 MHz steps. Core voltage is 1100 to 1225 mV in 25 mV steps. There is no free-form overclock.
- No auto tune and no auto update
- One pool, with a Stratum V1 or Stratum V2 choice. No dual-pool mode.
- SynFleet scan for other ESP-Miner devices on the same subnet
- Overheat latch, fan controls on the Tune tab, and a watt calibration card
- OLED boot: SynAxe, then TDMC, then By SyntheticDivision. If Wi-Fi is not set, the setup screen says SynAxe and the network is synaxe_ plus the last of the MAC.
- Developer tab for The Division Mining Company

The 15 minute hashrate is a real average. For the first minute it follows the 1 minute figure, then it fills in.

## Early beta

This build has only been run on one 601a. The safe clock stops at 650 MHz and 1225 mV because higher settings trip the voltage regulator. Do not treat it as stable.

If you try it, please say what the board did. The useful report is the clock, the core voltage, the error rate, and what the screen showed.

- Open an [issue](https://github.com/SyntheticDivision/SynAxeOS/issues) on this repo
- Email [thedivisionminingcompany@gmail.com](mailto:thedivisionminingcompany@gmail.com)
- Or leave a note on YouTube [@SyntheticDee](https://www.youtube.com/@SyntheticDee)

## Safety

This build is for the **Bitaxe Gamma 601a 12V** only. Do not flash it onto a 5V Gamma. Official ESP-Miner would program the input overvoltage fault at 6.5V, which turns the regulator off on a 12V supply. The 601a profile uses 11.0V on, 10.5V off, and 14.0V overvoltage. The clock stops at 650 MHz. Core voltage is 1100 to 1225 mV in 25 mV steps.

The Tune tab only offers 400 to 650 MHz and 1100 to 1225 mV, both in steps of 25.

## Install

The full steps are in [INSTALL.md](INSTALL.md).

Short version, from an **ESP-IDF 5.5 PowerShell** window. Do not use a folder named `SynAxe OS`.

```bat
git clone https://github.com/SyntheticDivision/SynAxeOS.git C:\Projects\synaxe-setup\SynAxeOS
cd C:\Projects\synaxe-setup\SynAxeOS
powershell -ExecutionPolicy Bypass -File .\fresh.ps1
cd C:\Projects\SynAxeOS\SynAxeOS
powershell -ExecutionPolicy Bypass -File .\build.ps1
powershell -ExecutionPolicy Bypass -File .\flash.ps1
```

Use your own COM port. The miner needs its **12V supply** plugged in. USB alone is only enough to flash, not to mine.

## License

SynAxe OS is a derivative of ESP-Miner and is released under the **GNU General Public License v3.0**. See [LICENSE](LICENSE). If you share a built `.bin`, you must share the matching source as well.

Upstream project:

- https://github.com/bitaxeorg/ESP-Miner
