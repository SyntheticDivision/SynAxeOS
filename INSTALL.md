# Install SynAxe OS v-0.0.1-beta

**Very early beta.** This is test firmware. Expect rough edges, and please send feedback if you try it. Issues, email, and YouTube links are in the [README](README.md).

This installs SynAxe OS onto a **StarMiner 601a 12V**. It does not replace the whole ESP-Miner tree. The installer patches that tree, then a normal `idf.py build` packs the new web UI into the firmware.

Do this on **Windows 11**. The steps below match the ESP-IDF 5.5 setup used to build this beta.

## What you need

- A StarMiner **601a 12V** board. Do not use a 5V Bitaxe Gamma.
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

## 2. Get StarMiner

StarMiner has submodules. The clone must be recursive, and the folder must be exactly `C:\Projects\StarMiner`. The installer refuses to run anywhere else.

```bat
mkdir C:\Projects
git clone --recursive https://github.com/tjwink/StarMiner.git C:\Projects\StarMiner
cd C:\Projects\StarMiner
```

If the clone was already done without `--recursive`, fix it before building:

```bat
cd C:\Projects\StarMiner
git submodule update --init --recursive
```

## 3. Get SynAxe OS

Put this repo **inside** the StarMiner folder:

```bat
cd C:\Projects\StarMiner
git clone https://github.com/SyntheticDivision/SynAxeOS.git SynAxeOS
```

You should now have these files:

```text
C:\Projects\StarMiner\SynAxeOS\install.ps1
C:\Projects\StarMiner\SynAxeOS\build-synaxe.js
C:\Projects\StarMiner\SynAxeOS\synaxe-www\index.html
C:\Projects\StarMiner\SynAxeOS\synaxe-www\city-bg.b64
```

`city-bg.b64` is the dashboard background. The installer turns it into `city-bg.jpg` while it copies the page. Do not delete it.

## 4. Apply the patch

Still in the ESP-IDF PowerShell window:

```bat
cd C:\Projects\StarMiner\SynAxeOS
powershell -ExecutionPolicy Bypass -File .\install.ps1
```

The script copies the web UI into the AxeOS folder and patches the 601a firmware. A good run mentions the boot screens, the removed auto tune, the core voltage cap, and the 15 minute hashrate. It is safe to run the script again. Lines that say the change is already present are fine.

Stop if it says it **could not patch** a file, or that it **could not find** `C:\Projects\StarMiner`. Do not flash that build. The usual cause is that StarMiner is in a different folder, or the StarMiner revision no longer matches the lines the installer looks for.

## 5. Build

```bat
cd C:\Projects\StarMiner
idf.py set-target esp32s3
idf.py build
```

The first build downloads the web toolchain and can take a while. The web step should print `SynAxe OS web UI` and a version string. That string is the internal ESP-Miner git version used to keep `www.bin` and `esp-miner.bin` in sync. The page itself still shows **SynAxe OS v-0.0.1-beta**.

When the build finishes, `idf.py` prints a `flash` command. Leave that window open.

If the web UI step fails, run the installer again and then:

```bat
cd C:\Projects\StarMiner
idf.py fullclean
idf.py build
```

## 6. Flash

1. Plug in the **12V supply**.
2. Plug the USB cable into the board and the PC.
3. Find the COM port in Device Manager under Ports. It is often `COM9`, but use the one Windows actually shows.
4. Flash:

```bat
cd C:\Projects\StarMiner
idf.py -p COM9 flash
```

Replace `COM9` with your port. Do not flash an old `www.bin` from a previous build. One `idf.py flash` writes the bootloader, the partition table, the app, and the web UI together.

If the port is busy, close any serial monitor and try again. If the flash cannot start the chip, hold the **BOOT** button, tap **RESET**, release **BOOT**, and run the flash command again.

## 7. First boot

Leave the 12V supply on and open the serial monitor if you want the log:

```bat
idf.py -p COM9 monitor
```

Exit the monitor with `Ctrl+]`.

The OLED plays four screens:

1. SynAxe / OS
2. TDMC
3. By SyntheticDivision
4. Wi-Fi name and `Connecting...`

After that it joins the network that was already saved on the board, or it shows the setup screen if no Wi-Fi is saved. The IP address screen shows the address to type into a browser.

On the PC, press **Ctrl+F5** the first time you open that address. A normal refresh can keep the old AxeOS page.

The Developer tab should say **v-0.0.1-beta**, with Questions, Support, and the YouTube link. The Dashboard hashrate card shows the live rate plus **1m**, **15m**, and **1h**.

## 8. If the board complains at boot

- **Power fail / self-test fail, hold boot button.** The ASIC is not powered from USB. Confirm the 12V plug is seated and the supply is on, then hold BOOT and tap RESET.
- **Firmware and SynAxe OS versions do not match.** The web UI and the app were not flashed from the same build. Run `idf.py build` again and flash the whole image. Do not copy an old `www.bin` in by hand.
- **The page still looks like AxeOS.** You opened the wrong host, or the browser cached the old UI. Check the IP on the OLED and press Ctrl+F5.
- **Hashrate collapses as soon as the clock rises.** Back off the overclock. The soft cap is 850 MHz and 1300 mV for a reason. Confirm this is a 601a on 12V before trying the risk checkbox.

## Updating later

```bat
cd C:\Projects\StarMiner\SynAxeOS
git pull
powershell -ExecutionPolicy Bypass -File .\install.ps1
cd C:\Projects\StarMiner
idf.py build
idf.py -p COM9 flash
```

## Sharing a build

SynAxe OS is GPL-3.0, the same license as StarMiner and ESP-Miner. If you give someone a `.bin`, also give them the source that built it: this repo at the commit you used, plus the StarMiner commit you applied it to.
