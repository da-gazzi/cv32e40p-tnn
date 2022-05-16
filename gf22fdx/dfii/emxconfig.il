;;; v2 Zerun Mon  2 May 12:54:16 CEST 2022
;;; define varible in here

;;; v1  Zerun, Thu 2 Apr 10:04:21 CEST 2022
;;;  change below variables:
;;; EMX_interface_path, EMX_layer_table, EMX_EMX_opts, EMX_process_path, EMX_process_name, EMX_path



GF_PDK_HOME = getShellEnvVar("GF_PDK_HOME")
BEOL_STACK  = getShellEnvVar("BEOL_STACK")
EMXHOME = getShellEnvVar("EMXHOME")


; EMX_interface_path tells where you've installed the interface.  This
; file (emxconfig.il) is in EMX_interface_path/emxskill/
EMX_interface_path=(strcat EMXHOME "/share/emx/virtuoso_ui/emxinterface")

; Variables marked with *TF* can depend on the technology library.  To
; use this feature, make the variable an association list like
; (("techlib1" "value1") ("techlib2" "value2") ...).  If the tech
; library is "techlib1", the variable will have value "value1", etc.
; Use t for the tech library if you want a default value.  Example
;EMX_process_name='(("tsmcN28" "emx28.proc") ("tsmcN20" "emx20.proc") (t nil))

; EMX_layer_table (*TF*) has the layer table for streaming out GDSII
; (needed if the technology file does not have this information)
; EMX_layer_table=(strcat EMX_interface_path "/emxskill/layers.txt")
EMX_layer_table=(strcat GF_PDK_HOME "/DesignEnv/VirtuosoOA/libs/cmos22fdsoi_tech_" BEOL_STACK "/cmos22fdsoi_tech.layermap")

; EMX_layout_type (*TF*) selects the type of stream out, GDSII or OASIS
; EMX_layout_type='(("tsmcN07" "oasis") (t "gds"))
EMX_layout_type="gds"
; EMX_stream_options (*TF*) has any extra info that should be added to
; the stream out configuration file
; EMX_stream_options='(("tsmcN07" "enableColoring \"true\"") (t ""))
EMX_stream_options=""

; EMX_EMX_opts (*TF*) sets the default command-line options for EMX on
; the advanced options form. EMX_GDSview_opts (*TF*) is for GDSview;
; it defaults to the same value as EMX_EMX_opts. EMX_combined_opts
; (*TF*) sets options used for both EMX and GDSview.
EMX_combined_opts="--key=EMXkey"
EMX_EMX_opts=""
;EMX_GDSview_opts=""

; EMX_process_path (*TF*) tells where you keep EMX process files
EMX_process_path=(strcat GF_PDK_HOME "/Emagnetic/EMX/" BEOL_STACK "thick")

; EMX_process_name (*TF*) is the process file name (sans path).  Nil
; means take the first .proc file in the EMX_process_path directory
EMX_process_name=(strcat "22fdsoi_" BEOL_STACK "thick_nominal_detailed.encrypted.proc")

; EMX_process_aliases (*TF*) is an association list of abbreviated
; names of processes, e.g., (("typ" "long_name_for_nominal_proc_file"))
EMX_process_aliases=nil

; EMX_hilight_layers (*TF*); see discussion in emxform.ils
;EMX_hilight_layers='((instance ("hilite" "drawing"))
;                     (fixed ("marker" "info"))
;                     (warning ("marker" "ackWarn"))
;                     (error ("marker" "critical")))

; If you want to run EMX on a remote machine, set this to the machine
; name (or IP address).  You must be able to execute a command on the
; remote machine via "ssh machine command" without requiring a
; password.  See the ssh man page for authentication options.  If you
; want to run EMX locally, set this to nil or the empty string ("").
; If your organization uses the bsub facility, you can set this to a
; string of the form "bsub ..." to invoke EMX via bsub.  Specify
; default options for things like the queue as part of the "...".
; (You can also use qsub in the same way as bsub.)  For more
; complicated possibilities, see the user-defined batch processing
; comment in emxform.ils.
;EMX_remote_machine="bsub -q desired_queue"
;EMX_remote_machine="qsub -q desired_queue"
EMX_remote_machine=""

