# SynAxe OS

**12V Gamma only.** StarMiner Bitaxe Gamma 601a. Do not flash this on a 5V Gamma. A wrong board can burn the ASIC. DO NOT OVERCLOCK!!!

**Very early beta.** This is v-0.0.1-beta test firmware. Expect rough edges. Feedback is welcome. DO NOT OVERCLOCK

SynAxe OS is a firmware interface and patch set for the **StarMiner 601a 12V** (Bitaxe Gamma, BM1370, ESP32-S3). It sits on top of [StarMiner](https://github.com/tjwink/StarMiner), which is built from ESP-Miner. The miner still runs that firmware. SynAxe OS replaces the web page and applies the 601a display and voltage changes.

This is **not** a standalone firmware tree, and it is **not** a finished product. You clone StarMiner, then apply this repo on top of it.

## What it is

A cyberpunk dashboard for one 12V board:

- Manual overclock tab with a voltage curve, a soft cap, and a hard cap
- No auto tune and no auto update
- Pool page with a fallback pool and a dual-pool share split
- SynFleet scan for other ESP-Miner devices on the same subnet
- Overheat latch, fan modes, and a watt calibration card
- OLED boot screens: SynAxe OS, TDMC, By SyntheticDivision, then Wi-Fi
- Developer tab for The Division Mining Company

The 15 minute hashrate is a real average. For the first minute it follows the 1 minute figure, then it fills in.

## Early beta

This build has only been run on one 601a. The clock curve, the watt reading, and dual pool are still being tested. Do not treat it as stable.

If you try it, please say what the board did. The useful report is the clock, the core voltage, the error rate, and what the screen showed.

- Open an [issue](https://github.com/SyntheticDivision/SynAxeOS/issues) on this repo
- Email [thedivisionminingcompany@gmail.com](mailto:thedivisionminingcompany@gmail.com)
- Or leave a note on YouTube [@SyntheticDee](https://www.youtube.com/@SyntheticDee)

## Safety

This build is for the **StarMiner Bitaxe Gamma 601a 12V** only. Do not flash it onto a 5V Gamma. The core voltage caps, the TPS546 input limits, and the voltage curve are written for the 12V board. A wrong board can burn the ASIC.

Soft cap is 850 MHz and 1300 mV. With the risk box checked, the hard cap is 1100 MHz and 1400 mV. The firmware will not go past that. Going over 1350 mV can damage the ASICs.

## Install

The full steps are in [INSTALL.md](INSTALL.md).

Short version, from an **ESP-IDF 5.5 PowerShell** window:

```bat
git clone --recursive https://github.com/tjwink/StarMiner.git C:\Projects\StarMiner
git clone https://github.com/SyntheticDivision/SynAxeOS.git C:\Projects\StarMiner\SynAxeOS
cd C:\Projects\StarMiner\SynAxeOS
powershell -ExecutionPolicy Bypass -File .\install.ps1
cd C:\Projects\StarMiner
idf.py build
idf.py -p COM9 flash
```

Use your own COM port. The miner needs its **12V supply** plugged in. USB alone is only enough to flash, not to mine.

## License

SynAxe OS is a derivative of StarMiner / ESP-Miner and is released under the **GNU General Public License v3.0**. See [LICENSE](LICENSE). If you share a built `.bin`, you must share the matching source as well.

Upstream projects:

- https://github.com/tjwink/StarMiner
- https://github.com/bitaxeorg/ESP-Miner
