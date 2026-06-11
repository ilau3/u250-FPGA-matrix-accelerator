# gen_xo.tcl <xoname> <krnl_name> <target> <xpfm_path> <device>
# Runs package_kernel.tcl, then wraps the packaged IP into a .xo object that
# v++ can link against a platform.

if { $::argc != 5 } {
    puts "ERROR: requires 5 args: <xoname> <krnl_name> <target> <xpfm_path> <device>"
    exit 1
}

set xoname    [lindex $::argv 0]
set krnl_name [lindex $::argv 1]
set target    [lindex $::argv 2]
set xpfm_path [lindex $::argv 3]
set device    [lindex $::argv 4]

set suffix "${krnl_name}_${target}_${device}"

source -notrace ./scripts/package_kernel.tcl

if {[file exists "${xoname}"]} {
    file delete -force "${xoname}"
}

package_xo -xo_path ${xoname} -kernel_name ${krnl_name} -ip_directory ./build/packaged_kernel_${suffix}
