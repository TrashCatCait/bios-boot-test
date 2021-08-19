# BIOS-BOOTLOADER/CHAINLOADER project:
This project is a MBR bootloader that will boot the VBR of any disk and execute the code contained there. It's intended to be used with my OS project though currently can't boot the kernel.

### Goals:

- Make a BIOS compatible chain-loader and stage2 boot-loader for my os-kernel project. That is FOSS.
- Learn more about the boot process of a BIOS computers (UEFI is cool but I feel I've learned so much more from bios than UEFI.)
- Try to get it working on real hardware (current: Tested on my MSI motherboard B450 chip set, BIOS Ver: H.70, Disk: Sandisk 235G ssd, Observation: appears to work correctly)
- Just overall a fun project that I enjoy making and working on.

___

# How To Build:

So currently to build this project you simply need to either run the make file provided or run `nasm -fbin src/start.asm -o mbr.bin`. This will change as I start work on stage2 and so though. Please see listed tool versions below if errors are encountered while building.

---

# Tools Used:
Below are the tools and version numbers I use for building. before filling out a issue due to an error building I would suggest trying to assemble with the below versions. As it's rare but sometimes differences in tool versions can cause issues. Especially when there is a large difference in version.

- Make(Version 4.3)
- nasm(Version 2.15.05)

___

# Issues:

### Building Issues:
If you encountered an error during building this project I'd suggest double checking our tool versions are the same and checking you're on the master branch as it could just be a broken unstable branch. But if none of the above helped you and you're still facing issues please feel free to file an issues with a descriptive title and the output of your nasm assembler for debuging.

### Other/Runtime Issues:
So if you encounter a problem during running and you suspect it's a bug or mistake please file a detailed report. Describing the bug and anything you did to cause it and the type of media you booted off of.


But if you suspect that it's an issue related to your BIOS or if I attempt to replicate it but am unable to I'll likely ask for you're hardware setup(Mainly motherboard and BIOS version and the boot media used{usb, HDD, m.2/Sata SSD}) as this could be potential causes if your BIOS maybe operates slightly differently. 

I will always try to make this runnable across all machines and BIOS but I can't test this or promise this but I will attempt to fix bugs related to different BIOS when they are reported to me. 

---

# Contributing: 

Help with the project and code contributions are always welcome. Though I do have a few requests for anyone that wants to do this. Please test you code before submitting a pull request or issue as I will be testing it as well to make sure it merges well and doesn't break anything less obvious. So not 100% needed but potentially could save me time.

If your code does have issues/isn't bug free and you don't know how to fix it. Feel free to still submit a request others including myself can potentially help solve the bug.

For small changes pull requests are more than welcome but for larger changes to the code base I would prefer for you to file an issue to being with [MERGE REQUEST] in the title with a detailed description of what you code is. Why you think it should be changed and what exactly the changed code does. E.G. "[MERGE REQUEST] Code update to fix program on old BIOS versions"


# FAQ
Currently empty but any questions I find myself answering a lot will be added as time goes on.

___

# Branches

- `Master` this branch is what I consider to be the up to date stable code and a good effort to make it bug free and working will always be taken. Along with giving me a clean empty branch to fall back on if I make a huge mistake on other branches.
- `Unstable` like the name suggest this branch is where I push the most recent and unstable/untested code. There is less guarantees about this branch actually working but of course an effort will still be made to ensure it "works". But this branch will also reflect what I'm currently working on.

___

# What's supported

- [x] Booting from the master SATA drive on first ATA bus located at legacy port 0x01f0
- [ ] Booting from the non master/master drives on any other ATA bus 
- [ ] USB booting (as stage2 bootloader can't read from USB currently)
- [ ] CD-ROM (Untested but I assume this doesn't work)
- [ ] Floopy drive(Untested I assume it doesn't work)
- [ ] m.2 SSD (Untested I assume this doesn't work. Though I think they also use ATA buses iinm)