; If using SSH for remote execution, set this to customize the ssh
; command
;EMX_ssh_cmd=(lambda (machine script) (sprintf nil "ssh %s 'sh %s'" machine script))
;EMX_ssh_cmd=(lambda (machine script)
;	      (sprintf nil "ssh %s bash -c 'true; export PATH=%s; export CDS_LIC_FILE=%s; . %s'"
;		       machine (getShellEnvVar "PATH") (getShellEnvVar "CDS_LIC_FILE") script))))

; EMX_path tells where you've installed the EMX executables (emx,
; modelgen, gdsview)
EMX_path=(strcat EMXHOME "/bin")

; EMX_ps_viewer and EMX_pdf_viewer are the applications used for
; viewing PostScript or PDF files (EMX versions prior to 2.13 can only
; produce PostScript files).  Common alternatives include gv, ggv,
; evince, okular, konqueror, and acroread
EMX_ps_viewer="evince"
;EMX_pdf_viewer="evince"  ; when unset, defaults to EMX_ps_viewer

; EMX_visualize gives the executable for mesh/current/charge display.
; If EMX_vtu is t, this should be ParaView.
EMX_visualize=nil
;EMX_visualize="paraview"
;EMX_visualize="matlab -nosplash -desktop -r"
;EMX_visualize="octave --persist --gui --eval"
;EMX_visualize="" ; Visualization options but no viewer buttons
;EMX_paraview_python=t  ; t => your ParaView has Python support

; Setting EMX_log_displayer to a string makes the interface spawn an
; external process to display the log file.  The string should contain
; a %s where the name of the log file should go.  Nil means use the
; internal Cadence viewer.
EMX_log_displayer=nil
;EMX_log_displayer="xterm -title 'EMX output' -e tail -f %s"

; By default, the interface puts all of the EMX files associated with
; a particular library and cell in the subdirectory lib_cell.work of
; the current directory, where lib and cell are the Cadence library
; and cell names.  If you want to put all of these lib_cell.work
; directories in a different place, set EMX_working_dir to that place.
EMX_working_dir="./EMX_work"
;EMX_working_dir="."
;EMX_working_dir="/where/I/want/the/interface/to/put/EMX/files"

; This option is a command for starting a documentation viewer.  When
; nil, the documentation button is not shown.
;EMX_documentation=nil  ; default if variable is unset
;EMX_documentation=(sprintf nil "dolphin %s > /dev/null 2>&1 < /dev/null &"
;                           (sprintf nil "%s/EMX_documentation" EMX_interface_path))
EMX_documentation=(sprintf nil "nautilus %s > /dev/null 2>&1 < /dev/null &"
                           (sprintf nil "%s/EMX_documentation" EMX_interface_path))

; Set view_name to a string like "sparam" to make a new view that
; holds the S-parameters for n-port models.  If there's a shell
; variable that holds a prefix of the library directory and you want
; the n-port to be relative to that directory, then set view_prefix to
; the name of the shell variable.
;EMX_nport_sparam_view_name=nil   ; view name, e.g., "sparam"
;EMX_nport_sparam_view_prefix=nil ; name of shell var, e.g., "PROJ_ROOT"
                                  ; or you can put the form of the
                                  ; prefix with shell variables, like
                                  ; "$HOME/projects/$PROJECT"

; Auto-configured to t if EMX_nport_sparam_view_name is set and if
; analogLib/nport supports lib/cell/view for specifying S-parameters.
; Set explicitly to nil to force using a filename.
;EMX_nport_use_cellview=nil

; Variables marked as *AC* are set automatically according to the
; installed version of EMX and ModelGen.  Use EMX_auto_config=nil to
; disable this.  EMX_auto_config='((EMX_vtu t) ...) auto-configures
; but forces certain variables to the given values.
EMX_auto_config=t

; EMX_pole_zero_models (*AC*) enables general state-space model
; creation.  EMX must support the --model-file option.
EMX_pole_zero_models=t

; EMX_black_box (*AC*) enables black box support in the interface.  It
; requires a version of EMX that supports --device-cells-file.
EMX_black_box=nil

; EMX_connectivity (*AC*) enables DC connectivity (LVS) support.  EMX
; must support the --dump-connectivity option.
EMX_connectivity=nil

; EMX_frequency_indep (*AC*) enables frequency-independent Green's
; function support.  EMX must support --frequency-independent.
EMX_frequency_indep=nil

; Set EMX_cadence_dev_info (*AC*) if EMX and GDSview recognize Cadence
; information for black-box devices
EMX_cadence_dev_info=nil

