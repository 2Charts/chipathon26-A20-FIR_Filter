# Copyright 2025 LibreLane Contributors
# Adapted for Chipathon 2026 A20_BH Macro Slot

source $::env(SCRIPTS_DIR)/openroad/common/io.tcl
source $::env(SCRIPTS_DIR)/openroad/common/set_global_connections.tcl
set_global_connections

set secondary []
foreach vdd $::env(VDD_NETS) gnd $::env(GND_NETS) {
    if { $vdd != $::env(VDD_NET)} {
        lappend secondary $vdd

        set db_net [[ord::get_db_block] findNet $vdd]
        if {$db_net == "NULL"} {
            set net [odb::dbNet_create [ord::get_db_block] $vdd]
            $net setSpecial
            $net setSigType "POWER"
        }
    }

    if { $gnd != $::env(GND_NET)} {
        lappend secondary $gnd

        set db_net [[ord::get_db_block] findNet $gnd]
        if {$db_net == "NULL"} {
            set net [odb::dbNet_create [ord::get_db_block] $gnd]
            $net setSpecial
            $net setSigType "GROUND"
        }
    }
}

set_voltage_domain -name CORE -power $::env(VDD_NET) -ground $::env(GND_NET) \
    -secondary_power $secondary

if { $::env(PDN_MULTILAYER) == 1 } {

    set arg_list [list]
    if { $::env(PDN_ENABLE_PINS) } {
        lappend arg_list -pins "$::env(PDN_VERTICAL_LAYER) $::env(PDN_HORIZONTAL_LAYER)"
    }

    define_pdn_grid \
        -name stdcell_grid \
        -starts_with POWER \
        -voltage_domain CORE \
        {*}$arg_list

    set arg_list [list]
    append_if_equals arg_list PDN_EXTEND_TO "core_ring" -extend_to_core_ring
    append_if_equals arg_list PDN_EXTEND_TO "boundary" -extend_to_boundary

    add_pdn_stripe \
        -grid stdcell_grid \
        -layer $::env(PDN_VERTICAL_LAYER) \
        -width $::env(PDN_VWIDTH) \
        -pitch $::env(PDN_VPITCH) \
        -offset $::env(PDN_VOFFSET) \
        -spacing $::env(PDN_VSPACING) \
        -starts_with POWER \
        {*}$arg_list

    add_pdn_stripe \
        -grid stdcell_grid \
        -layer $::env(PDN_HORIZONTAL_LAYER) \
        -width $::env(PDN_HWIDTH) \
        -pitch $::env(PDN_HPITCH) \
        -offset $::env(PDN_HOFFSET) \
        -spacing $::env(PDN_HSPACING) \
        -starts_with POWER \
        {*}$arg_list

    add_pdn_connect \
        -grid stdcell_grid \
        -layers "$::env(PDN_VERTICAL_LAYER) $::env(PDN_HORIZONTAL_LAYER)"
} else {

    set arg_list [list]
    if { $::env(PDN_ENABLE_PINS) } {
        lappend arg_list -pins "$::env(PDN_VERTICAL_LAYER)"
    }

    define_pdn_grid \
        -name stdcell_grid \
        -starts_with POWER \
        -voltage_domain CORE \
        {*}$arg_list

    set arg_list [list]
    append_if_equals arg_list PDN_EXTEND_TO "core_ring" -extend_to_core_ring
    append_if_equals arg_list PDN_EXTEND_TO "boundary" -extend_to_boundary

    add_pdn_stripe \
        -grid stdcell_grid \
        -layer $::env(PDN_VERTICAL_LAYER) \
        -width $::env(PDN_VWIDTH) \
        -pitch $::env(PDN_VPITCH) \
        -offset $::env(PDN_VOFFSET) \
        -spacing $::env(PDN_VSPACING) \
        -starts_with POWER \
        {*}$arg_list
}

