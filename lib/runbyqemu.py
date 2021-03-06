import argparse,subprocess,os,multiprocessing

DEFAULT_HD_IMAGE_0 = "testvm-hda.img"
DEFAULT_HD_IMAGE_1 = "testvm-hdb.img"
DEFAULT_HD_SIZE = "8G"

def create_hd_image_if_not_exist(hdimage, size=DEFAULT_HD_SIZE):
    if os.path.exists(hdimage): return
    #else
    print "Creating virtual HD image %s" % hdimage
    subprocess.check_call(["qemu-img","create","-f","raw",hdimage,size])

def run(cdimage, hda, hdb, memory, no64, cirrus, tap, vnc, soundhw, smp):
    if cdimage == None and not os.path.exists(hda):
        print "Fresh HD without CD, what are you going to do with it?"
        return False
    create_hd_image_if_not_exist(hda)

    cmdline = ["qemu-system-x86_64","-enable-kvm","-hda",hda,"-rtc","base=utc,clock=rt","-m",str(memory),"-smp",str(smp)]

    if hdb is not None:
        create_hd_image_if_not_exist(hdb)
        cmdline += ["-hdb", hdb]

    if cdimage is not None: cmdline += ["-cdrom",cdimage,"-boot","order=dc"]
    if no64: cmdline += ["-cpu", "host,-lm"]
    if cirrus: cmdline += ["-vga","cirrus"]
    if tap: cmdline += ["-net","tap,ifname=%s,script=no,downscript=no" % tap, "-net","nic"]
    if vnc: cmdline += ["-vnc",vnc]
    if soundhw: cmdline += ["-soundhw", soundhw]
    os.execvp("qemu-system-x86_64", cmdline)

def get_number_of_physical_cpu_cores():
    try:
        return int(subprocess.check_output("grep 'core id' /proc/cpuinfo | sort | uniq | wc -l", shell=True))
    except:
        return 1
    
if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument("cdimage", type=str, nargs='?', help="ISO9660 image")
    parser.add_argument("--hda", type=str, default=DEFAULT_HD_IMAGE_0, help="HD0 image")
    parser.add_argument("--hdb", type=str, nargs='?', const=DEFAULT_HD_IMAGE_1, help="HD1 image")
    parser.add_argument("--memory","-m", type=int, default=4096, help="Memory in MB")
    parser.add_argument("--no64", action="store_true", help="32bit mode")
    parser.add_argument("--cirrus", action="store_true", help="Use cirrus logic video emulation")
    parser.add_argument("--tap", type=str, nargs='?', const="tap0", help="TAP device to use as a bridged network")
    parser.add_argument("--vnc", type=str, nargs='?', const=":0", help="Use VNC instead of showing physical screen")
    parser.add_argument("--soundhw", type=str, nargs='?', const="ac97", help="Sound card emulation")
    parser.add_argument("--smp", type=int, default=get_number_of_physical_cpu_cores(), help="Number of CPU")
    args = parser.parse_args()
    run(args.cdimage, args.hda, args.hdb, args.memory, args.no64, args.cirrus, args.tap, args.vnc, args.soundhw, args.smp)
