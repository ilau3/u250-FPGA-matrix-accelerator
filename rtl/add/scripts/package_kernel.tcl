# package_kernel.tcl
# Packages the RTL sources in src/hdl as a Vitis RTL "kernel" IP.
# Adapted from Xilinx Vitis_Accel_Examples/rtl_kernels/rtl_vadd.
#
# The key job here is to describe, in the IP's memory map, the AXI4-Lite
# control register layout that XRT/Vitis expect for a kernel:
#   0x00 CTRL  (ap_start/ap_done/ap_idle/ap_ready/auto_restart)
#   0x04 GIER, 0x08 IP_IER, 0x0C IP_ISR
#   0x10 a   (64-bit pointer)   <- setArg index 0
#   0x1C b   (64-bit pointer)   <- setArg index 1
#   0x28 c   (64-bit pointer)   <- setArg index 2
#   0x34 length (32-bit scalar) <- setArg index 3
# These offsets MUST match the decode logic in krnl_vadd_rtl_control_s_axi.v.

set path_to_hdl       "./src/hdl"
set path_to_packaged  "./build/packaged_kernel_${suffix}"
set path_to_tmp_project "./build/tmp_kernel_pack_${suffix}"

create_project -force kernel_pack $path_to_tmp_project
add_files -norecurse [glob $path_to_hdl/*.v $path_to_hdl/*.sv]
update_compile_order -fileset sources_1
update_compile_order -fileset sim_1
ipx::package_project -root_dir $path_to_packaged -vendor xilinx.com -library RTLKernel -taxonomy /KernelIP -import_files -set_current false
ipx::unload_core $path_to_packaged/component.xml
ipx::edit_ip_in_project -upgrade true -name tmp_edit_project -directory $path_to_packaged $path_to_packaged/component.xml

set core [ipx::current_core]

set_property core_revision 2 $core
foreach up [ipx::get_user_parameters] {
  ipx::remove_user_parameter [get_property NAME $up] $core
}
ipx::associate_bus_interfaces -busif m_axi_gmem -clock ap_clk $core
ipx::associate_bus_interfaces -busif s_axi_control -clock ap_clk $core

set mem_map    [::ipx::add_memory_map -quiet "s_axi_control" $core]
set addr_block [::ipx::add_address_block -quiet "reg0" $mem_map]

set reg      [::ipx::add_register "CTRL" $addr_block]
  set_property description    "Control signals"    $reg
  set_property address_offset 0x000 $reg
  set_property size           32    $reg
set field [ipx::add_field AP_START $reg]
  set_property ACCESS {read-write} $field
  set_property BIT_OFFSET {0} $field
  set_property BIT_WIDTH {1} $field
  set_property DESCRIPTION {Control signal Register for 'ap_start'.} $field
  set_property MODIFIED_WRITE_VALUE {modify} $field
set field [ipx::add_field AP_DONE $reg]
  set_property ACCESS {read-only} $field
  set_property BIT_OFFSET {1} $field
  set_property BIT_WIDTH {1} $field
  set_property DESCRIPTION {Control signal Register for 'ap_done'.} $field
  set_property READ_ACTION {modify} $field
set field [ipx::add_field AP_IDLE $reg]
  set_property ACCESS {read-only} $field
  set_property BIT_OFFSET {2} $field
  set_property BIT_WIDTH {1} $field
  set_property DESCRIPTION {Control signal Register for 'ap_idle'.} $field
  set_property READ_ACTION {modify} $field
set field [ipx::add_field AP_READY $reg]
  set_property ACCESS {read-only} $field
  set_property BIT_OFFSET {3} $field
  set_property BIT_WIDTH {1} $field
  set_property DESCRIPTION {Control signal Register for 'ap_ready'.} $field
  set_property READ_ACTION {modify} $field
set field [ipx::add_field RESERVED_1 $reg]
  set_property ACCESS {read-only} $field
  set_property BIT_OFFSET {4} $field
  set_property BIT_WIDTH {3} $field
  set_property DESCRIPTION {Reserved.  0s on read.} $field
  set_property READ_ACTION {modify} $field
set field [ipx::add_field AUTO_RESTART $reg]
  set_property ACCESS {read-write} $field
  set_property BIT_OFFSET {7} $field
  set_property BIT_WIDTH {1} $field
  set_property DESCRIPTION {Control signal Register for 'auto_restart'.} $field
  set_property MODIFIED_WRITE_VALUE {modify} $field
set field [ipx::add_field RESERVED_2 $reg]
  set_property ACCESS {read-only} $field
  set_property BIT_OFFSET {8} $field
  set_property BIT_WIDTH {24} $field
  set_property DESCRIPTION {Reserved.  0s on read.} $field
  set_property READ_ACTION {modify} $field

set reg      [::ipx::add_register "GIER" $addr_block]
  set_property description    "Global Interrupt Enable Register"    $reg
  set_property address_offset 0x004 $reg
  set_property size           32    $reg

set reg      [::ipx::add_register "IP_IER" $addr_block]
  set_property description    "IP Interrupt Enable Register"    $reg
  set_property address_offset 0x008 $reg
  set_property size           32    $reg

set reg      [::ipx::add_register "IP_ISR" $addr_block]
  set_property description    "IP Interrupt Status Register"    $reg
  set_property address_offset 0x00C $reg
  set_property size           32    $reg

set reg      [::ipx::add_register -quiet "a" $addr_block]
  set_property address_offset 0x010 $reg
  set_property size           [expr {8*8}]   $reg
  set regparam [::ipx::add_register_parameter -quiet {ASSOCIATED_BUSIF} $reg]
  set_property value m_axi_gmem $regparam

set reg      [::ipx::add_register -quiet "b" $addr_block]
  set_property address_offset 0x01C $reg
  set_property size           [expr {8*8}]   $reg
  set regparam [::ipx::add_register_parameter -quiet {ASSOCIATED_BUSIF} $reg]
  set_property value m_axi_gmem $regparam

set reg      [::ipx::add_register -quiet "c" $addr_block]
  set_property address_offset 0x028 $reg
  set_property size           [expr {8*8}]   $reg
  set regparam [::ipx::add_register_parameter -quiet {ASSOCIATED_BUSIF} $reg]
  set_property value m_axi_gmem $regparam

set reg      [::ipx::add_register -quiet "length_r" $addr_block]
  set_property address_offset 0x034 $reg
  set_property size           [expr {4*8}]   $reg

set_property slave_memory_map_ref "s_axi_control" [::ipx::get_bus_interfaces -of $core "s_axi_control"]

set_property xpm_libraries {XPM_CDC XPM_MEMORY XPM_FIFO} $core
set_property sdx_kernel true $core
set_property sdx_kernel_type rtl $core
set_property supported_families { } $core
set_property auto_family_support_level level_2 $core
ipx::create_xgui_files $core
ipx::update_checksums $core
ipx::check_integrity -kernel $core
ipx::save_core $core
close_project -delete