# Adds the standard cell rails if enabled.
if { $::env(PDN_ENABLE_RAILS) == 1 } {
    add_pdn_stripe \
        -grid stdcell_grid \
        -layer $::env(PDN_RAIL_LAYER) \
        -width $::env(PDN_RAIL_WIDTH) \
        -followpins

    add_pdn_connect \
        -grid stdcell_grid \
        -layers "$::env(PDN_RAIL_LAYER) $::env(PDN_VERTICAL_LAYER)"
}

# Adds the core ring if enabled.
if { $::env(PDN_CORE_RING) == 1 } {
    if { $::env(PDN_MULTILAYER) == 1 } {
        set arg_list [list]
        append_if_flag arg_list PDN_CORE_RING_ALLOW_OUT_OF_DIE -allow_out_of_die
        append_if_flag arg_list PDN_CORE_RING_CONNECT_TO_PADS -connect_to_pads
        append_if_equals arg_list PDN_EXTEND_TO "boundary" -extend_to_boundary

        set pdn_core_vertical_layer $::env(PDN_VERTICAL_LAYER)
        set pdn_core_horizontal_layer $::env(PDN_HORIZONTAL_LAYER)

        if { [info exists ::env(PDN_CORE_VERTICAL_LAYER)] } {
            set pdn_core_vertical_layer $::env(PDN_CORE_VERTICAL_LAYER)
        }

        if { [info exists ::env(PDN_CORE_HORIZONTAL_LAYER)] } {
            set pdn_core_horizontal_layer $::env(PDN_CORE_HORIZONTAL_LAYER)
        }

        add_pdn_ring \
            -grid stdcell_grid \
            -layers "$pdn_core_vertical_layer $pdn_core_horizontal_layer" \
            -widths "$::env(PDN_CORE_RING_VWIDTH) $::env(PDN_CORE_RING_HWIDTH)" \
            -spacings "$::env(PDN_CORE_RING_VSPACING) $::env(PDN_CORE_RING_HSPACING)" \
            -core_offset "$::env(PDN_CORE_RING_VOFFSET) $::env(PDN_CORE_RING_HOFFSET)" \
            {*}$arg_list

        if { [info exists ::env(PDN_CORE_VERTICAL_LAYER)] } {
            add_pdn_connect \
                -grid stdcell_grid \
                -layers "$::env(PDN_CORE_VERTICAL_LAYER) $::env(PDN_HORIZONTAL_LAYER)"
        }

        if { [info exists ::env(PDN_CORE_HORIZONTAL_LAYER)] } {
            add_pdn_connect \
                -grid stdcell_grid \
                -layers "$::env(PDN_CORE_HORIZONTAL_LAYER) $::env(PDN_VERTICAL_LAYER)"
        }

        if { [info exists ::env(PDN_CORE_VERTICAL_LAYER)] && [info exists ::env(PDN_CORE_HORIZONTAL_LAYER)] } {
            add_pdn_connect \
                -grid stdcell_grid \
                -layers "$::env(PDN_CORE_VERTICAL_LAYER) $::env(PDN_CORE_HORIZONTAL_LAYER)"
        }

    } else {
        throw APPLICATION "PDN_CORE_RING cannot be used when PDN_MULTILAYER is set to false."
    }
}

# =============================================================================
# Padframe power bridge (A20_BH: connect West VSS and North VDD pins to core ring)
# =============================================================================

set ::_PG_BRIDGE_W_UM   2.0     ;# width (Y) of the VSS and VDD bridges
set ::_PG_M2_LAND_UM    2.0     ;# VDD Metal2 landing reach from the die edge
set ::_PG_M3_EDGE_UM    0.20    ;# Metal3 hop start offset from the die edge
set ::_PG_VIA_ROWS      3       ;# Via2 cut rows per stack  (Y)
set ::_PG_VIA_COLS      3       ;# Via2 cut cols per stack  (X)  -- matches the PDN

