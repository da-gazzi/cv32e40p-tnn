##################################################################################
### This script is find all the possible DFM PM.M2.C.1 violation locations
### and then delete the redundant patch M2 to avoid the violation.
###
### This reduces the iteration time from calibre drc checking to Innovus fixing.
### 
### by DZ zerun - v1 - 2 Sep 2021
##################################################################################

### fix DFM PM.M2.C.1
echo "###\nfinding possible DFM PM.M2.C.1 violations... \n###"
set listVia01Bar [dbGet top.nets.vias.via.name -regexp  VIA01_BAR_V_ -p2]
#set listVia [dbGet top.nets.vias.via {.name=="NR_VIA2_AYBAR_HV_VS" || .name=="NR_VIA2_AYBAR_HV_VN"} -p] ; finding all the VIA02 is taking much longer than VIA01

set patchWire_list {}
set i 1
foreach Via01Bar $listVia01Bar  {
  set box [dbGet $Via01Bar.topRects]
  set offCenterVia02 [dbGet [dbQuery -area [lindex $box 0] -objType {ViaInst}].via. {.name=="VIA02_BAR_V_20_10_2_30_AY_LS" || .name=="VIA02_BAR_V_20_10_2_30_AY_LN"} -p]
  if { $offCenterVia02 != "0x0"} {
    set boxVia02 [dbGet $offCenterVia02.botRects]
    if {[dbShape $box ENCLOSE $boxVia02] == ""} {
      set patchWire [dbGet [dbQuery -area [lindex $boxVia02 0] -objType pWire].layer.name M2 -p2]
      foreach patchW $patchWire {
        if {[dbGet $patchW.box_sizey] == 0.04 } {
          set boxPatchM2 [dbGet $patchW.box]
          createMarker -bbox [lindex $boxPatchM2 0] -type DZ.DFM.PM.M2.C.1
          echo "creating violation mark #$i on patch M2 $boxPatchM2"; incr i
          lappend patchWire_list $patchW
        }
      }
    }
  }
}
deselectAll
select_obj $patchWire_list
echo "###\nDelete the patch M2 around problematic VIA02s,\nYou can check the deleted patch M2 box on Violation Browser"
editDelete -selected
