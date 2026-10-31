# SynAxe OS

SynAxe OS **v-0.0.1-beta** is a firmware interface and patch set for the **StarMiner 601a 12V** board. It sits on top of [StarMiner](https://github.com/tjwink/StarMiner), which is itself built from ESP-Miner. The miner still runs that ESP32-S3 firmware. SynAxe OS replaces the web UI and applies the 601a safety and display changes.

This is **not** a standalone firmware tree. You clone StarMiner, then apply this repo on top of it.

## What this version is

- Cyberpunk dashboard for the 601a, not the stock AxeOS layout
- Manual overclock tab with a voltage curve, soft cap, and hard cap
- No auto tune and no auto update
- Pool page with a fallback pool and a dual-pool share split
- SynFleet scan for other ESP-Miner devices on the same subnet
- Overheat latch, fan modes, and a watt calibration card
- OLED boot screens: SynAxe OS, TDMC, By SyntheticDivision, then the Wi-Fi screen
- Developer tab for The Division Mining Company

The 15 minute hashrate is a real average. For the first minute it follows the 1 minute figure, then it fills in.

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