proc _pg_template_path {} {
    if {[info exists ::env(FP_DEF_TEMPLATE)] && [file readable $::env(FP_DEF_TEMPLATE)]} {
        return $::env(FP_DEF_TEMPLATE)
    }
    set cfgdir [file dirname $::env(PDN_CFG)]
    set cfg    [file join $cfgdir config.yaml]
    if {[file readable $cfg]} {
        set fh [open $cfg r]; set txt [read $fh]; close $fh
        if {[regexp {FP_DEF_TEMPLATE:\s*dir::(\S+)} $txt -> rel]} {
            set p [file normalize [file join $cfgdir $rel]]
            if {[file readable $p]} { return $p }
        }
    }
    error "power-bridge: could not resolve FP_DEF_TEMPLATE from $cfg"
}

proc _pg_template_pin_rows {net_name} {
    set fh [open [_pg_template_path] r]
    set tdbu 1000
    set rows {}
    set in 0
    while {[gets $fh line] >= 0} {
        if {[regexp {UNITS\s+DISTANCE\s+MICRONS\s+(\d+)} $line -> u]} {
            set tdbu $u; continue
        }
        if {[regexp {^-\s+(\S+)\s+\+\s+NET\s+(\S+)} $line -> pn nn]} {
            set in [expr {$nn eq $net_name}]; continue
        }
        if {$in} {
            if {[regexp {LAYER\s+Metal2\s+\(\s*(-?\d+)\s+(-?\d+)\s*\)\s+\(\s*(-?\d+)\s+(-?\d+)\s*\)} \
                     $line -> x1 y1 x2 y2]} {
                lappend rows [list $y1 $y2 $x2]
            }
            if {[string first ";" $line] >= 0} { set in 0 }
        }
    }
    close $fh
    return [list $tdbu $rows]
}

proc _pg_template_pin_cols {net_name} {
    set fh [open [_pg_template_path] r]
    set tdbu 1000
    set cols {}
    set in 0
    while {[gets $fh line] >= 0} {
        if {[regexp {UNITS\s+DISTANCE\s+MICRONS\s+(\d+)} $line -> u]} {
            set tdbu $u; continue
        }
        if {[regexp {^-\s+(\S+)\s+\+\s+NET\s+(\S+)} $line -> pn nn]} {
            set in [expr {$nn eq $net_name}]; continue
        }
        if {$in} {
            if {[regexp {LAYER\s+Metal2\s+\(\s*(-?\d+)\s+(-?\d+)\s*\)\s+\(\s*(-?\d+)\s+(-?\d+)\s*\)} \
                     $line -> x1 y1 x2 y2]} {
                lappend cols [list $x1 $x2 $y1]
            }
            if {[string first ";" $line] >= 0} { set in 0 }
        }
    }
    close $fh
    return [list $tdbu $cols]
}

proc _pg_west_leg {net} {
    set best ""
    foreach sw [$net getSWires] {
        foreach box [$sw getWires] {
            if {[$box isVia]} { continue }
            set ly [$box getTechLayer]
            if {$ly eq "NULL" || [$ly getName] ne "Metal2"} { continue }
            set w [expr {[$box xMax] - [$box xMin]}]
            set h [expr {[$box yMax] - [$box yMin]}]
            if {$h < 5 * $w} { continue }
            if {$best eq "" || [$box xMin] < [lindex $best 0]} {
                set best [list [$box xMin] [$box xMax]]
            }
        }
    }
    return $best
}

proc _pg_north_leg {net} {
    set best ""
    foreach sw [$net getSWires] {
        foreach box [$sw getWires] {
            if {[$box isVia]} { continue }
            set ly [$box getTechLayer]
            if {$ly eq "NULL" || [$ly getName] ne "Metal3"} { continue }
            set w [expr {[$box xMax] - [$box xMin]}]
            set h [expr {[$box yMax] - [$box yMin]}]
            if {$w < 5 * $h} { continue }
            if {$best eq "" || [$box yMax] > [lindex $best 1]} {
                set best [list [$box yMin] [$box yMax]]
            }
        }
    }
    return $best
}

