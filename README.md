<p align="center">
    <a href="https://github.com/cheat-engine/cheat-engine/raw/master/Cheat%20Engine/images">
        <img src="https://github.com/cheat-engine/cheat-engine/raw/master/Cheat%20Engine/images/celogo.png" />
    </a>
</p>

<h1 align="center">Cheat Engine</h1>

Cheat Engine is a development environment focused on modding games and applications for personal use.


# Download

  * **[Latest Version](https://github.com/cheat-engine/cheat-engine/releases/latest)**

[Older versions](https://github.com/cheat-engine/cheat-engine/releases)


# Links

  * [Website](https://www.cheatengine.org)
  * [Forum](https://forum.cheatengine.org)
  * [Forum (alternate)](https://fearlessrevolution.com/index.php)
  * [Wiki](https://wiki.cheatengine.org/index.php?title=Main_Page)

## Social Media

  * [Reddit](https://reddit.com/r/cheatengine)
  * [Twitter](https://twitter.com/_cheatengine)

## Donate

  * [Patreon](https://www.patreon.com/cheatengine)
  * [PayPal](https://www.paypal.com/xclick/business=dark_byte%40hotmail.com&no_note=1&tax=0&lc=US)


## Basic Build Instructions

  1. Download Lazarus 2.2.2 from https://sourceforge.net/projects/lazarus/files/Lazarus%20Windows%2064%20bits/Lazarus%202.2.2/ First install lazarus-2.2.2-fpc-3.2.2-win64.exe and then lazarus-2.2.2-fpc-3.2.2-cross-i386-win32-win64.exe

  2. Run Lazarus and click on `Project->Open Project`. Select `cheatengine.lpi` from the `Cheat Engine` folder as the project.
  3. Click on `Run->Build` or press <kbd>SHIFT+F9</kbd>.
      * you can also click on `Run->Compile many Modes` (tip: select first three compile modes)
      * If you want to run or debug from the IDE on Windows you will need to run Lazarus as administrator.

  Do not forget to compile secondary projects you'd like to use:

     speedhack.lpr: Compile both 32- and 64-bit DLL's for speedhack capability
     luaclient.lpr: Compile both 32- and 64-bit DLL's for {$luacode} capability
     DirectXMess.sln: Compile for 32-bit and 64-bit for D3D overlay and snapshot capabilities
     DotNetcompiler.sln: for the cscompile lua command
     monodatacollector.sln: Compile both 32-bit and 64-bit dll's to get Mono features to inspect the .NET environment of the process
     dotnetdatacollector.sln: Compile both 32- and 64-bit EXE's to get .NET symbols
     dotnetinvasivedatacollector.sln: Compile this managed .DLL to add support for runtime JIT support
     cejvmti.sln: Compile both 32- and 64-bit DLL's for Java inspection support
     tcclib.sln: Compile 32-32, 64-32 and 64-64 to add {$C} and {$CCODE} support in scripts
     vehdebug.lpr: Compile 32- and 64-bit DLL's to add support for the VEH debugger interface
     dbkkernel.sln: for kernelmode functions (settings->extra) You will need to build the no-sig version and either boot with unsigned driver support, or sign the driver yourself

*.SLN files require visual studio (Usually 2017)

## 32-bit and 64-bit

  * In the project options -> Config and Target the setting "Win32 gui application" is checked.

## lazarus projects

  * cecore: if you plan on bulding a jni version for android
  * ceregreset: to reset your ce config
  * launcher/cheatengine.lpi: to pick for you which .exe to launch
  * \plugin: just example plugins
  * Kernelmoduleunloader.lpi: To unload the driver
  * luaclient.lpi: You'll need this for {$luacode} blocks
  * luaclienttest.lpi: Just a small test project
  * Tutorial\graphical\project1.lpi: If you feel like having the graphical tutorial
  * speedhack.lpi: If you wish to use the speedhack functionality
  * standalonephase2.lpi: If you wish to create standalone trainers. and/or want to trigger anti viruses
  * tutorial.lpi: tutorial. Build it if you think you'll need it. Good app to test stuff on
  * vehdebug.lpi: VEH debug. You'll need this if you with to use the veh debugger
  * windowsrepair.lpi: Only needed if there's a registry setting that blocks CE from executing
  * winhook.lpi : Only needed if you wish to intercept windows messages in the target process
  * xmplayer.lpi: Needed if you wish to play xm files
