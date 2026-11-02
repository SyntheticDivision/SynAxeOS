# Install SynAxe OS v-0.0.1-beta

**12V Gamma only.** This is for the Bitaxe Gamma 601a on 12V. Do not install it on a 5V Gamma. A wrong board can burn the ASIC.

**Very early beta.** This is test firmware. Expect rough edges, and please send feedback if you try it. Issues, email, and YouTube links are in the [README](README.md).

This installs SynAxe OS onto official [ESP-Miner](https://github.com/bitaxeorg/ESP-Miner) for a **601a 12V** board. It does not replace the whole tree. The installer patches that tree, then a normal `idf.py build` packs the new web UI into the firmware.

Official ESP-Miner has no `601a` board. Its Gamma 601 profile is 5V, and the input overvoltage fault is 6.5V. On a 12V supply that fault turns the regulator off. The installer adds board `601a` and locks the input to 11.0V on, 10.5V off, and 14.0V overvoltage. The clock is 400 to 650 MHz in 25 MHz steps. Core voltage is 1100 to 1225 mV in 25 mV steps. Firmware and web updates are refused. Do not point this patch at a 5V Gamma.

Do this on **Windows 11**. The steps below match the ESP-IDF 5.5 setup used to build this beta.

## What you need

- A Bitaxe Gamma **601a 12V** board. Do not use a 5V Bitaxe Gamma.
- The board's **12V power supply**. USB is only for flashing and the serial log.
- A USB data cable.
- Windows 11.
- Git.
- Node.js, the current LTS is fine. `node` and `npm` must be on your PATH.
- Espressif's **ESP-IDF v5.5** Windows installer. This beta was built with **v5.5.6**.

The Espressif installer puts the tools under `C:\Espressif` and adds a Start Menu shortcut named **ESP-IDF 5.5 PowerShell**. Use that window for every command below. A normal PowerShell or Command Prompt will not have `idf.py`, and it often will not have the ESP-IDF copy of Python.

## 1. Install ESP-IDF

1. Download the ESP-IDF v5.5 Windows installer from Espressif.
2. Install it with the default options, including the ESP32-S3 chip target.
3. When it finishes, open **ESP-IDF 5.5 PowerShell** from the Start Menu.
4. Check the tools:

```bat
idf.py --version
python --version
node --version
git --version
```

`idf.py` should report ESP-IDF v5.5.x. If `idf.py` is not found, you are in the wrong window.

## 2. Fresh install

Do not use `C:\Projects\SynAxe OS`. That tree still has the voltage window the TPS546 rejects. `fresh.ps1` clones a clean ESP-Miner v2.14.2 into `C:\Projects\SynAxeOS` and patches only that copy. If `C:\Projects\SynAxeOS` already exists, the script renames it out of the way first.

In the ESP-IDF 5.5 PowerShell window, from the folder that contains `fresh.ps1`:

```bat
powershell -ExecutionPolicy Bypass -File .\fresh.ps1
```

The script has to finish with `Fresh SynAxe OS is at C:\Projects\SynAxeOS`. Then:

```bat
cd C:\Projects\SynAxeOS\SynAxeOS
powershell -ExecutionPolicy Bypass -File .\build.ps1
powershell -ExecutionPolicy Bypass -File .\flash.ps1
```

Unplug the 12 V supply once after the flash. The boot log must contain `TPS546 fixed window ov_fault` and a percent, for example `125.0% = 1.562V`. It must not say `ov_fault 1.440V`. If it still says `VOUT window command`, the old folder was flashed again.

## 3. What a good install says

`fresh.ps1` must print `Fresh SynAxe OS is at C:\Projects\SynAxeOS`. The patch says the 601a input is 11.0V on, 10.5V off, and 14.0V overvoltage, and that the TPS546 overvoltage fault is a percent of the command, 105% to 140%, aimed at a 1.55V trip. Stop if it says it could not patch a file.

After flashing, unplug the 12 V supply once. The serial log must contain `TPS546 fixed window ov_fault` with a percent near a 1.55V trip, and `on=11.00 off=10.50 ov_fault=14.00`. If it says `ov_fault 1.440V`, `VOUT window command`, or `on=4.80`, the old tree was flashed. Do not use that build.

The first build downloads the web toolchain and can take a while. The web step should print `SynAxe OS web UI`. The page shows **SynAxe OS v-0.0.1-beta**.

## 6. Flash notes

`flash.ps1` writes COM9. Plug in the **12V supply** and the USB cable first. If Windows shows a different port:

```bat
powershell -ExecutionPolicy Bypass -File .\flash.ps1 COM5
```

Do not flash an old `www.bin` from a previous build. One flash writes the bootloader, the partition table, the app, and the web UI together.

If the port is busy, close any serial monitor and try again. If the flash cannot start the chip, hold the **BOOT** button, tap **RESET**, release **BOOT**, and run `flash.ps1` again.

## 7. First boot

Leave the 12V supply on and open the serial monitor if you want the log:

```bat
idf.py -p COM9 monitor
```

Exit the monitor with `Ctrl+]`.

The OLED plays four screens:

1. SynAxe
2. TDMC
3. By SyntheticDivision
4. Wi-Fi. If nothing is saved, this screen stays up and says SynAxe, then `synaxe_` plus the last of the MAC.

After that it joins the network that was already saved on the board, or it shows the setup screen if no Wi-Fi is saved. The IP address screen shows the address to type into a browser.

On the PC, press **Ctrl+F5** the first time you open that address. A normal refresh can keep the old AxeOS page.

The Developer tab should say **v-0.0.1-beta**, with Questions, Support, and the YouTube link. The Dashboard hashrate card shows the live rate plus **1m**, **15m**, and **1h**.

## 8. If the board complains at boot

- **Power fail / self-test fail, hold boot button.** The ASIC is not powered from USB. Confirm the 12V plug is seated and the supply is on, then hold BOOT and tap RESET.
- **Firmware and SynAxe OS versions do not match.** The web UI and the app were not flashed from the same build. Run `idf.py build` again and flash the whole image. Do not copy an old `www.bin` in by hand.
- **The page still looks like AxeOS.** You opened the wrong host, or the browser cached the old UI. Check the IP on the OLED and press Ctrl+F5.
- **Hashrate collapses as soon as the clock rises.** This build will not go above 650 MHz or outside 1100 to 1225 mV. Confirm this is a 601a on 12V.

## Updating later

```bat
cd C:\Projects\synaxe-setup\SynAxeOS
git pull
powershell -ExecutionPolicy Bypass -File .\fresh.ps1
cd C:\Projects\SynAxeOS\SynAxeOS
powershell -ExecutionPolicy Bypass -File .\build.ps1
powershell -ExecutionPolicy Bypass -File .\flash.ps1
```

## Sharing a build

SynAxe OS is GPL-3.0, the same license as ESP-Miner. If you give someone a `.bin`, also give them the source that built it: this repo at the commit you used, plus the ESP-Miner commit you applied it to.