proc _pg_make_stack_via {block name m2 v2 m3 nrow ncol} {
    set v [odb::dbVia_create $block $name]
    $v setViaGenerateRule [[$block getTech] findViaGenerateRule "Via2_GEN_HH"]
    set cs [expr {($nrow >= 4 || $ncol >= 4) ? 720 : 520}]
    set p  [$v getViaParams]
    $p setBottomLayer $m2
    $p setCutLayer    $v2
    $p setTopLayer    $m3
    $p setXCutSize 520 ; $p setYCutSize 520
    $p setXCutSpacing $cs ; $p setYCutSpacing $cs
    $p setXBottomEnclosure 120 ; $p setYBottomEnclosure 120
    $p setXTopEnclosure    120 ; $p setYTopEnclosure    120
    $p setNumCutRows $nrow ; $p setNumCutCols $ncol
    $v setViaParams $p
    return $v
}

proc _pg_build_power_bridges {} {
    if {[info exists ::_PG_DONE]} { return }
    set ::_PG_DONE 1
    set block [ord::get_db_block]
    set tech  [ord::get_db_tech]
    set dbu   [$block getDbUnitsPerMicron]
    set m2    [$tech findLayer Metal2]
    set v2    [$tech findLayer Via2]
    set m3    [$tech findLayer Metal3]
    
    set bw    [expr {int($::_PG_BRIDGE_W_UM * $dbu)}]
    set colv  [_pg_make_stack_via $block PG_V2_COL $m2 $v2 $m3 \
                   $::_PG_VIA_ROWS $::_PG_VIA_COLS]

    set vdd [$block findNet VDD]
    set vss [$block findNet VSS]

    # ---- VSS (West Edge) ----
    set vss_leg [_pg_west_leg $vss]
    if {$vss_leg eq ""} {
        puts "\[ERROR\] power-bridge: could not find VSS core-ring leg!"
    } else {
        lassign $vss_leg vssL vssR
        puts "\[INFO\] power-bridge: VSS leg x=($vssL $vssR)"
        lassign [_pg_template_pin_rows VSS] tdbu rows
        set sc [expr {double($dbu) / $tdbu}]
        set sw [odb::dbSWire_create $vss "ROUTED"]
        foreach r $rows {
            lassign $r y1 y2 x2
            set cy [expr {int(($y1 + $y2) * 0.5 * $sc)}]
            set bx1 0
            set by1 [expr {int($cy - $bw / 2)}]
            set bx2 $vssR
            set by2 [expr {int($cy + $bw / 2)}]
            odb::dbSBox_create $sw $m2 $bx1 $by1 $bx2 $by2 "STRIPE"
        }
    }

    # ---- VDD (North Edge) ----
    set vdd_leg [_pg_north_leg $vdd]
    if {$vdd_leg eq ""} {
        puts "\[ERROR\] power-bridge: could not find VDD core-ring leg!"
    } else {
        lassign $vdd_leg vddB vddT
        puts "\[INFO\] power-bridge: VDD leg y=($vddB $vddT)"
        lassign [_pg_template_pin_cols VDD] tdbu cols
        set sc [expr {double($dbu) / $tdbu}]
        set sw  [odb::dbSWire_create $vdd "ROUTED"]
        set nv 0
        foreach c $cols {
            lassign $c x1 x2 y1
            set cx [expr {int(($x1 + $x2) * 0.5 * $sc)}]
            set ty [expr {int(550.0 * $dbu)}]
            
            set bx1 [expr {int($cx - $bw / 2)}]
            set by1 $vddB
            set bx2 [expr {int($cx + $bw / 2)}]
            set by2 $ty
            
            odb::dbSBox_create $sw $m2 $bx1 $by1 $bx2 $by2 "STRIPE"
            
            set vy [expr {int(($vddB + $vddT) / 2)}]
            odb::dbSBox_create $sw $colv $cx $vy "STRIPE"
            incr nv 1
        }
    }
}

if {[info commands pdngen] ne "" && [info commands _pg_pdngen_real] eq ""} {
    rename pdngen _pg_pdngen_real
    proc pdngen {args} {
        set rc [uplevel 1 [list _pg_pdngen_real {*}$args]]
        if {[catch {_pg_build_power_bridges} emsg]} {
            puts stderr "\[ERROR\] power-bridge builder failed: $emsg"
            puts stderr $::errorInfo
        }
        return $rc
    }
}