; Set EMX_dev_term_mapping (*AC*) if EMX and GDSview support remapping
; of pins in black-box devices
EMX_dev_term_mapping=nil

; EMX_dynamic_frequencies (*AC*) indicates whether EMX can dynamically
; set the maximum number of sweep frequencies being solved for (i.e.,
; whether --simultaneous-frequencies=0 is allowed)
EMX_dynamic_frequencies=nil

; EMX_port_collapsing (*AC*) indicates whether EMX supports automatic
; merging of ports that are strongly connected via short low-impedance
; paths
EMX_port_collapsing=nil

; EMX_log_sweep (*AC*) indicates whether EMX supports logarithmic
; frequency sweeps
EMX_log_sweep=nil

; EMX_vtu (*AC*) indicates whether EMX supports VTU output format for
; meshes and for current and charge display.  See also EMX_visualize
EMX_vtu=nil

; EMX_cdslic (*AC*) is set when EMX uses the Cadence license daemon
EMX_cdslic=nil

; EMX_8cpu_lic (*AC*) is t when EMX supports EMX_Solve_V8 licenses
EMX_8cpu_lic=nil

; EMX_memory (*AC*) indicates whether EMX supports the
; --recommended-memory option
EMX_memory=nil

; EMX_printproc_text (*AC*) is t when EMX can output a text file
; containing the conductors and vias in the process file
EMX_printproc_text=nil

; EMX_mpi (*AC*) is t when EMX supports multi-machine execution via
; MPI
EMX_mpi=nil

; EMX_oasis (*AC*) is t when EMX and GDSview support the OASIS stream
; format
EMX_oasis=nil

; EMX_multimask (*AC*) says if EMX and GDSview support multiple masks
EMX_multimask=nil

; EMX_bb_pin_check (*AC*) is t if EMX and GDSview support black box
; pin checking
EMX_bb_pin_check=nil

; EMX_log_time (*AC*) tells if EMX supports --log-time-level
EMX_log_time=nil

; EMX_mg_global_interp (*AC*) if ModelGen recognizes the
; --global-interp option
EMX_mg_global_interp=nil

; These are the original style extracted view names (and defaults)
;EMX_symbol_name="symbol"
;EMX_symbol_nport_name="symbol_nport"
;EMX_schematic_name="schematic"
;EMX_schematic_nport_name="schematic_nport"
;EMX_schematic_pz_name="schematic"
;EMX_schematic_dc_name="EMX_dc"
; These are the new style extracted view names
;EMX_symbol_name="symbol"
;EMX_symbol_nport_name="symbol"
;EMX_schematic_name="EMX_model"
;EMX_schematic_nport_name="EMX_spar"
;EMX_schematic_pz_name="EMX_pz"
;EMX_schematic_dc_name="EMX_dc"
; Optional views produced with symbol and symbol_nport
;EMX_aucdl_name="auCdl"  ; string, or nil to not generate
;EMX_aulvs_name="auLvs"  ; string, or nil to not generate
;EMX_minilayout_layers=nil  ; (*TF*) string of layers for mini-layout symbols
; A procedure giving the resistor used for DC views (see
; EMX_dc_view_default_res for an example)
;EMX_dc_view_res=nil  ; for analogLib/res + lxRemoveDevice property

; Simulation cases (see manual for details)
;EMX_use_case_name=nil  ; nil => old style, t => case support
;EMX_form_state_name="EMX_form"
;EMX_form_defaults_lib=nil  ; (*TF*)
;EMX_form_defaults_cell="EMX_defaults"  ; (*TF*)
;EMX_form_defaults_view="EMX_form%_c"  ; (*TF*)
;EMX_case_assistant_values=nil  ; (*TF*) see case assistant comment in emxform.ils

; Miscellaneous
;EMX_new_style_form_state=t  ; nil => old style, t => tag extra fields
;EMX_bsub_default=nil  ; t => default "Use bsub" field to selected
;EMX_job_limit=999     ; maximum number of jobs to run at once
;EMX_viewproc_local=t  ; nil => emx --print-proc via bsub instead of locally
;EMX_spectre_local=t   ; nil => run spectre via bsub instead of locally
;EMX_modelgen_local=t  ; nil => to run modelgen via bsub instead of locally
;EMX_spectre_command="spectre"  ; maybe "PATH=/path/to/cadence/bin: spectre"
;EMX_modelgen_path=EMX_path  ; if modelgen is in a different place
;EMX_internal_PSF_reader=nil  ; probably not needed anymore
;EMX_xsection_opts=""  ; use --generate-pdf for PDF instead of PostScript
;EMX_specialized_models=t  ; nil => modelgen models use generic model form
;EMX_RLCK_model_schematics=t  ; nil => non-generic modelgen models have an
			      ; instance reference, t => use an RLCK schematic
