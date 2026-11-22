# SynAxe OS

**12V Gamma only.** Bitaxe Gamma 601a on 12V. Do not flash this on a 5V Gamma. A wrong board can burn the ASIC.

**Very early beta.** This is v-0.0.1-beta test firmware. Expect rough edges. Feedback is welcome.

SynAxe OS is a firmware interface and patch set for the **Bitaxe Gamma 601a 12V** (BM1370, ESP32-S3). It sits on top of [ESP-Miner](https://github.com/bitaxeorg/ESP-Miner). Official ESP-Miner treats a Gamma as a 5V board. This patch adds board `601a` and forces the 12V input limits: on at 11.0V, off at 10.5V, input overvoltage fault at 14.0V. A locked clock uses the same BM1370 lists as AxeOS. Unlock custom to type other numbers. The core command stops at 1520 mV so the regulator fault stays under 1.60V. Firmware and web updates are refused, so this build cannot be replaced from the page. A saved 5V profile cannot change those input limits.

This is **not** a standalone firmware tree, and it is **not** a finished product. You clone ESP-Miner, then apply this repo on top of it.

## What it is

A cyberpunk dashboard for one 12V board:

- Tune tab. Locked frequency and core voltage use the AxeOS BM1370 lists. Unlock custom for other numbers. There is no auto tune.
- ASIC temperature is the EMC2101 external diode. VR die is the TPS546 on-die sensor. The chart can plot any two of hashrate, ASIC temp, VR die, and fan speed.
- No auto update
- One pool, with a Stratum V1 or Stratum V2 choice. No dual-pool mode.
- SynFleet works like AxeOS swarm: it scans the subnet, keeps the boards that answer, and lets you add one by IP.
- Overheat latch, fan controls on the Tune tab, and a watt calibration card
- OLED boot: SynAxe, then TDMC, then By SyntheticDivision. If Wi-Fi is not set, the setup screen says SynAxe and the network is synaxe_ plus the last of the MAC.
- Developer tab for The Division Mining Company

The 15 minute hashrate is a real average. For the first minute it follows the 1 minute figure, then it fills in.

## Early beta

This build has only been run on one 601a. A locked clock follows the AxeOS list, up to 625 MHz and 1250 mV. Higher custom voltage can still trip the regulator. Do not treat it as stable.

If you try it, please say what the board did. The useful report is the clock, the core voltage, the error rate, and what the screen showed.

- Open an [issue](https://github.com/SyntheticDivision/SynAxeOS/issues) on this repo
- Email [thedivisionminingcompany@gmail.com](mailto:thedivisionminingcompany@gmail.com)
- Or leave a note on YouTube [@SyntheticDee](https://www.youtube.com/@SyntheticDee)

## Safety

This build is for the **Bitaxe Gamma 601a 12V** only. Do not flash it onto a 5V Gamma. Official ESP-Miner would program the input overvoltage fault at 6.5V, which turns the regulator off on a 12V supply. The 601a profile uses 11.0V on, 10.5V off, and 14.0V overvoltage. Locked core voltage stops at 1250 mV. Custom core voltage stops at 1520 mV.

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