;EMX_model_port_checking=t  ; nil => don't check ports before running modelgen
;EMX_GDSview_show_status=nil  ; t => show status window for GDSview
;EMX_new_style_menu_trigger=t  ; probably not needed anymore
;EMX_fixed_cell_name=nil ; t => name instead of [@cellName] in n-port symbol
;EMX_global_ref_ground=nil ; t => implicit references can use gnd!
;EMX_dialog_msgs=0 ; 0 => warn and info use dialog box
		   ; 1 => warn uses dbox; info goes to CIW
		   ; 2 => warn and info go to CIW
;EMX_log_time_level=nil ; 2, 3, 4 show more time/mem summaries when running
			; nil means don't show any
;EMX_save_process_path=nil ; nil => always search EMX_process_path for .proc
			   ; t => save EMX_process_path in forms at form
			   ;   creation time, ignore later changes in
			   ;   EMX_process_path
			   ; 'override => include EMX_process_path in form
			   ;   state when saving, and set EMX_process_path
			   ;   based on saved value when loading a form
;EMX_form_init_proc=nil ; symbol = function to call after form creation
 			; arguments are basic form and advanced form
;EMX_nport_instance_hook=nil ; see nport instance hook comment in emxform.ils
; The following are hooks that are called after view creation
; arguments are (open) cellview; names of lib, cell, and view; and
; a final argument indicating what was just created.  Each hook can
; be either a symbol (the name of a function) or a function.
;EMX_schematic_creation_hook=nil ; called after schematic view creation
				 ; type is either a string (= model type)
				 ; or a symbol (= 'nport for S-param view,
				 ; 'generic for other schematic)
;EMX_LVS_creation_hook=nil ; called after LVS view creation
			   ; type is either 'assura (for auLvs)
			   ; or 'calibre (for auCdl)
;EMX_symbol_creation_hook=nil ; called after symbol view creation
			      ; type is either a string (= model type)
			      ; or the symbol 'nport

;views_for_EMX_menu='(("maskLayout" (("*" layout))) ("maskLayoutXL" (("*" layout))))
; views_for_EMX_menu is a list of views where the EMX menu should be
; installed.  Each element is a pair of a view type and a list of
; pairs.  The pairs in the list are a view name and an interface type.
; The name can be "*" to match all names.  The interface type is a
; symbol which is one of: layout, schematic, or calibre.

; EMX_cci (*AC*) tells if EMX has Calibre Connect Interface support
EMX_cci=nil
; EMX_cci_expand (*AC*) tells if EMX can expand Calibre primitive cells
EMX_cci_expand=nil
; When using the Calibre Connect Interface, these set the calibre
; executable and a mapping to make the CCI layers match the EMX
; process file layers.
;EMX_calibre_command="calibre"
;EMX_cci_layer_table=(strcat EMX_interface_path "/emxskill/cci.map")

;; To make the interface set temperature coefficients for built-in
;; models:
;EMX_default_tcr1="1e-3" ; Set EMX_default_tcr1 and _tcr2 as desired
;EMX_default_tcr2="2e-3"
;EMX_schematic_creation_hook='EMX_set_model_temp_coeffs

; EMX_modelgen_temp_coeffs, if t, makes ModelGen produce linear
; temperature coefficients when using case support.
;EMX_modelgen_temp_coeffs=nil

; EMX_map_layout_symbol_hook (*TF*) is used if some black-box cells
; have symbols and layouts with mismatched terminals.  It gives
; association lists mapping layout terminals to symbol terminals (or
; to nil if a layout terminal has no matching symbol terminal and
; should be ignored).  Requires EMX_dev_term_mapping support.  See
; EMX_layout_symbol_termmap in emxform.ils
;EMX_map_layout_symbol_hook=nil

; Now actually load the interface
(load (strcat EMX_interface_path "/emxskill/emxform.ils"))
